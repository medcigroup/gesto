import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/support_ticket.dart';
import '../models/roadmap_item.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============== TICKETS DE SUPPORT ==============

  /// Créer un nouveau ticket de support
  Future<String> createTicket({
    required String userId,
    required String userEmail,
    required String userName,
    required String subject,
    required String description,
    required TicketCategory category,
    TicketPriority priority = TicketPriority.medium,
    List<String> attachmentUrls = const [],
  }) async {
    try {
      final ticket = SupportTicket(
        id: '',
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        subject: subject,
        description: description,
        category: category,
        priority: priority,
        status: TicketStatus.open,
        createdAt: DateTime.now(),
        attachmentUrls: attachmentUrls,
        messages: [],
      );

      final docRef = await _firestore
          .collection('support_tickets')
          .add(ticket.toFirestore());

      print('[SUPPORT] ✅ Ticket créé avec ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('[SUPPORT] ❌ Erreur création ticket: $e');
      rethrow;
    }
  }

  /// Récupérer tous les tickets d'un utilisateur
  Stream<List<SupportTicket>> getUserTickets(String userId) {
    return _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => SupportTicket.fromFirestore(doc))
            .toList());
  }

  /// Récupérer tous les tickets (pour admin)
  Stream<List<SupportTicket>> getAllTickets() {
    return _firestore
        .collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => SupportTicket.fromFirestore(doc))
            .toList());
  }

  /// Récupérer les tickets par statut
  Stream<List<SupportTicket>> getTicketsByStatus(TicketStatus status) {
    return _firestore
        .collection('support_tickets')
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => SupportTicket.fromFirestore(doc))
            .toList());
  }

  /// Récupérer un ticket spécifique
  Future<SupportTicket?> getTicket(String ticketId) async {
    try {
      final doc = await _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .get();

      if (doc.exists) {
        return SupportTicket.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('[SUPPORT] ❌ Erreur récupération ticket: $e');
      return null;
    }
  }

  /// Écouter les changements d'un ticket spécifique en temps réel
  Stream<SupportTicket?> getTicketStream(String ticketId) {
    return _firestore
        .collection('support_tickets')
        .doc(ticketId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return SupportTicket.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Ajouter un message à un ticket
  Future<void> addMessageToTicket({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String senderEmail,
    required bool isAdmin,
    required String message,
    List<String> attachmentUrls = const [],
  }) async {
    try {
      final ticketMessage = TicketMessage(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        senderId: senderId,
        senderName: senderName,
        senderEmail: senderEmail,
        isAdmin: isAdmin,
        message: message,
        timestamp: DateTime.now(),
        attachmentUrls: attachmentUrls,
      );

      await _firestore.collection('support_tickets').doc(ticketId).update({
        'messages': FieldValue.arrayUnion([ticketMessage.toMap()]),
        'updatedAt': Timestamp.now(),
      });

      print('[SUPPORT] ✅ Message ajouté au ticket $ticketId');
    } catch (e) {
      print('[SUPPORT] ❌ Erreur ajout message: $e');
      rethrow;
    }
  }

  /// Mettre à jour le statut d'un ticket
  Future<void> updateTicketStatus(String ticketId,
      TicketStatus newStatus) async {
    try {
      final updates = {
        'status': newStatus.name,
        'updatedAt': Timestamp.now(),
      };

      if (newStatus == TicketStatus.closed ||
          newStatus == TicketStatus.resolved) {
        updates['closedAt'] = Timestamp.now();
      }

      await _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .update(updates);

      print('[SUPPORT] ✅ Statut du ticket $ticketId mis à jour: ${newStatus
          .name}');
    } catch (e) {
      print('[SUPPORT] ❌ Erreur mise à jour statut: $e');
      rethrow;
    }
  }

  /// Mettre à jour la priorité d'un ticket
  Future<void> updateTicketPriority(String ticketId,
      TicketPriority newPriority) async {
    try {
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'priority': newPriority.name,
        'updatedAt': Timestamp.now(),
      });

      print('[SUPPORT] ✅ Priorité du ticket $ticketId mise à jour: ${newPriority
          .name}');
    } catch (e) {
      print('[SUPPORT] ❌ Erreur mise à jour priorité: $e');
      rethrow;
    }
  }

  /// Assigner un ticket à un admin
  Future<void> assignTicket(String ticketId, String adminId) async {
    try {
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'assignedTo': adminId,
        'status': TicketStatus.inProgress.name,
        'updatedAt': Timestamp.now(),
      });

      print('[SUPPORT] ✅ Ticket $ticketId assigné à $adminId');
    } catch (e) {
      print('[SUPPORT] ❌ Erreur assignation ticket: $e');
      rethrow;
    }
  }

  /// Supprimer un ticket
  Future<void> deleteTicket(String ticketId) async {
    try {
      await _firestore.collection('support_tickets').doc(ticketId).delete();
      print('[SUPPORT] ✅ Ticket $ticketId supprimé');
    } catch (e) {
      print('[SUPPORT] ❌ Erreur suppression ticket: $e');
      rethrow;
    }
  }

  // ============== ROADMAP ==============

  /// Créer un nouvel item de roadmap
  Future<String> createRoadmapItem({
    required String title,
    required String description,
    required RoadmapStatus status,
    required RoadmapPriority priority,
    DateTime? estimatedDate,
    String category = 'Général',
    List<String> tags = const [],
  }) async {
    try {
      final item = RoadmapItem(
        id: '',
        title: title,
        description: description,
        status: status,
        priority: priority,
        createdAt: DateTime.now(),
        estimatedDate: estimatedDate,
        category: category,
        tags: tags,
      );

      final docRef = await _firestore
          .collection('roadmap')
          .add(item.toFirestore());

      print('[ROADMAP] ✅ Item créé avec ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('[ROADMAP] ❌ Erreur création item: $e');
      rethrow;
    }
  }

  /// Récupérer tous les items de la roadmap
  Stream<List<RoadmapItem>> getRoadmapItems() {
    return _firestore
        .collection('roadmap')
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => RoadmapItem.fromFirestore(doc))
            .toList());
  }

  /// Récupérer les items de roadmap par statut
  Stream<List<RoadmapItem>> getRoadmapItemsByStatus(RoadmapStatus status) {
    return _firestore
        .collection('roadmap')
        .where('status', isEqualTo: status.name)
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => RoadmapItem.fromFirestore(doc))
            .toList());
  }

  /// Voter pour un item de roadmap
  Future<void> voteForRoadmapItem(String itemId, String userId) async {
    try {
      final doc = await _firestore.collection('roadmap').doc(itemId).get();
      if (doc.exists) {
        final item = RoadmapItem.fromFirestore(doc);

        if (item.voters.contains(userId)) {
          // Retirer le vote
          await _firestore.collection('roadmap').doc(itemId).update({
            'voters': FieldValue.arrayRemove([userId]),
            'votesCount': FieldValue.increment(-1),
          });
          print('[ROADMAP] ✅ Vote retiré de l\'item $itemId');
        } else {
          // Ajouter le vote
          await _firestore.collection('roadmap').doc(itemId).update({
            'voters': FieldValue.arrayUnion([userId]),
            'votesCount': FieldValue.increment(1),
          });
          print('[ROADMAP] ✅ Vote ajouté à l\'item $itemId');
        }
      }
    } catch (e) {
      print('[ROADMAP] ❌ Erreur vote: $e');
      rethrow;
    }
  }

  /// Mettre à jour un item de roadmap
  Future<void> updateRoadmapItem(String itemId,
      Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('roadmap').doc(itemId).update(updates);
      print('[ROADMAP] ✅ Item $itemId mis à jour');
    } catch (e) {
      print('[ROADMAP] ❌ Erreur mise à jour item: $e');
      rethrow;
    }
  }

  /// Supprimer un item de roadmap
  Future<void> deleteRoadmapItem(String itemId) async {
    try {
      await _firestore.collection('roadmap').doc(itemId).delete();
      print('[ROADMAP] ✅ Item $itemId supprimé');
    } catch (e) {
      print('[ROADMAP] ❌ Erreur suppression item: $e');
      rethrow;
    }
  }

  // ============== STATISTIQUES ==============

  /// Obtenir les statistiques des tickets
  Future<Map<String, int>> getTicketStatistics() async {
    try {
      final snapshot = await _firestore.collection('support_tickets').get();

      final stats = {
        'total': snapshot.docs.length,
        'open': 0,
        'inProgress': 0,
        'waiting': 0,
        'resolved': 0,
        'closed': 0,
      };

      for (var doc in snapshot.docs) {
        final ticket = SupportTicket.fromFirestore(doc);
        stats[ticket.status.name] = (stats[ticket.status.name] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('[SUPPORT] ❌ Erreur récupération statistiques: $e');
      return {};
    }
  }

  // ============== NOTIFICATIONS ==============

  /// Compter le nombre de tickets non lus (statut 'open') pour un utilisateur
  Stream<int> getUnreadTicketsCount(String userId) {
    return _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: TicketStatus.open.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Compter le nombre de messages non lus (messages admin après dernière visite)
  /// Pour simplifier, on compte les tickets qui ont des messages admin après le dernier message utilisateur
  Stream<int> getUnreadMessagesCount(String userId) {
    return _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      int unreadCount = 0;

      for (var doc in snapshot.docs) {
        final ticket = SupportTicket.fromFirestore(doc);

        // Trouver le dernier message de l'utilisateur et le dernier message admin
        DateTime? lastUserMessageTime;
        DateTime? lastAdminMessageTime;

        for (var message in ticket.messages) {
          if (message.isAdmin) {
            if (lastAdminMessageTime == null ||
                message.timestamp.isAfter(lastAdminMessageTime)) {
              lastAdminMessageTime = message.timestamp;
            }
          } else if (message.senderId == userId) {
            if (lastUserMessageTime == null ||
                message.timestamp.isAfter(lastUserMessageTime)) {
              lastUserMessageTime = message.timestamp;
            }
          }
        }

        // Si un message admin est plus récent que le dernier message user, c'est non lu
        if (lastAdminMessageTime != null) {
          if (lastUserMessageTime == null ||
              lastAdminMessageTime.isAfter(lastUserMessageTime)) {
            unreadCount++;
          }
        }
      }

      return unreadCount;
    });
  }

  /// Compter le total de notifications (tickets avec nouveaux messages admin)
  Stream<int> getTotalNotificationsCount(String userId) {
    return _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      int totalCount = 0;

      for (var doc in snapshot.docs) {
        final ticket = SupportTicket.fromFirestore(doc);

        // Ignorer les tickets fermés
        if (ticket.status == TicketStatus.closed) {
          continue;
        }

        // Ne compter que si le ticket a des messages
        if (ticket.messages.isEmpty) {
          continue;
        }

        // Vérifier s'il y a des messages admin non lus
        DateTime? lastUserMessageTime;
        DateTime? lastAdminMessageTime;

        for (var message in ticket.messages) {
          if (message.isAdmin) {
            if (lastAdminMessageTime == null ||
                message.timestamp.isAfter(lastAdminMessageTime)) {
              lastAdminMessageTime = message.timestamp;
            }
          } else if (message.senderId == userId) {
            if (lastUserMessageTime == null ||
                message.timestamp.isAfter(lastUserMessageTime)) {
              lastUserMessageTime = message.timestamp;
            }
          }
        }

        // Si le dernier message est de l'admin et plus récent que le dernier message utilisateur
        if (lastAdminMessageTime != null) {
          if (lastUserMessageTime == null ||
              lastAdminMessageTime.isAfter(lastUserMessageTime)) {
            totalCount++;
          }
        }
      }

      return totalCount;
    });
  }

  /// Compter les notifications pour l'admin (tickets avec nouveaux messages utilisateur non fermés)
  Stream<int> getAdminNotificationsCount() {
    return _firestore
        .collection('support_tickets')
        .where('status', whereIn: [
      TicketStatus.open.name,
      TicketStatus.inProgress.name,
      TicketStatus.waiting.name,
      TicketStatus.resolved.name,
    ])
        .snapshots()
        .map((snapshot) {
      int totalCount = 0;

      for (var doc in snapshot.docs) {
        final ticket = SupportTicket.fromFirestore(doc);

        // Compter seulement les tickets où le dernier message est d'un utilisateur (non admin)
        if (ticket.messages.isNotEmpty) {
          final lastMessage = ticket.messages.last;
          if (!lastMessage.isAdmin) {
            totalCount++;
          }
        }
      }

      return totalCount;
    });
  }
}