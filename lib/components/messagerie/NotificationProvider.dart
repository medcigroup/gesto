import 'package:flutter/material.dart';
import 'NotificationService.dart';
// Import avec alias pour éviter le conflit
import 'NotificationService.dart' as NS;

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  // Utilisation de l'alias pour éviter le conflit avec la classe Notification de Flutter
  List<NS.Notification> _notifications = [];
  int _nonLuesCount = 0;

  List<NS.Notification> get notifications => _notifications;
  int get nonLuesCount => _nonLuesCount;

  // Initialiser les streams de notifications
  void initialiser() {
    // Écouter le stream des notifications
    _notificationService.getNotificationsStream().listen((notifications) {
      _notifications = notifications;
      notifyListeners();
    });

    // Écouter le stream du compteur de notifications non lues
    _notificationService.getNonLuesCount().listen((count) {
      _nonLuesCount = count;
      notifyListeners();
    });
  }

  // Marquer une notification comme lue
  Future<void> marquerCommeLue(String notificationId) async {
    await _notificationService.marquerCommeLue(notificationId);
  }

  // Marquer toutes les notifications comme lues
  Future<void> marquerToutesCommeLues() async {
    for (var notification in _notifications.where((n) => !n.estLu)) {
      await _notificationService.marquerCommeLue(notification.id);
    }
  }

  // Envoyer une notification
  Future<bool> envoyerNotification({
    required String titre,
    required String contenu,
    required String destinataireId,
  }) async {
    return await _notificationService.envoyerNotification(
      titre: titre,
      contenu: contenu,
      destinataireId: destinataireId,
    );
  }

  // Supprimer une notification
  Future<bool> supprimerNotification(String notificationId) async {
    // Retirer la notification de la liste locale pour une mise à jour immédiate de l'interface
    _notifications.removeWhere((notification) => notification.id == notificationId);
    notifyListeners();

    // Supprimer la notification dans Firestore
    return await _notificationService.supprimerNotification(notificationId);
  }
}