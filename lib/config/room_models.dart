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
  final String userId;
  final bool passage;
  final int priceHour;
  // Nouveau champ pour indiquer si l'image est par défaut
  final bool isDefaultImage;
  // Nouvelle structure pour stocker les métadonnées de l'image
  final Map<String, dynamic>? imageMetadata;

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
    required this.userId,
    this.passage = false,
    this.priceHour = 0,
    this.isDefaultImage = false,
    this.imageMetadata,
  });

  // Méthode factory pour créer une Room depuis Firestore avec gestion des erreurs
  factory Room.fromFirestore(Map<String, dynamic> data) {
    // Initialiser les variables pour l'image
    String imagePath = '';
    String imageUrl = '';
    bool isDefaultImage = false;
    Map<String, dynamic>? imageMetadata;

    try {
      // Gérer le cas où 'image' est un objet (nouveau format)
      if (data['image'] is Map) {
        imageMetadata = Map<String, dynamic>.from(data['image']);
        imagePath = imageMetadata['path'] ?? '';
        imageUrl = imageMetadata['url'] ?? '';
        isDefaultImage = imageMetadata['isDefault'] ?? false;
      }
      // Gérer le cas où 'image' est une chaîne (ancien format)
      else if (data['image'] is String) {
        imagePath = data['image'];
        imageUrl = data['imageUrl'] ?? '';
        isDefaultImage = false;
      }
      // Cas par défaut si 'image' est null ou d'un autre type
      else {
        imagePath = '';
        imageUrl = data['imageUrl'] ?? '';
        isDefaultImage = true;
      }
    } catch (e) {
      print('Erreur lors de l\'extraction des données d\'image: $e');
      // En cas d'erreur, utiliser des valeurs par défaut sécurisées
      imagePath = '';
      imageUrl = '';
      isDefaultImage = true;
    }

    return Room(
      id: data['id'] ?? '',
      number: data['number'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      capacity: data['capacity'] ?? 0,
      amenities: List<String>.from(data['amenities'] ?? []),
      floor: data['floor'] ?? 0,
      image: imagePath,
      imageUrl: imageUrl,
      description: data['description'] ?? '',
      datedisponible: data['datedisponible'] ?? '',
      userId: data['userId'] ?? '',
      passage: data['passage'] ?? false,
      priceHour: data['pricehour'] ?? 0,
      isDefaultImage: isDefaultImage,
      imageMetadata: imageMetadata,
    );
  }

  // Méthode pour convertir une Room en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    // Si nous avons des métadonnées d'image, les utiliser
    // Sinon, créer une nouvelle structure
    final Map<String, dynamic> imageData = imageMetadata ?? {
      'url': imageUrl,
      'path': image,
      'isDefault': isDefaultImage,
      'fileName': image.split('/').last,
      'uploadedAt': FieldValue.serverTimestamp(),
    };

    return {
      'id': id,
      'number': number,
      'type': type,
      'status': status,
      'price': price,
      'capacity': capacity,
      'amenities': amenities,
      'floor': floor,
      'image': imageData, // Stocker l'objet complet
      'imageUrl': imageUrl, // Conserver pour la compatibilité descendante
      'description': description,
      'datedisponible': datedisponible,
      'userId': userId,
      'passage': passage,
      'pricehour': priceHour,
      'updatedAt': FieldValue.serverTimestamp(),
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
