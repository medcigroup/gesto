// services/setup_checker.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class SetupChecker {
  static const String _hotelConfiguredKey = 'hotel_configured';
  static const String _roomsCreatedKey = 'rooms_created';
  static const String _staffAddedKey = 'staff_added';
  static const String _initialSetupKey = 'initial_setup_completed';

  final SharedPreferences _prefs;
  final FirebaseFirestore? _firestore;

  SetupChecker(this._prefs, {FirebaseFirestore? firestore}) : _firestore = firestore;

  // Vérifier si la configuration initiale est complète
  Future<bool> isInitialSetupComplete() async {
    try {
      return _prefs.getBool(_initialSetupKey) ?? false;
    } catch (e) {
      print('Erreur vérification setup: $e');
      return false;
    }
  }

  // Marquer la configuration initiale comme complète
  Future<void> markInitialSetupComplete() async {
    try {
      await _prefs.setBool(_initialSetupKey, true);

      if (_firestore != null) {
        // Enregistrer dans le backend si nécessaire
        // Cette partie dépend de votre structure de données
      }
    } catch (e) {
      print('Erreur marquage setup: $e');
    }
  }

  // Vérifier chaque étape individuellement
  Future<bool> isHotelConfigured() async {
    try {
      if (_firestore != null) {
        // Vérifier dans Firestore si les données de l'hôtel existent
        final hotelDoc = await _firestore!
            .collection('hotelSettings')
            .doc('main')
            .get();

        if (hotelDoc.exists && hotelDoc.data() != null) {
          final data = hotelDoc.data()!;
          final hasBasicInfo = data['hotelName'] != null &&
              data['hotelName'].toString().isNotEmpty;

          if (hasBasicInfo) {
            await _prefs.setBool(_hotelConfiguredKey, true);
            return true;
          }
        }
      }

      return _prefs.getBool(_hotelConfiguredKey) ?? false;
    } catch (e) {
      print('Erreur vérification hotel: $e');
      return false;
    }
  }

  Future<bool> areRoomsCreated() async {
    try {
      if (_firestore != null) {
        // Vérifier dans Firestore s'il y a des chambres
        final roomsQuery = await _firestore!
            .collection('rooms')
            .limit(1)
            .get();

        if (roomsQuery.docs.isNotEmpty) {
          await _prefs.setBool(_roomsCreatedKey, true);
          return true;
        }
      }

      return _prefs.getBool(_roomsCreatedKey) ?? false;
    } catch (e) {
      print('Erreur vérification chambres: $e');
      return false;
    }
  }

  Future<bool> isStaffAdded() async {
    try {
      if (_firestore != null) {
        // Vérifier dans Firestore s'il y a du personnel (exclure l'admin)
        final staffQuery = await _firestore!
            .collection('users')
            .where('role', whereIn: ['receptionist', 'employee', 'kitchen', 'manager'])
            .limit(1)
            .get();

        if (staffQuery.docs.isNotEmpty) {
          await _prefs.setBool(_staffAddedKey, true);
          return true;
        }
      }

      return _prefs.getBool(_staffAddedKey) ?? false;
    } catch (e) {
      print('Erreur vérification personnel: $e');
      return false;
    }
  }

  // Obtenir la progression de la configuration
  Future<List<String>> getSetupProgress() async {
    final List<String> completed = [];

    if (await isHotelConfigured()) completed.add('hotel');
    if (await areRoomsCreated()) completed.add('rooms');
    if (await isStaffAdded()) completed.add('staff');

    return completed;
  }

  // Réinitialiser la configuration (pour les tests)
  Future<void> resetSetup() async {
    await _prefs.remove(_initialSetupKey);
    await _prefs.remove(_hotelConfiguredKey);
    await _prefs.remove(_roomsCreatedKey);
    await _prefs.remove(_staffAddedKey);
  }
}