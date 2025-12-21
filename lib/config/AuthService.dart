import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'UserModel.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Récupérer l'utilisateur actuellement connecté
  Future<UserModel?> getCurrentUser() async {
    try {
      final User? user = _auth.currentUser;
      print('🔍 AuthService.getCurrentUser: Firebase user: ${user?.email ?? "null"}');

      if (user == null) {
        print('⚠️ AuthService.getCurrentUser: Pas d\'utilisateur Firebase connecté');
        return null;
      }

      print('📡 AuthService.getCurrentUser: Récupération du document Firestore pour: ${user.uid}');
      final DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        print('❌ AuthService.getCurrentUser: Document utilisateur introuvable dans Firestore');
        return null;
      }

      print('✅ AuthService.getCurrentUser: Document trouvé, conversion en UserModel...');
      final userData = doc.data() as Map<String, dynamic>;
      print('📊 AuthService.getCurrentUser: Données: ${userData.keys.join(", ")}');

      return UserModel.fromJson(userData);
    } catch (e, stackTrace) {
      print('❌ AuthService.getCurrentUser: Erreur: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  // Récupérer le rôle de l'utilisateur actuellement connecté
  Future<String?> getCurrentUserRole() async {
    final UserModel? user = await getCurrentUser();
    if (user != null) {
      return user.userRole;
    }
    return null;
  }

  // Déconnexion de l'utilisateur
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Vérifier si les données ont été modifiées côté serveur
  Future<bool> hasUserDataChanged(String userId, DateTime lastUpdated) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();

    if (snapshot.exists) {
      final serverUpdated = (snapshot.data()?['updatedAt'] as Timestamp).toDate();
      return serverUpdated.isAfter(lastUpdated);
    }
    return true; // Si l'utilisateur n'existe plus, forcer une mise à jour
  }

  // Récupérer le slug de l'hôtel de l'utilisateur connecté
  Future<String?> getUserHotelSlug() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      // Récupérer les données de l'utilisateur
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data();
      final establishmentName = userData?['establishmentName'] as String?;
      
      if (establishmentName == null) return null;

      // Chercher l'hôtel correspondant dans la collection hotels
      final hotelsQuery = await _firestore
          .collection('hotels')
          .where('hotelName', isEqualTo: establishmentName)
          .limit(1)
          .get();

      if (hotelsQuery.docs.isEmpty) return null;

      return hotelsQuery.docs.first.data()['slug'] as String?;
    } catch (e) {
      print('Erreur lors de la récupération du slug: $e');
      return null;
    }
  }

  // Récupérer le nom de l'établissement
  Future<String?> getEstablishmentName() async {
    final UserModel? user = await getCurrentUser();
    return user?.establishmentName;
  }
}