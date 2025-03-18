import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String number;
  final String type;
  final String status;
  final double price;
  final int capacity;
  final List<String> amenities;
  final int floor;
  final String image;
  final String imageUrl;
  final String description;
  final String datedisponible;
  final String userId;  // Ajout du champ userId

  Room({
    required this.id,
    required this.number,
    required this.type,
    required this.status,
    required this.price,
    required this.capacity,
    required this.amenities,
    required this.floor,
    required this.image,
    this.imageUrl = '',
    this.description = '',
    this.datedisponible = '',
    required this.userId,  // Assurez-vous d'inclure userId dans le constructeur
  });

  // Méthode factory pour créer une Room depuis Firestore
  factory Room.fromFirestore(Map<String, dynamic> data) {
    return Room(
      id: data['id'],
      number: data['number'],
      type: data['type'],
      status: data['status'],
      price: data['price'].toDouble(),
      capacity: data['capacity'],
      amenities: List<String>.from(data['amenities']),
      floor: data['floor'],
      image: data['image'],
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      datedisponible: data['datedisponible'] ?? '',
      userId: data['userId'] ?? '',  // Assurez-vous que userId est récupéré depuis Firestore
    );
  }

  // Méthode pour convertir une Room en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'number': number,
      'type': type,
      'status': status,
      'price': price,
      'capacity': capacity,
      'amenities': amenities,
      'floor': floor,
      'image': image,
      'imageUrl': imageUrl,
      'description': description,
      'datedisponible': datedisponible,
      'userId': userId,  // Assurez-vous que userId est inclus dans les données Firestore
    };
  }
}

class Booking {
  final String id;
  final String roomId;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final String status;

  Booking({
    required this.id,
    required this.roomId,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });

  // Méthode factory pour créer un Booking depuis Firestore
  factory Booking.fromFirestore(Map<String, dynamic> data) {
    return Booking(
      id: data['id'],
      roomId: data['roomId'],
      guestName: data['guestName'],
      checkIn: (data['checkIn'] as Timestamp).toDate(),
      checkOut: (data['checkOut'] as Timestamp).toDate(),
      status: data['status'],
    );
  }

  // Méthode pour convertir un Booking en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'roomId': roomId,
      'guestName': guestName,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'status': status,
    };
  }
}
