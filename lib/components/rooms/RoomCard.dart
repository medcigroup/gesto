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
          // Afficher l'image par défaut au lieu du placeholder
          return ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              'assets/images/default_room.jpg',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback ultime si même l'asset n'est pas disponible
                return Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.hotel, size: 50, color: Colors.grey),
                  ),
                );
              },
            ),
          );
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 5,
        shadowColor: _getStatusColor(room.status).withOpacity(0.3),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                _getStatusColor(room.status).withOpacity(0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // Image de la chambre avec overlay gradient
                  Stack(
                    children: [
                      _buildRoomImage(),
                      // Gradient overlay pour meilleure lisibilité
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Badge du statut moderne
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(room.status),
                            _getStatusColor(room.status).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(room.status).withOpacity(0.5),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            room.status == 'disponible' ? LucideIcons.check :
                            room.status == 'occupée' ? LucideIcons.user :
                            room.status == 'réservée' ? LucideIcons.clock :
                            LucideIcons.wrench,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            room.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Type de chambre avec icône
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.hotel, size: 14, color: Colors.blue.shade700),
                          SizedBox(width: 6),
                          Text(
                            room.type,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Info chambre en bas de l'image
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Numéro de chambre
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.meeting_room, size: 20, color: Colors.blue.shade700),
                              SizedBox(width: 8),
                              Text(
                                'Ch. ${room.number}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Boutons d'action
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(LucideIcons.pencil, size: 18, color: Colors.white),
                                onPressed: () => onEdit(room.id),
                                tooltip: 'Modifier',
                                padding: EdgeInsets.all(8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(LucideIcons.trash, size: 18, color: Colors.white),
                                onPressed: () => onDelete(room.id),
                                tooltip: 'Supprimer',
                                padding: EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Contenu de la carte
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prix et capacité
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Prix
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade50, Colors.green.shade100],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.banknote, size: 20, color: Colors.green.shade700),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${room.price.toStringAsFixed(0)} FCFA',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    'par nuit',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Capacité
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade50, Colors.blue.shade100],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.users, size: 20, color: Colors.blue.shade700),
                              SizedBox(width: 8),
                              Text(
                                '${room.capacity} ${room.capacity > 1 ? 'pers.' : 'pers.'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Divider(color: Colors.grey.shade200),

                    const SizedBox(height: 12),

                    // Commodités avec titre moderne
                    Row(
                      children: [
                        Icon(LucideIcons.sparkles, size: 18, color: Colors.purple.shade600),
                        SizedBox(width: 8),
                        Text(
                          'Équipements',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Liste des commodités avec design amélioré
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: room.amenities.take(3).map((amenity) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.purple.shade50, Colors.purple.shade100],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getAmenityIcon(amenity),
                                size: 12,
                                color: Colors.purple.shade700,
                              ),
                              SizedBox(width: 3),
                              Text(
                                amenity,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    if (room.amenities.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '+${room.amenities.length - 3} autres équipements',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}