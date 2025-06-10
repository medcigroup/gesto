import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Définition des types de licence
enum LicenseType {
  basic,
  starter,
  pro,
  entreprise
}

// Extension pour convertir String en LicenseType
extension LicenseTypeExtension on String {
  LicenseType toLicenseType() {
    switch (this.toLowerCase()) {
      case 'basic':
        return LicenseType.basic;
      case 'starter':
        return LicenseType.starter;
      case 'pro':
        return LicenseType.pro;
      case 'entreprise':
        return LicenseType.entreprise;
      default:
        return LicenseType.basic; // Type par défaut
    }
  }
}

// Fonctionnalités disponibles par type de licence
class LicenseFeatures {
  // Pages accessibles par type de licence
  static const Map<LicenseType, List<String>> pageAccess = {
    LicenseType.basic: [
      'Tableau de bord',
      'Réservations',
      'Chambres',
      'Enregistrement',
      'Passages',
      'Départ',
      'Personnel',
      'Licences',
      'Administration',
      'Paramètres',
    ],
    LicenseType.starter: [
      'Tableau de bord',
      'Réservations',
      'Chambres',
      'Taches',
      'Enregistrement',
      'Passages',
      'Départ',
      'Personnel',
      'Licences',
      'Administration',
      'Paramètres',
    ],
    LicenseType.pro: [
      'Tableau de bord',
      'Réservations',
      'Chambres',
      'Taches',
      'Paiements',
      'Enregistrement',
      'Passages',
      'Départ',
      'Restaurant',
      'Personnel',
      'Finances',
      'Licences',
      'Administration',
      'Paramètres',
    ],
    LicenseType.entreprise: [
      'Tableau de bord',
      'Réservations',
      'Chambres',
      'Taches',
      'Paiements',
      'Enregistrement',
      'Passages',
      'Départ',
      'Restaurant',
      'Personnel',
      'Finances',
      'Licences',
      'Administration',
      'Paramètres',
    ],
  };

  // Fonctionnalités premium (nécessitant une mise à niveau)
  static const Map<String, LicenseType> premiumFeatures = {
    'Restaurant': LicenseType.pro,
    'Finances': LicenseType.pro,
    'Taches': LicenseType.starter,
  };

  // Vérifier si une page est accessible pour un type de licence donné
  static bool isPageAccessible(String pageTitle, LicenseType licenseType) {
    return pageAccess[licenseType]?.contains(pageTitle) ?? false;
  }

  // Vérifier si une page est une fonctionnalité premium
  static bool isPremiumFeature(String pageTitle, LicenseType currentLicense) {
    if (!premiumFeatures.containsKey(pageTitle)) {
      return false;
    }

    LicenseType requiredLicense = premiumFeatures[pageTitle]!;
    // C'est une fonctionnalité premium si le niveau de licence requis est supérieur au niveau actuel
    return requiredLicense.index > currentLicense.index;
  }

  // Obtenir le type de licence requis pour une fonctionnalité
  static LicenseType? getRequiredLicenseForFeature(String pageTitle) {
    return premiumFeatures[pageTitle];
  }
}

// Classe pour la gestion des licences
class LicenseManager extends ChangeNotifier {
  LicenseType _currentLicenseType = LicenseType.basic;
  DateTime? _expiryDate;
  bool _isExpired = false;
  bool _isLoading = true;

  LicenseType get currentLicenseType => _currentLicenseType;
  DateTime? get expiryDate => _expiryDate;
  bool get isExpired => _isExpired;
  bool get isLoading => _isLoading;

  // Constructeur
  LicenseManager() {
    // Charger les informations de licence depuis Firestore au démarrage
    loadLicenseInfo();
  }

  // Récupérer les informations de licence depuis Firestore
  Future<void> loadLicenseInfo() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Récupérer l'utilisateur actuel
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Récupérer les données utilisateur depuis Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();

        // Récupérer le type de licence (String)
        String licenseTypeStr = userData?['licenceType'] ?? 'basic';

        // Récupérer la date d'expiration (Timestamp)
        Timestamp? expiryTimestamp = userData?['licenceExpiryDate'];
        DateTime? expiryDate = expiryTimestamp?.toDate();

        // Initialiser avec les données récupérées
        initialize(
          licenseType: licenseTypeStr.toLicenseType(),
          expiryDate: expiryDate,
        );
      }
    } catch (e) {
      print('Erreur lors de la récupération des informations de licence: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialiser avec les données de l'utilisateur
  void initialize({required LicenseType licenseType, DateTime? expiryDate}) {
    _currentLicenseType = licenseType;
    _expiryDate = expiryDate;
    checkExpiration();
    _isLoading = false;
    notifyListeners();
  }

  // Mettre à jour le type de licence
  void updateLicenseType(LicenseType newType, DateTime? newExpiryDate) {
    _currentLicenseType = newType;
    _expiryDate = newExpiryDate;
    checkExpiration();
    notifyListeners();
  }

  // Vérifier si la licence a expiré
  void checkExpiration() {
    if (_expiryDate != null) {
      _isExpired = DateTime.now().isAfter(_expiryDate!);
    } else {
      _isExpired = false;
    }
  }

  // Vérifier si une page est accessible avec la licence actuelle
  bool canAccessPage(String pageTitle) {
    // Si la licence a expiré, seuls quelques pages sont accessibles
    if (_isExpired) {
      return ['Tableau de bord', 'Licences', 'Paramètres'].contains(pageTitle);
    }

    return LicenseFeatures.isPageAccessible(pageTitle, _currentLicenseType);
  }

  // Vérifier si une fonctionnalité est premium pour l'utilisateur actuel
  bool isFeaturePremium(String featureName) {
    return LicenseFeatures.isPremiumFeature(featureName, _currentLicenseType);
  }

  // Récupérer le niveau de licence requis pour une fonctionnalité
  String getRequiredLicenseNameForFeature(String featureName) {
    LicenseType? requiredType = LicenseFeatures.getRequiredLicenseForFeature(featureName);
    if (requiredType == null) return "";

    switch (requiredType) {
      case LicenseType.basic:
        return "basic";
      case LicenseType.starter:
        return "starter";
      case LicenseType.pro:
        return "pro";
      case LicenseType.entreprise:
        return "entreprise";
    }
  }
}