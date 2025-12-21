import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Clés pour les configurations
  static const String _apkStableUrlKey = 'apk_stable_url';
  static const String _apkBetaUrlKey = 'apk_beta_url';
  static const String _apkStableVersionKey = 'apk_stable_version';
  static const String _apkBetaVersionKey = 'apk_beta_version';
  static const String _apkStableReleaseDateKey = 'apk_stable_release_date';
  static const String _apkBetaReleaseDateKey = 'apk_beta_release_date';
  static const String _apkStableChangelogKey = 'apk_stable_changelog';
  static const String _apkBetaChangelogKey = 'apk_beta_changelog';

  bool _initialized = false;

  /// Initialise Firebase Remote Config
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Configuration des paramètres par défaut
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1), // Cache de 1 heure
        ),
      );

      // Valeurs par défaut
      await _remoteConfig.setDefaults({
        _apkStableUrlKey: 'https://firebasestorage.googleapis.com/v0/b/agritechapp-b4910.firebasestorage.app/o/Apk%2FGesto_1.0.5.apk?alt=media&token=17486240-7cd8-4a4d-931c-f399c4a4bb9a',
        _apkBetaUrlKey: '',
        _apkStableVersionKey: '1.0.5',
        _apkBetaVersionKey: '',
        _apkStableReleaseDateKey: '2024-01-15',
        _apkBetaReleaseDateKey: '',
        _apkStableChangelogKey: '{"features":["Gestion des commandes restaurant","Gestion cuisine et bar","Inventaire du bar","Planning personnel"],"fixes":["Corrections de bugs mineurs"]}',
        _apkBetaChangelogKey: '',
      });

      // Récupère et active les valeurs distantes
      await _remoteConfig.fetchAndActivate();

      _initialized = true;
      if (kDebugMode) {
        print('✅ Remote Config initialisé avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'initialisation de Remote Config: $e');
      }
      // Continue avec les valeurs par défaut
      _initialized = true;
    }
  }

  /// Récupère l'URL de l'APK stable
  String getStableApkUrl() {
    return _remoteConfig.getString(_apkStableUrlKey);
  }

  /// Récupère l'URL de l'APK beta
  String getBetaApkUrl() {
    return _remoteConfig.getString(_apkBetaUrlKey);
  }

  /// Récupère la version de l'APK stable
  String getStableVersion() {
    return _remoteConfig.getString(_apkStableVersionKey);
  }

  /// Récupère la version de l'APK beta
  String getBetaVersion() {
    return _remoteConfig.getString(_apkBetaVersionKey);
  }

  /// Récupère la date de release de l'APK stable
  String getStableReleaseDate() {
    return _remoteConfig.getString(_apkStableReleaseDateKey);
  }

  /// Récupère la date de release de l'APK beta
  String getBetaReleaseDate() {
    return _remoteConfig.getString(_apkBetaReleaseDateKey);
  }

  /// Récupère le changelog de l'APK stable
  String getStableChangelog() {
    return _remoteConfig.getString(_apkStableChangelogKey);
  }

  /// Récupère le changelog de l'APK beta
  String getBetaChangelog() {
    return _remoteConfig.getString(_apkBetaChangelogKey);
  }

  /// Vérifie si une version beta est disponible
  bool isBetaAvailable() {
    final betaUrl = getBetaApkUrl();
    return betaUrl.isNotEmpty;
  }

  /// Force le rechargement des configurations depuis Firebase
  Future<bool> forceRefresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      if (kDebugMode) {
        print('✅ Remote Config rechargé avec succès');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors du rechargement de Remote Config: $e');
      }
      return false;
    }
  }

  /// Récupère toutes les informations d'une version
  ApkVersionInfo getVersionInfo(bool isBeta) {
    if (isBeta) {
      return ApkVersionInfo(
        url: getBetaApkUrl(),
        version: getBetaVersion(),
        releaseDate: getBetaReleaseDate(),
        changelog: getBetaChangelog(),
        isBeta: true,
      );
    } else {
      return ApkVersionInfo(
        url: getStableApkUrl(),
        version: getStableVersion(),
        releaseDate: getStableReleaseDate(),
        changelog: getStableChangelog(),
        isBeta: false,
      );
    }
  }
}

/// Classe pour encapsuler les informations d'une version APK
class ApkVersionInfo {
  final String url;
  final String version;
  final String releaseDate;
  final String changelog;
  final bool isBeta;

  ApkVersionInfo({
    required this.url,
    required this.version,
    required this.releaseDate,
    required this.changelog,
    required this.isBeta,
  });

  bool get isAvailable => url.isNotEmpty;

  String get versionLabel => isBeta ? 'Beta $version' : 'v$version';

  String get channelName => isBeta ? 'Beta' : 'Stable';

  /// Parse le changelog JSON en un objet Changelog
  Changelog? getChangelog() {
    if (changelog.isEmpty) return null;
    try {
      return Changelog.fromJson(changelog);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du parsing du changelog: $e');
      }
      return null;
    }
  }

  @override
  String toString() {
    return 'ApkVersionInfo(version: $version, isBeta: $isBeta, releaseDate: $releaseDate)';
  }
}

/// Classe pour gérer le changelog d'une version
class Changelog {
  final List<String> features;
  final List<String> fixes;
  final List<String> improvements;

  Changelog({
    this.features = const [],
    this.fixes = const [],
    this.improvements = const [],
  });

  factory Changelog.fromJson(String jsonString) {
    final Map<String, dynamic> json =
        (jsonString.contains('{'))
            ? _parseJson(jsonString)
            : {};

    return Changelog(
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      fixes: (json['fixes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      improvements: (json['improvements'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }

  static Map<String, dynamic> _parseJson(String jsonString) {
    try {
      // Simple parsing manuel du JSON
      final features = <String>[];
      final fixes = <String>[];
      final improvements = <String>[];

      if (jsonString.contains('"features"')) {
        final featuresMatch = RegExp(r'"features"\s*:\s*\[(.*?)\]', dotAll: true)
            .firstMatch(jsonString);
        if (featuresMatch != null) {
          final items = featuresMatch.group(1)!
              .split('",')
              .map((s) => s.trim().replaceAll('"', '').replaceAll('[', '').replaceAll(']', ''))
              .where((s) => s.isNotEmpty)
              .toList();
          features.addAll(items);
        }
      }

      if (jsonString.contains('"fixes"')) {
        final fixesMatch = RegExp(r'"fixes"\s*:\s*\[(.*?)\]', dotAll: true)
            .firstMatch(jsonString);
        if (fixesMatch != null) {
          final items = fixesMatch.group(1)!
              .split('",')
              .map((s) => s.trim().replaceAll('"', '').replaceAll('[', '').replaceAll(']', ''))
              .where((s) => s.isNotEmpty)
              .toList();
          fixes.addAll(items);
        }
      }

      if (jsonString.contains('"improvements"')) {
        final improvementsMatch = RegExp(r'"improvements"\s*:\s*\[(.*?)\]', dotAll: true)
            .firstMatch(jsonString);
        if (improvementsMatch != null) {
          final items = improvementsMatch.group(1)!
              .split('",')
              .map((s) => s.trim().replaceAll('"', '').replaceAll('[', '').replaceAll(']', ''))
              .where((s) => s.isNotEmpty)
              .toList();
          improvements.addAll(items);
        }
      }

      return {
        'features': features,
        'fixes': fixes,
        'improvements': improvements,
      };
    } catch (e) {
      return {};
    }
  }

  bool get isEmpty => features.isEmpty && fixes.isEmpty && improvements.isEmpty;

  bool get isNotEmpty => !isEmpty;
}
