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
      case 'Disponible':
        return Colors.green;
      case 'occupée':
        return Colors.red;
      case 'réservée':
        return Colors.blue;
      case 'En maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
                height: 180, // Updated to a larger image size
                width: double.infinity,
                child: Image.network(
                  room.image,
                  fit: BoxFit.cover,
                ),
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
                      icon: Icon(LucideIcons.pencil, size: 20, color: Colors.white),
                      onPressed: () => onEdit(room.id),
                      tooltip: 'Modifier',
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(LucideIcons.trash, size: 20, color: Colors.white),
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
                      '\$${room.price}/nuit',
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
                    Icon(LucideIcons.hotel, size: 18, color: Colors.grey[700]),
                    SizedBox(width: 6),
                    Text(
                      '${room.type} Room',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(width: 20),
                    Icon(LucideIcons.users, size: 18, color: Colors.grey[700]),
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
                SizedBox(height: 8),

                // Amenities
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: room.amenities.map((amenity) {
                      return Chip(
                        label: Text(
                          amenity,
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        padding: EdgeInsets.all(6),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      );
                    }).toList(),
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
}

