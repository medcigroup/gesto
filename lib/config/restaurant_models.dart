// ================================
// MODÈLES DE DONNÉES (restaurant_models.dart)
// ================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Modèle pour les tables du restaurant
class RestaurantTable {
  final String id;
  final String tableNumber;
  final int capacity;
  final String location; // terrasse, intérieur, VIP
  final String status; // libre, occupée, réservée, maintenance
  final String? currentOrderId;
  final DateTime? reservationTime;
  final String? reservedFor;
  final String userId; // ID du propriétaire de l'hôtel

  RestaurantTable({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.location,
    required this.status,
    this.currentOrderId,
    this.reservationTime,
    this.reservedFor,
    required this.userId,
  });

  factory RestaurantTable.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RestaurantTable(
      id: doc.id,
      tableNumber: data['tableNumber'] ?? '',
      capacity: data['capacity'] ?? 2,
      location: data['location'] ?? 'intérieur',
      status: data['status'] ?? 'libre',
      currentOrderId: data['currentOrderId'],
      reservationTime: data['reservationTime']?.toDate(),
      reservedFor: data['reservedFor'],
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableNumber': tableNumber,
      'capacity': capacity,
      'location': location,
      'status': status,
      'currentOrderId': currentOrderId,
      'reservationTime': reservationTime != null ? Timestamp.fromDate(reservationTime!) : null,
      'reservedFor': reservedFor,
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// Modèle pour les articles du menu
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category; // entrée, plat, dessert, boisson
  final String? imageUrl;
  final bool isAvailable;
  final List<String> allergens;
  final int preparationTime; // en minutes
  final String userId;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.isAvailable,
    required this.allergens,
    required this.preparationTime,
    required this.userId,
  });

  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'],
      isAvailable: data['isAvailable'] ?? true,
      allergens: List<String>.from(data['allergens'] ?? []),
      preparationTime: data['preparationTime'] ?? 15,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'allergens': allergens,
      'preparationTime': preparationTime,
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// Modèle pour les articles commandés
class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? specialInstructions;
  final String status; // commandé, en_preparation, prêt, servi
  final String category; // entrée, plat, dessert, boisson;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.specialInstructions,
    required this.status,
    required this.category,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      menuItemId: data['menuItemId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: data['quantity'] ?? 1,
      specialInstructions: data['specialInstructions'],
      status: data['status'] ?? 'commandé',
      category: data['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'specialInstructions': specialInstructions,
      'status': status,
      'category': category,
    };
  }

  double get totalPrice => price * quantity;
}

// Modèle pour les commandes du restaurant (CORRIGÉ)
class RestaurantOrder {
  final String id;
  final String tableId;
  final String tableNumber;
  final String customerType; // hotel_guest, external
  final String? hotelGuestId; // ID du client hôtel si applicable
  final String? guestName;
  final String? guestPhone;
  final String? roomNumber; // Si client d'hôtel
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double serviceCharge;
  final double total;
  final String status; // en_cours, terminée, annulée, payée
  final String paymentMethod; // espèces, carte, chambre (pour clients hôtel)
  final DateTime createdAt;
  final DateTime? completedAt;
  final String userId;
  final String? waiterId;
  final String? specialRequests;
  final bool? isRoomService; // NOUVEAU CHAMP

  RestaurantOrder({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.customerType,
    this.hotelGuestId,
    this.guestName,
    this.guestPhone,
    this.roomNumber,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.completedAt,
    required this.userId,
    this.waiterId,
    this.specialRequests,
    this.isRoomService,
  });

