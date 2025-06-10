import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HotelSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fonction pour vérifier si l'utilisateur est un employé et obtenir l'ID admin approprié
  Future<String> _getAppropriateUserId() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Vérifier si l'utilisateur est dans la collection staff
      final staffDoc = await _firestore.collection('staff').doc(currentUser.uid).get();

      if (staffDoc.exists) {
        // Si c'est un employé, utiliser l'ID admin de son document
        return staffDoc.data()?['idadmin'] ?? currentUser.uid;
      } else {
        // Si ce n'est pas un employé, on suppose que c'est un admin, utiliser son propre ID
        return currentUser.uid;
      }
    } catch (e) {
      print('Erreur lors de la détermination du type d\'utilisateur: $e');
      rethrow;
    }
  }

  // Fonction pour enregistrer ou mettre à jour les paramètres de l'hôtel
  Future<void> saveHotelSettings({
    required String currency,
    required String checkInTime,
    required String checkOutTime,
    required String hotelName,
    required String address,
    required String phoneNumber,
    required String email,
    List<String>? roomTypes,
    Map<String, dynamic>? otherSettings,
    required int depositPercentage,
  }) async {
    try {
      final userId = await _getAppropriateUserId();

      await _firestore.collection('hotelSettings').doc(userId).set({
        'currency': currency,
        'checkInTime': checkInTime ?? "12:00", // Valeur par défaut
        'checkOutTime': checkOutTime ?? "10:00", // Valeur par défaut
        'hotelName': hotelName,
        'address': address,
        'phoneNumber': phoneNumber,
        'email': email,
        'roomTypes': roomTypes ?? [],
        'depositPercentage': depositPercentage,
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
      final userId = await _getAppropriateUserId();

      final doc = await _firestore.collection('hotelSettings').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;

        // Assurer que les valeurs requises ont au moins des valeurs par défaut
        return {
          'currency': data['currency'] ?? 'FCFA',
          'checkInTime': data['checkInTime'] ?? '12:00',
          'checkOutTime': data['checkOutTime'] ?? '10:00',
          'hotelName': data['hotelName'] ?? 'Hôtel',
          'address': data['address'] ?? '',
          'phoneNumber': data['phoneNumber'] ?? '',
          'email': data['email'] ?? '',
          'roomTypes': data['roomTypes'] ?? [],
          'depositPercentage': data['depositPercentage'] ?? 30,
          'otherSettings': data['otherSettings'] ?? {},
        };
      } else {
        // Retourner des valeurs par défaut si le document n'existe pas
        return {
          'currency': 'FCFA',
          'checkInTime': '12:00',
          'checkOutTime': '10:00',
          'hotelName': 'Hôtel',
          'address': '',
          'phoneNumber': '',
          'email': '',
          'roomTypes': [],
          'depositPercentage': 30,
          'otherSettings': {},
        };
      }
    } catch (e) {
      print('Erreur lors de la récupération des paramètres de l\'hôtel : $e');
      // Retourner des valeurs par défaut en cas d'erreur
      return {
        'currency': 'FCFA',
        'checkInTime': '12:00',
        'checkOutTime': '10:00',
        'hotelName': 'Hôtel',
        'address': '',
        'phoneNumber': '',
        'email': '',
        'roomTypes': [],
        'depositPercentage': 30,
        'otherSettings': {},
      };
    }
  }
}