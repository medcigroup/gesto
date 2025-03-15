import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'UserModel.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Récupérer l'utilisateur actuellement connecté
  Future<UserModel?> getCurrentUser() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
    }
    return null;
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
}