  factory RestaurantOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RestaurantOrder(
      id: doc.id,
      tableId: data['tableId'] ?? '',
      tableNumber: data['tableNumber'] ?? '',
      customerType: data['customerType'] ?? 'external',
      hotelGuestId: data['hotelGuestId'],
      guestName: data['guestName'],
      guestPhone: data['guestPhone'],
      roomNumber: data['roomNumber'],
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      tax: (data['tax'] ?? 0.0).toDouble(),
      serviceCharge: (data['serviceCharge'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'en_cours',
      paymentMethod: data['paymentMethod'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt']?.toDate(),
      userId: data['userId'] ?? '',
      waiterId: data['waiterId'],
      specialRequests: data['specialRequests'],
      isRoomService: data['isRoomService'], // AJOUTÉ
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableId': tableId,
      'tableNumber': tableNumber,
      'customerType': customerType,
      'hotelGuestId': hotelGuestId,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'roomNumber': roomNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'serviceCharge': serviceCharge,
      'total': total,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'userId': userId,
      'waiterId': waiterId,
      'specialRequests': specialRequests,
      'isRoomService': isRoomService, // AJOUTÉ
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// Modèle pour les réservations de table
class TableReservation {
  final String id;
  final String tableId;
  final String tableNumber;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String customerType; // hotel_guest, external
  final String? roomNumber;
  final DateTime reservationDate;
  final TimeOfDay reservationTime;
  final int numberOfGuests;
  final String status; // confirmée, en_attente, annulée, terminée
  final String? specialRequests;
  final DateTime createdAt;
  final String userId;

  TableReservation({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.customerType,
    this.roomNumber,
    required this.reservationDate,
    required this.reservationTime,
    required this.numberOfGuests,
    required this.status,
    this.specialRequests,
    required this.createdAt,
    required this.userId,
  });

  factory TableReservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Conversion de l'heure depuis la base de données
    final timeData = data['reservationTime'] as Map<String, dynamic>?;
    final reservationTime = timeData != null
        ? TimeOfDay(hour: timeData['hour'] ?? 12, minute: timeData['minute'] ?? 0)
        : TimeOfDay(hour: 12, minute: 0);

    return TableReservation(
      id: doc.id,
      tableId: data['tableId'] ?? '',
      tableNumber: data['tableNumber'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerEmail: data['customerEmail'],
      customerType: data['customerType'] ?? 'external',
      roomNumber: data['roomNumber'],
      reservationDate: (data['reservationDate'] as Timestamp).toDate(),
      reservationTime: reservationTime,
      numberOfGuests: data['numberOfGuests'] ?? 2,
      status: data['status'] ?? 'en_attente',
      specialRequests: data['specialRequests'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableId': tableId,
      'tableNumber': tableNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'customerType': customerType,
      'roomNumber': roomNumber,
      'reservationDate': Timestamp.fromDate(reservationDate),
      'reservationTime': {
        'hour': reservationTime.hour,
        'minute': reservationTime.minute,
      },
      'numberOfGuests': numberOfGuests,
      'status': status,
      'specialRequests': specialRequests,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// ================================
// SERVICES (restaurant_service.dart)
// ================================

class RestaurantService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== GESTION DES TABLES ==========

  static Future<List<RestaurantTable>> getTables(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('restaurant_tables')
          .where('userId', isEqualTo: userId)
          .orderBy('tableNumber')
          .get();

      return snapshot.docs.map((doc) => RestaurantTable.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors du chargement des tables: $e');
      return [];
    }
  }

  static Future<void> addTable(RestaurantTable table) async {
    await _firestore.collection('restaurant_tables').add(table.toMap());
  }

  static Future<void> updateTable(String tableId, RestaurantTable table) async {
    await _firestore.collection('restaurant_tables').doc(tableId).update(table.toMap());
  }

  static Future<void> updateTableStatus(String tableId, String status) async {
    await _firestore.collection('restaurant_tables').doc(tableId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== GESTION DU MENU ==========

  static Future<List<MenuItem>> getMenuItems(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('restaurant_menu')
          .where('userId', isEqualTo: userId)
          .orderBy('category')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors du chargement du menu: $e');
      return [];
    }
  }

  static Future<List<MenuItem>> getMenuByCategory(String userId, String category) async {
    try {
      final snapshot = await _firestore
          .collection('restaurant_menu')
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .where('isAvailable', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors du chargement du menu par catégorie: $e');
      return [];
    }
  }

  static Future<void> addMenuItem(MenuItem item) async {
    await _firestore.collection('restaurant_menu').add(item.toMap());
  }

  static Future<void> updateMenuItem(String itemId, MenuItem item) async {
    await _firestore.collection('restaurant_menu').doc(itemId).update(item.toMap());
  }

  static Future<void> toggleMenuItemAvailability(String itemId, bool isAvailable) async {
    await _firestore.collection('restaurant_menu').doc(itemId).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== GESTION DES COMMANDES ==========

  static Future<String> createOrder(RestaurantOrder order) async {
    try {
      final docRef = await _firestore.collection('restaurant_orders').add(order.toMap());

      // Mettre à jour le statut de la table SEULEMENT si ce n'est pas un service en chambre
      if (order.isRoomService != true && order.tableId.isNotEmpty) {
        await updateTableStatus(order.tableId, 'occupée');
      }

      return docRef.id;
    } catch (e) {
      print('❌ Erreur lors de la création de la commande: $e');
      throw Exception('Erreur lors de la création de la commande: $e');
    }
  }

  static Future<List<RestaurantOrder>> getActiveOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('restaurant_orders')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['en_cours', 'terminée'])
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => RestaurantOrder.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Erreur lors du chargement des commandes actives: $e');
      return [];
    }
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'payée') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('restaurant_orders').doc(orderId).update(updateData);
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du statut de commande: $e');
      throw Exception('Erreur lors de la mise à jour du statut de commande: $e');
    }
  }

  static Future<void> updateOrderPayment(String orderId, String paymentMethod) async {
    try {
      await _firestore.collection('restaurant_orders').doc(orderId).update({
        'paymentMethod': paymentMethod,
        'status': 'payée',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du paiement: $e');
      throw Exception('Erreur lors de la mise à jour du paiement: $e');
    }
  }

  // ========== GESTION DES RÉSERVATIONS ==========

  static Future<List<TableReservation>> getReservations(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('table_reservations')
          .where('userId', isEqualTo: userId)
          .where('reservationDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('reservationDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('reservationDate')
          .get();

      return snapshot.docs.map((doc) => TableReservation.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors du chargement des réservations: $e');
      return [];
    }
  }

  static Future<void> addReservation(TableReservation reservation) async {
    await _firestore.collection('table_reservations').add(reservation.toMap());
  }

  static Future<void> updateReservationStatus(String reservationId, String status) async {
    await _firestore.collection('table_reservations').doc(reservationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== RECHERCHE DE CLIENTS HÔTEL ==========

  static Future<List<Map<String, dynamic>>> searchHotelGuests(String userId, String query) async {
    try {
      // Rechercher dans les bookings actifs
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'enregistré')
          .get();

      final guests = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final customerName = data['customerName'] as String? ?? '';
        final roomNumber = data['roomNumber'] as String? ?? '';

        if (customerName.toLowerCase().contains(query.toLowerCase()) ||
            roomNumber.toLowerCase().contains(query.toLowerCase())) {
          guests.add({
            'id': doc.id,
            'name': customerName,
            'roomNumber': roomNumber,
            'phone': data['customerPhone'] ?? '',
            'email': data['customerEmail'] ?? '',
          });
        }
      }

      return guests;
    } catch (e) {
      print('Erreur lors de la recherche des clients: $e');
      return [];
    }
  }
  // ========== RECHERCHE DES INFOS DU STAFF ==========
  static final Map<String, Map<String, dynamic>> _staffCache = {};

  static Future<Map<String, dynamic>?> getStaffInfo(String waiterId) async {
    if (waiterId.isEmpty) return null;

    // Vérifier le cache
    if (_staffCache.containsKey(waiterId)) {
      return _staffCache[waiterId];
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('staff')
          .doc(waiterId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final staffInfo = {
          'nom': data['nom'] ?? '',
          'prenom': data['prenom'] ?? '',
          'poste': data['poste'] ?? '',
          'departement': data['departement'] ?? '',
          'email': data['email'] ?? '',
          'photoUrl': data['photoUrl'],
        };

        // Mettre en cache
        _staffCache[waiterId] = staffInfo;
        return staffInfo;
      }
    } catch (e) {
      print('❌ Erreur chargement info serveur: $e');
    }

    return null;
  }


  // ========== STATISTIQUES ==========

  static Future<Map<String, dynamic>> getRestaurantStats(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('restaurant_orders')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'payée')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double totalRevenue = 0;
      int totalOrders = snapshot.docs.length;
      int hotelGuestOrders = 0;
      int externalOrders = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['total'] ?? 0.0).toDouble();

        if (data['customerType'] == 'hotel_guest') {
          hotelGuestOrders++;
        } else {
          externalOrders++;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'hotelGuestOrders': hotelGuestOrders,
        'externalOrders': externalOrders,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
      };
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {
        'totalRevenue': 0.0,
        'totalOrders': 0,
        'hotelGuestOrders': 0,
        'externalOrders': 0,
        'averageOrderValue': 0.0,
      };
    }
  }
}

// ================================
// STRUCTURE DES PAGES
// ================================

/*
📁 restaurant/
  📁 pages/
    📄 restaurant_dashboard.dart         // Tableau de bord principal
    📄 tables_management.dart           // Gestion des tables
    📄 menu_management.dart             // Gestion du menu/carte
    📄 order_taking.dart               // Prise de commandes
    📄 active_orders.dart              // Commandes en cours
    📄 billing_page.dart               // Facturation
    📄 table_reservations.dart         // Réservations de tables
    📄 restaurant_reports.dart         // Rapports et statistiques

  📁 components/
    📄 table_status_card.dart          // Carte statut table
    📄 menu_item_card.dart             // Carte article menu
    📄 order_item_widget.dart          // Widget article commandé
    📄 customer_search_dialog.dart     // Recherche client hôtel
    📄 payment_dialog.dart             // Dialog paiement

  📁 services/
    📄 restaurant_service.dart          // Service principal
    📄 restaurant_models.dart           // Modèles de données

  📁 utils/
    📄 restaurant_constants.dart        // Constantes
    📄 restaurant_helpers.dart          // Fonctions utilitaires
*/

// ================================
// CONSTANTES (restaurant_constants.dart)
// ================================

class RestaurantConstants {
  // Statuts des tables
  static const String tableStatusFree = 'libre';
  static const String tableStatusOccupied = 'occupée';
  static const String tableStatusReserved = 'réservée';
  static const String tableStatusMaintenance = 'maintenance';

  // Types de clients
  static const String customerTypeHotel = 'hotel_guest';
  static const String customerTypeExternal = 'external';

  // Catégories du menu
  static const List<String> menuCategories = [
    'Entrées',
    'Plats principaux',
    'Desserts',
    'Boissons',
    'Vins',
    'Cocktails',
  ];

  // Méthodes de paiement
  static const List<String> paymentMethods = [
    'Espèces',
    'Carte bancaire',
    'Facturation chambre',
    'Chèque',
    'Mobile Money',
  ];

  // Statuts des commandes
  static const String orderStatusInProgress = 'en_cours';
  static const String orderStatusCompleted = 'terminée';
  static const String orderStatusPaid = 'payée';
  static const String orderStatusCancelled = 'annulée';

  // Emplacements des tables
  static const List<String> tableLocations = [
    'Intérieur',
    'Terrasse',
    'VIP',
    'Bar',
    'Jardin',
  ];

  // Configuration par défaut
  static const double defaultTaxRate = 0.18; // 18% TVA
  static const double defaultServiceCharge = 0.10; // 10% service
}