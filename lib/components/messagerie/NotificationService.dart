import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class Notification {
  final String id;
  final String titre;
  final String contenu;
  final String expediteurId;
  final String destinataireId;
  final DateTime dateEnvoi;
  final bool estLu;

  Notification({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.expediteurId,
    required this.destinataireId,
    required this.dateEnvoi,
    required this.estLu,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'contenu': contenu,
      'expediteurId': expediteurId,
      'destinataireId': destinataireId,
      'dateEnvoi': dateEnvoi,
      'estLu': estLu,
    };
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      titre: json['titre'],
      contenu: json['contenu'],
      expediteurId: json['expediteurId'],
      destinataireId: json['destinataireId'],
      dateEnvoi: (json['dateEnvoi'] as Timestamp).toDate(),
      estLu: json['estLu'] ?? false,
    );
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Stream des notifications pour l'utilisateur actuel
  // Stream des notifications pour l'utilisateur actuel
  Stream<List<Notification>> getNotificationsStream() {
    if (_currentUser == null) return Stream.value([]);

    print('Recherche des notifications pour: ${_currentUser!.email}');

    return _firestore
        .collection('notifications')
        .where('destinataireId', isEqualTo: _currentUser!.email) // Utiliser l'email au lieu de l'UID
        .orderBy('dateEnvoi', descending: true)
        .snapshots()
        .map((snapshot) {
      print('Notifications trouvées: ${snapshot.docs.length}');
      return snapshot.docs
          .map((doc) => Notification.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

// Récupérer le nombre de notifications non lues
  Stream<int> getNonLuesCount() {
    if (_currentUser == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('destinataireId', isEqualTo: _currentUser!.email) // Utiliser l'email au lieu de l'UID
        .where('estLu', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  // Marquer une notification comme lue
  Future<void> marquerCommeLue(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'estLu': true});
    } catch (e) {
      print('Erreur lors du marquage de la notification: $e');
    }
  }

  // Envoyer une notification
  Future<bool> envoyerNotification({
    required String titre,
    required String contenu,
    required String destinataireId,
  }) async {
    try {
      if (_currentUser == null) return false;

      final notificationId = _firestore.collection('notifications').doc().id;
      final notification = Notification(
        id: notificationId,
        titre: titre,
        contenu: contenu,
        expediteurId: _currentUser!.uid,
        destinataireId: destinataireId,
        dateEnvoi: DateTime.now(),
        estLu: false,
      );

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set(notification.toJson());

      return true;
    } catch (e) {
      print('Erreur lors de l\'envoi de la notification: $e');
      return false;
    }
  }
  Future<bool> supprimerNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de la notification: $e');
      return false;
    }
  }
}