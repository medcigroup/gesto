import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../components/rooms/RoomCalendar.dart';
import '../components/rooms/RoomCard.dart';
import '../components/rooms/room_data.dart';
import '../config/room_models.dart';

class RoomsPage extends StatefulWidget {
  @override
  _RoomsPageState createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  List<Room> rooms = roomsData;
  String view = 'grid';
  String searchTerm = '';
  String filterStatus = 'tout'; // 'all' traduit en 'tout'
  String filterType = 'tout'; // 'all' traduit en 'tout'

  void handleEditRoom(String id) {
    print('Modifier la chambre $id'); // 'Edit room' traduit en 'Modifier la chambre'
  }

  void handleDeleteRoom(String id) {
    print('Supprimer la chambre $id'); // 'Delete room' traduit en 'Supprimer la chambre'
  }

  List<Room> get filteredRooms {
    return rooms.where((room) {
      final matchesSearch =
      room.number.toLowerCase().contains(searchTerm.toLowerCase());
      final matchesStatus = filterStatus == 'tout' || room.status == filterStatus;
      final matchesType = filterType == 'tout' || room.type == filterType;
      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Row(
          children: [
            IconButton(
              icon: Icon(LucideIcons.layoutGrid, color: Colors.black87),
              onPressed: () => setState(() => view = 'grid'),
            ),
            IconButton(
              icon: Icon(LucideIcons.calendar, color: Colors.grey),
              onPressed: () => setState(() => view = 'calendar'),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Rechercher des chambres...", // "Search rooms..." traduit en "Rechercher des chambres..."
                  prefixIcon: Icon(LucideIcons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.grey[200],
                  filled: true,
                ),
                onChanged: (value) => setState(() => searchTerm = value),
              ),
            ),
            SizedBox(width: 12),
            DropdownButton<String>(
              value: filterStatus,
              items: [
                DropdownMenuItem(value: 'tout', child: Text("Tous les statuts")), // "All Status" traduit en "Tous les statuts"
                DropdownMenuItem(value: 'disponible', child: Text("Disponible")), // "Available" traduit en "Disponible"
                DropdownMenuItem(value: 'occupée', child: Text("Occupée")), // "Occupied" traduit en "Occupée"
                DropdownMenuItem(value: 'réservée', child: Text("Réservée")), // "Reserved" traduit en "Réservée"
              ],
              onChanged: (value) => setState(() => filterStatus = value!),
            ),
            SizedBox(width: 12),
            DropdownButton<String>(
              value: filterType,
              items: [
                DropdownMenuItem(value: 'tout', child: Text("Tous les types")), // "All Types" traduit en "Tous les types"
                DropdownMenuItem(value: 'simple', child: Text("Simple")), // "Single" traduit en "Simple"
                DropdownMenuItem(value: 'double', child: Text("Double")),
                DropdownMenuItem(value: 'suite', child: Text("Suite")),
              ],
              onChanged: (value) => setState(() => filterType = value!),
            ),
            SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {},
              icon: Icon(LucideIcons.plus, size: 20, color: Colors.white),
              label: Text("Ajouter une chambre", style: TextStyle(color: Colors.white)), // "Add Room" traduit en "Ajouter une chambre"
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final screenWidth = constraints.maxWidth;
          int crossAxisCount = 4;

          if (screenWidth < 600) {
            crossAxisCount = 1;
          } else if (screenWidth < 900) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = 4;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16),
                Expanded(
                  child: view == 'grid'
                      ? GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      return RoomCard(
                        room: room,
                        onEdit: handleEditRoom,
                        onDelete: handleDeleteRoom,
                      );
                    },
                  )
                      : RoomCalendar(
                    rooms: rooms,
                    bookings: bookingsData,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

