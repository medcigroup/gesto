import 'package:flutter/material.dart';

/// Modèle pour les services/commodités d'hôtel
class HotelAmenityData {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String category;

  const HotelAmenityData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
  });
}

/// Liste globale de tous les services/commodités disponibles
class HotelAmenities {
  static const List<HotelAmenityData> all = [
    // Services essentiels
    HotelAmenityData(
      id: 'wifi',
      title: 'WiFi Haut Débit',
      subtitle: 'Connexion gratuite',
      icon: Icons.wifi,
      category: 'Essentiel',
    ),
    HotelAmenityData(
      id: 'parking',
      title: 'Parking',
      subtitle: 'Sécurisé & gratuit',
      icon: Icons.local_parking,
      category: 'Essentiel',
    ),
    HotelAmenityData(
      id: 'reception24',
      title: 'Réception 24h/24',
      subtitle: 'Service continu',
      icon: Icons.support_agent,
      category: 'Essentiel',
    ),
    HotelAmenityData(
      id: 'ac',
      title: 'Climatisation',
      subtitle: 'Dans toutes les chambres',
      icon: Icons.ac_unit,
      category: 'Essentiel',
    ),

    // Restauration
    HotelAmenityData(
      id: 'restaurant',
      title: 'Restaurant',
      subtitle: 'Cuisine locale & internationale',
      icon: Icons.restaurant_menu,
      category: 'Restauration',
    ),
    HotelAmenityData(
      id: 'breakfast',
      title: 'Petit-déjeuner',
      subtitle: 'Buffet continental',
      icon: Icons.free_breakfast,
      category: 'Restauration',
    ),
    HotelAmenityData(
      id: 'roomservice',
      title: 'Room Service',
      subtitle: 'Service 24h/24',
      icon: Icons.room_service,
      category: 'Restauration',
    ),
    HotelAmenityData(
      id: 'bar',
      title: 'Bar',
      subtitle: 'Cocktails & boissons',
      icon: Icons.local_bar,
      category: 'Restauration',
    ),

    // Loisirs & Bien-être
    HotelAmenityData(
      id: 'pool',
      title: 'Piscine',
      subtitle: 'Disponible 24/7',
      icon: Icons.pool,
      category: 'Loisirs',
    ),
    HotelAmenityData(
      id: 'gym',
      title: 'Salle de Sport',
      subtitle: 'Équipement moderne',
      icon: Icons.fitness_center,
      category: 'Loisirs',
    ),
    HotelAmenityData(
      id: 'spa',
      title: 'Spa & Bien-être',
      subtitle: 'Massage & soins',
      icon: Icons.spa,
      category: 'Loisirs',
    ),
    HotelAmenityData(
      id: 'sauna',
      title: 'Sauna',
      subtitle: 'Détente & relaxation',
      icon: Icons.hot_tub,
      category: 'Loisirs',
    ),
    HotelAmenityData(
      id: 'garden',
      title: 'Jardin',
      subtitle: 'Espace vert',
      icon: Icons.park,
      category: 'Loisirs',
    ),

    // Services
    HotelAmenityData(
      id: 'shuttle',
      title: 'Navette Aéroport',
      subtitle: 'Transport inclus',
      icon: Icons.airport_shuttle,
      category: 'Services',
    ),
    HotelAmenityData(
      id: 'laundry',
      title: 'Blanchisserie',
      subtitle: 'Service de nettoyage',
      icon: Icons.local_laundry_service,
      category: 'Services',
    ),
    HotelAmenityData(
      id: 'concierge',
      title: 'Conciergerie',
      subtitle: 'Assistance personnalisée',
      icon: Icons.headset_mic,
      category: 'Services',
    ),
    HotelAmenityData(
      id: 'pets',
      title: 'Animaux Acceptés',
      subtitle: 'Bienvenue aux animaux',
      icon: Icons.pets,
      category: 'Services',
    ),

    // Business
    HotelAmenityData(
      id: 'meeting',
      title: 'Salle de Réunion',
      subtitle: 'Équipement professionnel',
      icon: Icons.meeting_room,
      category: 'Business',
    ),
    HotelAmenityData(
      id: 'business',
      title: 'Centre d\'Affaires',
      subtitle: 'Services professionnels',
      icon: Icons.business_center,
      category: 'Business',
    ),
  ];

  /// Récupère un amenity par son ID
  static HotelAmenityData? getById(String id) {
    try {
      return all.firstWhere((amenity) => amenity.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Récupère plusieurs amenities par leurs IDs
  static List<HotelAmenityData> getByIds(List<String> ids) {
    return ids
        .map((id) => getById(id))
        .where((amenity) => amenity != null)
        .cast<HotelAmenityData>()
        .toList();
  }

  /// Récupère tous les amenities d'une catégorie
  static List<HotelAmenityData> getByCategory(String category) {
    return all.where((amenity) => amenity.category == category).toList();
  }
}
