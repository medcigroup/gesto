import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

import 'UserModel.dart';

class LocalStorage {
  /// Sauvegarde des données dans le localStorage.
  /// [key] : La clé sous laquelle les données seront stockées.
  /// [data] : Les données à sauvegarder (doivent être sérialisables en JSON).
  static void save(String key, dynamic data) {
    if (key.isEmpty) {
      throw ArgumentError('La clé ne peut pas être vide.');
    }

    if (kIsWeb) {
      try {
        final jsonData = jsonEncode(data.toJson()); // Utilisez toJson() ici
        html.window.localStorage[key] = jsonData;
      } catch (e) {
        debugPrint('Erreur lors de la sauvegarde des données : $e');
        throw Exception('Impossible de sauvegarder les données. Vérifiez que les données sont sérialisables en JSON.');
      }
    } else {
      debugPrint('LocalStorage.save() est uniquement supporté sur le web.');
    }
  }

  /// Charge des données depuis le localStorage.
  /// [key] : La clé sous laquelle les données sont stockées.
  /// Retourne les données désérialisées ou `null` si la clé n'existe pas.
  static UserModel? load(String key) {
    if (key.isEmpty) {
      throw ArgumentError('La clé ne peut pas être vide.');
    }

    if (kIsWeb) {
      try {
        final jsonData = html.window.localStorage[key];
        if (jsonData != null) {
          final decodedData = jsonDecode(jsonData);
          return UserModel.fromJson(decodedData); // Utilisez fromJson() ici
        }
      } catch (e) {
        debugPrint('Erreur lors du chargement des données : $e');
        throw Exception('Impossible de charger les données. Vérifiez que les données sont valides.');
      }
    } else {
      debugPrint('LocalStorage.load() est uniquement supporté sur le web.');
    }
    return null;
  }

  /// Supprime des données du localStorage.
  /// [key] : La clé des données à supprimer.
  static void remove(String key) {
    if (key.isEmpty) {
      throw ArgumentError('La clé ne peut pas être vide.');
    }

    if (kIsWeb) {
      html.window.localStorage.remove(key);
    } else {
      debugPrint('LocalStorage.remove() est uniquement supporté sur le web.');
    }
  }

  /// Vérifie si une clé existe dans le localStorage.
  /// [key] : La clé à vérifier.
  /// Retourne `true` si la clé existe, sinon `false`.
  static bool containsKey(String key) {
    if (key.isEmpty) {
      throw ArgumentError('La clé ne peut pas être vide.');
    }

    if (kIsWeb) {
      return html.window.localStorage.containsKey(key);
    } else {
      debugPrint('LocalStorage.containsKey() est uniquement supporté sur le web.');
      return false;
    }
  }

  /// Efface toutes les données du localStorage.
  static void clear() {
    if (kIsWeb) {
      html.window.localStorage.clear();
    } else {
      debugPrint('LocalStorage.clear() est uniquement supporté sur le web.');
    }
  }
}