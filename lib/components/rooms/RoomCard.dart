import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/room_models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final Function(String) onEdit;
  final Function(String) onDelete;

  // Transparent placeholder image bytes
  static final Uint8List kTransparentImage = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
    0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
    0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
    0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
    0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
    0x60, 0x82,
  ]);

  RoomCard({
    Key? key,
    required this.room,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'disponible':
        return Colors.green;
      case 'occupée':
        return Colors.red;
      case 'réservée':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Map amenities to their corresponding icons
  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return LucideIcons.wifi;
      case 'tv':
        return LucideIcons.tv;
      case 'piscine':
        return Icons.pool_outlined;
      case 'jaccuzy':
        return Icons.bathtub;
      case 'climatisation':
        return LucideIcons.thermometer;
      case 'minibar':
        return Icons.wine_bar;
      case 'coffre-fort':
        return LucideIcons.lock;
      case 'cuisine':
        return Icons.kitchen_outlined;
      case 'frigo':
        return LucideIcons.refrigerator;
      case 'vue sur mer':
        return LucideIcons.mountain;
      case 'petit-dejeuner':
        return Icons.free_breakfast;
      case 'salle de bain privée':
        return Icons.shower;
      case 'service en chambre':
        return LucideIcons.bellRing;
      case 'parking':
        return LucideIcons.car;
      default:
        return LucideIcons.check;
    }
  }

  // Build a list of amenity chips with icons
  List<Widget> _buildAmenityChips(List<String> amenities) {
    return amenities.map((amenity) {
      return Chip(
        avatar: Icon(
          _getAmenityIcon(amenity),
          size: 16,
          color: Colors.blue[700],
        ),
        label: Text(
          amenity,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue[800],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
        backgroundColor: Colors.blue.withOpacity(0.1),
      );
    }).toList();
  }

  // Widget for the default/error image
  Widget _buildPlaceholderImage({bool isError = false}) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isError ? LucideIcons.triangleAlert : LucideIcons.image,
            size: 40,
            color: isError ? Colors.orange[400] : Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            isError ? 'Impossible de charger l\'image' : 'Image non disponible',
            style: TextStyle(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          if (isError && kDebugMode)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Vérifiez l\'URL et les paramètres',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // Méthode pour corriger les URL Firebase si nécessaire
  String _sanitizeFirebaseUrl(String url) {
    if (url.isEmpty) return url;

    // Si l'URL ne contient pas encore ces paramètres, les ajouter
    if (!url.contains('alt=media')) {
      final separator = url.contains('?') ? '&' : '?';
      return '$url${separator}alt=media';
    }
    return url;
  }

  Widget _buildRoomImage() {
    if (room.imageUrl.isEmpty) {
      print('Aucune URL d\'image pour la chambre ${room.number}');
      return _buildPlaceholderImage();
    }

    // Ajout d'un timestamp pour éviter les problèmes de cache
    final String imageUrl = _sanitizeFirebaseUrl(room.imageUrl);
    final String imageUrlWithTimestamp = '$imageUrl&_t=${DateTime.now().millisecondsSinceEpoch}';

    print('Tentative de chargement de l\'image: $imageUrlWithTimestamp');

    // Utiliser CachedNetworkImage pour une meilleure gestion du cache
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: CachedNetworkImage(
        imageUrl: imageUrlWithTimestamp,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),
        // Placeholder pendant le chargement
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        // Gestion des erreurs
        errorWidget: (context, url, error) {
          print('Erreur de chargement d\'image: $error');
          return _buildPlaceholderImage(isError: true);
        },
        // Headers pour gérer les problèmes CORS (même si vous les avez résolus au niveau du serveur)
        httpHeaders: kIsWeb ? {
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        } : null,
        // Configurer le cache local (uniquement pour les applications mobiles)
        cacheManager: kIsWeb ? null : DefaultCacheManager(),
        cacheKey: 'room_${room.id}_image',
        // Empêcher le cache du navigateur en mode web
        useOldImageOnUrlChange: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Image de la chambre
              _buildRoomImage(),

              // Statut de la chambre
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(room.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    room.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Type de chambre
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    room.type,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),

              // Boutons d'édition et de suppression
              Positioned(
                bottom: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                          LucideIcons.pencil,
                          size: 20,
                          color: Colors.white
                      ),
                      onPressed: () => onEdit(room.id),
                      tooltip: 'Modifier',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                          LucideIcons.trash,
                          size: 20,
                          color: Colors.white
                      ),
                      onPressed: () => onDelete(room.id),
                      tooltip: 'Supprimer',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Numéro de chambre et prix
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chambre ${room.number}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'FCFA ${room.price}/nuit',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Type de chambre et capacité avec icônes
                Row(
                  children: [
                    Icon(LucideIcons.hotel, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 6),
                    Text(
                      '${room.type} chambre',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Icon(LucideIcons.users, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 6),
                    Text(
                      'Capacité : ${room.capacity} personne${room.capacity > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Titre de la section des commodités
                const Text(
                  'Commodités',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Liste des commodités avec icônes
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildAmenityChips(room.amenities),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}