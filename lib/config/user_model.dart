import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserModelPersonnel {
  final String id;
  final String idadmin;
  final String nom;
  final String prenom;
  final String email;
  final String poste;
  final String departement;
  final String entrepriseCode;
  final DateTime dateEmbauche;
  final String statut;
  final String? photoUrl;
  final List<String>? competences;
  final List<String>? permissions;

  UserModelPersonnel( {
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.poste,
    required this.departement,
    required this.dateEmbauche,
    required this.statut,
    this.photoUrl,
    this.competences,
    this.permissions,
    required this.entrepriseCode,
    required this.idadmin,
  });

  factory UserModelPersonnel.fromJson(Map<String, dynamic> json) {
    return UserModelPersonnel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      entrepriseCode: json['entrepriseCode'] ?? '',
      email: json['email'] ?? '',
      poste: json['poste'] ?? '',
      departement: json['departement'] ?? '',
      dateEmbauche: json['dateEmbauche'] is Timestamp
          ? (json['dateEmbauche'] as Timestamp).toDate()
          : DateTime.now(),
      statut: json['statut'] ?? 'actif',
      photoUrl: json['photoUrl'],
      competences: json['competences'] != null
          ? List<String>.from(json['competences'])
          : [],
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : [],
      idadmin: json['idadmin'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'poste': poste,
      'departement': departement,
      'dateEmbauche': Timestamp.fromDate(dateEmbauche),
      'statut': statut,
      'photoUrl': photoUrl,
      'competences': competences ?? [],
      'permissions': permissions ?? [],
      'entrepriseCode': entrepriseCode,
      'idadmin': idadmin,
    };
  }

  // Méthode pour créer une copie modifiée de l'objet
  UserModelPersonnel copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? poste,
    String? departement,
    DateTime? dateEmbauche,
    String? statut,
    String? photoUrl,
    List<String>? competences,
    List<String>? permissions,
    String? entrepriseCode,
    String? idadmin,
  }) {
    return UserModelPersonnel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      poste: poste ?? this.poste,
      departement: departement ?? this.departement,
      dateEmbauche: dateEmbauche ?? this.dateEmbauche,
      statut: statut ?? this.statut,
      photoUrl: photoUrl ?? this.photoUrl,
      competences: competences ?? this.competences,
      permissions: permissions ?? this.permissions,
      entrepriseCode: entrepriseCode ?? this.entrepriseCode,
      idadmin: idadmin ?? this.idadmin,
    );
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _staffCollection = 'staff'; // Collection pour le personnel

  // Obtenir l'utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;

  // Stream pour écouter les changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Connexion avec email et mot de passe
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      throw e;
    }
  }

  // Inscription d'un nouvel utilisateur
  Future<UserCredential> createUserWithEmailAndPassword(
      String email,
      String password,
      UserModelPersonnel userData
      ) async {
    try {
      // Créer l'utilisateur dans Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ajouter les données utilisateur à Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set(
            userData.copyWith(id: userCredential.user!.uid).toJson()
        );
      }

      return userCredential;
    } catch (e) {
      throw e;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // Récupérer les informations d'un utilisateur
  Future<UserModelPersonnel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModelPersonnel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw e;
    }
  }

  // Récupérer les informations de l'utilisateur connecté
  Future<UserModelPersonnel?> getCurrentUserData() async {
    if (currentUser == null) return null;
    return await getUserData(currentUser!.uid);
  }

  // Mettre à jour les données d'un utilisateur
  Future<void> updateUserData(UserModelPersonnel userData) async {
    try {
      await _firestore.collection('users').doc(userData.id).update(userData.toJson());
    } catch (e) {
      throw e;
    }
  }

  // Récupérer tous les utilisateurs
  Future<List<UserModelPersonnel>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs
          .map((doc) => UserModelPersonnel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw e;
    }
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw e;
    }
  }

  // Vérifier si un utilisateur a certaines permissions
  bool hasPermission(UserModelPersonnel user, String permission) {
    return user.permissions?.contains(permission) ?? false;
  }

  // ========== NOUVELLES MÉTHODES ==========

  // Récupérer tout le personnel
  // Récupérer tout le personnel de l'entreprise
  Future<List<UserModelPersonnel>> getAllStaff(String entrepriseCode) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_staffCollection)
          .where('entrepriseCode', isEqualTo: entrepriseCode)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModelPersonnel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw e;
    }
  }

// Récupérer le personnel par département et entreprise
  Future<List<UserModelPersonnel>> getStaffByDepartment(
      String departement,
      String entrepriseCode
      ) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_staffCollection)
          .where('departement', isEqualTo: departement)
          .where('entrepriseCode', isEqualTo: entrepriseCode)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModelPersonnel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw e;
    }
  }

  // Créer un compte pour un membre du personnel
  Future<UserCredential> createStaffAccount(
      String email, String password, UserModelPersonnel staffData) async {
    try {
      // Créer l'utilisateur dans Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ajouter les données du personnel à Firestore
      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;
        await _firestore.collection(_staffCollection).doc(uid).set(
            staffData.copyWith(id: uid).toJson()
        );
      }

      return userCredential;
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, dynamic>> createStaffAccountServeur(
      String email, String password, UserModelPersonnel staffData) async {
    try {
      // Obtenir la référence à la fonction Cloud
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('createStaffUser');

      // Convertir le modèle en Map pour l'envoyer à la fonction
      final staffDataMap = staffData.toJson();

      // Appeler la fonction avec les données
      final result = await callable.call({
        'email': email,
        'password': password,
        'staffData': staffDataMap
      });

      return result.data;
    } catch (e) {
      // Gérer les erreurs spécifiques
      if (e is FirebaseFunctionsException) {
        String errorCode = e.code;
        String errorMessage = e.message ?? 'Erreur inconnue';
        throw Exception('$errorCode: $errorMessage');
      }
      throw Exception('Erreur lors de la création du compte staff: ${e.toString()}');
    }
  }

  // Mettre à jour les informations d'un membre du personnel
  Future<void> updateStaffInfo(UserModelPersonnel staffData) async {
    try {
      await _firestore
          .collection(_staffCollection)
          .doc(staffData.id)
          .update(staffData.toJson());
    } catch (e) {
      throw e;
    }
  }

  // Stream pour écouter les changements dans la collection du personnel
  Stream<List<UserModelPersonnel>> streamAllStaff() {
    return _firestore
        .collection(_staffCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModelPersonnel.fromJson(doc.data()))
        .toList());
  }

  // Supprimer un membre du personnel
  Future<void> removeStaffMember(String staffId) async {
    try {
      // Récupérer l'utilisateur pour obtenir son email
      DocumentSnapshot doc = await _firestore.collection(_staffCollection).doc(staffId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String email = data['email'] ?? '';

        // Rechercher l'utilisateur dans Firebase Auth par email
        List<UserInfo> users = await _auth.fetchSignInMethodsForEmail(email).then(
                (_) => _auth.currentUser?.providerData ?? []
        );

        // Supprimer le document de Firestore
        await _firestore.collection(_staffCollection).doc(staffId).delete();

        // Si l'utilisateur existe dans Auth, essayer de le supprimer
        if (users.isNotEmpty) {
          await _auth.currentUser?.delete();
        }
      }
    } catch (e) {
      throw e;
    }
  }

}