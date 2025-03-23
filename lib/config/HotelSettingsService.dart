import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HotelSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fonction pour enregistrer ou mettre à jour les paramètres de l'hôtel
  Future<void> saveHotelSettings({
    required String currency,
    required String checkInTime,
    required String checkOutTime,
    // Nouveaux paramètres ajoutés
    required String hotelName,
    required String address,
    required String phoneNumber,
    required String email,
    List<String>? roomTypes,
    Map<String, dynamic>? otherSettings,
    // Paramètre pour le pourcentage d'acompte
    required int depositPercentage,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _firestore.collection('hotelSettings').doc(userId).set({
        'currency': currency,
        'checkInTime': checkInTime,
        'checkOutTime': checkOutTime,
        'hotelName': hotelName,
        'address': address,
        'phoneNumber': phoneNumber,
        'email': email,
        'roomTypes': roomTypes ?? [],
        'depositPercentage': depositPercentage, // Nouveau paramètre ajouté
        'otherSettings': otherSettings ?? {},
      });
    } catch (e) {
      print('Erreur lors de l\'enregistrement des paramètres de l\'hôtel : $e');
      rethrow;
    }
  }

  // Fonction pour récupérer les paramètres de l'hôtel
  Future<Map<String, dynamic>> getHotelSettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final doc = await _firestore.collection('hotelSettings').doc(userId).get();
      if (doc.exists) {
        return doc.data()!;
      } else {
        return {};
      }
    } catch (e) {
      print('Erreur lors de la récupération des paramètres de l\'hôtel : $e');
      rethrow;
    }
  }
}

