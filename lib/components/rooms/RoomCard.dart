import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/room_models.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final Function(String) onEdit;
  final Function(String) onDelete;

  RoomCard({
    required this.room,
    required this.onEdit,
    required this.onDelete,
  });

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
        padding: EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
        backgroundColor: Colors.blue.withOpacity(0.1),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: _buildRoomImage(context),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(room.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    room.status.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Icons for Edit and Delete next to Status
              Positioned(
                top: 8,
                left: 8,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(LucideIcons.pencil, size: 20, color: Colors.grey),
                      onPressed: () => onEdit(room.id),
                      tooltip: 'Modifier',
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(LucideIcons.trash, size: 20, color: Colors.grey),
                      onPressed: () => onDelete(room.id),
                      tooltip: 'Supprimer',
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
                // Room Name and Price in the Same Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chambre ${room.number}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '\FCFA ${room.price}/nuit',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),

                // Room Type and Capacity with Icons
                Row(
                  children: [
                    Icon(LucideIcons.hotel, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 6),
                    Text(
                      '${room.type} chambre',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(width: 20),
                    Icon(LucideIcons.users, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 6),
                    Text(
                      'Capacité : ${room.capacity} personne${room.capacity > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Section title for amenities
                SizedBox(width: 6),
                Text(
                  'Commodités ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),

                // Amenities with icons
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _buildAmenityChips(room.amenities),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Improved method to handle image loading with robust error handling
  Widget _buildRoomImage(BuildContext context) {
    // Check if image URL is empty, null, or invalid
    if (room.image == null || room.image.isEmpty) {
      return _buildDefaultImage();
    }

    // Use network image with complete error handling
    return FadeInImage.assetNetwork(
      placeholder: 'assets/images/placeholder.png', // Light placeholder while loading
      image: room.image,
      fit: BoxFit.cover,
      imageErrorBuilder: (context, error, stackTrace) {
        // Handle all network image errors by showing default image
        return _buildDefaultImage();
      },
    );
  }

  // Extract default image to a separate method
  Widget _buildDefaultImage() {
    try {
      // Primary option: use asset image
      return Image.asset(
        'assets/images/default_room.jpg',
        fit: BoxFit.cover,
      );
    } catch (e) {
      // Fallback option if asset loading fails: use a colored container with an icon
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            LucideIcons.hotel,
            size: 60,
            color: Colors.grey[600],
          ),
        ),
      );
    }
  }
}

