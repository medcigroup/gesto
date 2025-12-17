import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../components/rooms/RoomCalendar.dart';
import '../../components/rooms/RoomCard.dart';
import '../../config/HotelSettingsService.dart';
import '../../config/checkRoomCreationLimit.dart';
import '../../config/room_models.dart';
import '../../widgets/side_menu.dart';
import 'AddRoomBottomSheet.dart';
import 'EditRoomBottomSheet.dart';


class RoomsPage extends StatefulWidget {
  @override
  _RoomsPageState createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  List<Room> rooms = [];
  List<Booking> bookings = [];
  String view = 'grid';
  String _previousView = 'grid';
  String searchTerm = '';
  String filterStatus = 'tout';
  String filterType = 'tout';
  bool isLoading = false;
  String? userId;
  String sortOrder = 'asc';  // Pour le tri dynamique

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid; // Récupérer l'ID de l'utilisateur
    fetchRooms(); // Charger les chambres depuis Firebase au démarrage
    fetchBookings(); // Charger les réservations
  }

  // Méthode pour rafraîchir les données
  Future<void> _refreshData() async {
    await Future.wait([
      fetchRooms(),
      fetchBookings(),
    ]);
  }

  // Méthode pour détecter le changement de vue et actualiser
  void _onViewChanged(String newView) {
    if (_previousView != newView) {
      _previousView = newView;
      _refreshData();
    }
  }

  // Fonction pour ouvrir le bottom sheet d'ajout
  void _showAddRoomBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddRoomBottomSheet(
        onRoomAdded: fetchRooms, // Rafraîchir la liste après l'ajout
      ),
    );
  }

  // Fonction pour ouvrir le bottom sheet d'édition
  void _showEditRoomBottomSheet(Room room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditRoomBottomSheet(
        room: room,
        onRoomEdited: fetchRooms, // Rafraîchir la liste après la modification
      ),
    );
  }

  // Récupérer les chambres depuis Firebase
  Future<void> fetchRooms() async {
    if (userId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('userId', isEqualTo: userId)
          .get();

      final fetchedRooms = snapshot.docs.map((doc) {
        final data = doc.data();

        // Dans fetchRooms(), remplacer la section de gestion d'image par :
        String imagePath = '';
        String imageUrl = '';
        bool isDefaultImage = false;

        if (data['image'] is Map) {
          Map<String, dynamic> imageData = Map<String, dynamic>.from(data['image']);
          imagePath = imageData['path'] ?? '';
          imageUrl = imageData['url'] ?? '';
          isDefaultImage = imageData['isDefault'] ?? false;
        } else if (data['image'] is String) {
          imagePath = data['image'];
          imageUrl = data['imageUrl'] ?? '';
          isDefaultImage = false;
        }

// Si aucune image n'est disponible, utiliser l'image par défaut
        if (imagePath.isEmpty && imageUrl.isEmpty) {
          imagePath = 'assets/images/default_room.jpg';
          isDefaultImage = true;
        }

        return Room(
          id: doc.id,
          number: data['number'], // On garde 'number' comme String pour l'affichage
          type: data['type'],
          status: data['status'],
          price: data['price'].toDouble(),
          capacity: data['capacity'],
          amenities: List<String>.from(data['amenities']),
          floor: data['floor'],
          image: imagePath,
          imageUrl: imageUrl,
          description: data['description'] ?? '',
          userId: data['userId'] ?? '',
          passage: data['passage'] ?? false,
          priceHour: data['pricehour'] ?? 0,
        );
      }).toList();

      // Tri en convertissant 'number' en entier (int) de manière sécurisée
      if (sortOrder == 'asc') {
        fetchedRooms.sort((a, b) {
          int aNumber = int.tryParse(a.number) ?? 0;  // Si non converti, mettre 0
          int bNumber = int.tryParse(b.number) ?? 0;  // Si non converti, mettre 0
          return aNumber.compareTo(bNumber);  // Tri croissant
        });
      } else {
        fetchedRooms.sort((a, b) {
          int aNumber = int.tryParse(a.number) ?? 0;  // Si non converti, mettre 0
          int bNumber = int.tryParse(b.number) ?? 0;  // Si non converti, mettre 0
          return bNumber.compareTo(aNumber);  // Tri décroissant
        });
      }

      setState(() {
        rooms = fetchedRooms;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de la récupération des chambres: $e');
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des chambres: $e')),
      );
    }
  }

  // Récupérer les réservations depuis Firebase
  Future<void> fetchBookings() async {
    if (userId == null) return;

    try {
      List<Booking> allBookings = [];

      // Récupérer les réservations depuis la collection 'bookings'
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['enregistré', 'hourly']).get();

      // Récupérer les réservations depuis la collection 'reservations'
      final reservationsSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['réservée', 'Enregistré']).get();

      // Récupérer les réservations horaires depuis 'bookingshours'
      final hourlyBookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookingshours')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'hourly')
          .get();

      // Transformer les documents 'bookings' en objets Booking
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        if (data['checkInDate'] != null && data['checkOutDate'] != null) {
          allBookings.add(Booking(
            id: doc.id,
            roomId: data['roomId'] ?? '',
            guestName: data['customerName'] ?? 'Client',
            checkIn: (data['checkInDate'] as Timestamp).toDate(),
            checkOut: (data['checkOutDate'] as Timestamp).toDate(),
            status: data['status'] ?? 'enregistré',
          ));
        }
      }

      // Transformer les documents 'reservations' en objets Booking
      for (var doc in reservationsSnapshot.docs) {
        final data = doc.data();
        if (data['checkInDate'] != null && data['checkOutDate'] != null) {
          allBookings.add(Booking(
            id: doc.id,
            roomId: data['roomId'] ?? '',
            guestName: data['customerName'] ?? 'Client',
            checkIn: (data['checkInDate'] as Timestamp).toDate(),
            checkOut: (data['checkOutDate'] as Timestamp).toDate(),
            status: data['status'] ?? 'réservée',
          ));
        }
      }

      // Transformer les documents 'bookingshours' en objets Booking
      for (var doc in hourlyBookingsSnapshot.docs) {
        final data = doc.data();
        if (data['checkInDate'] != null && data['checkOutDate'] != null) {
          allBookings.add(Booking(
            id: doc.id,
            roomId: data['roomId'] ?? '',
            guestName: data['customerName'] ?? 'Client',
            checkIn: (data['checkInDate'] as Timestamp).toDate(),
            checkOut: (data['checkOutDate'] as Timestamp).toDate(),
            status: data['status'] ?? 'hourly',
          ));
        }
      }

      setState(() {
        bookings = allBookings;
      });
    } catch (e) {
      print('Erreur lors de la récupération des réservations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des réservations: $e')),
      );
    }
  }



  void handleEditRoom(String id) {
    final roomToEdit = rooms.firstWhere((room) => room.id == id);
    _showEditRoomBottomSheet(roomToEdit);
  }

  Future<void> handleDeleteRoom(String id) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette chambre ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmDelete) {
      try {
        await FirebaseFirestore.instance.collection('rooms').doc(id).delete();
        fetchRooms(); // Rafraîchir la liste
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chambre supprimée avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  List<Room> get filteredRooms {
    List<Room> filtered = rooms.where((room) {
      final matchesSearch =
      room.number.toLowerCase().contains(searchTerm.toLowerCase());
      final matchesStatus = filterStatus == 'tout' || room.status == filterStatus;
      final matchesType = filterType == 'tout' || room.type == filterType;
      return matchesSearch && matchesStatus && matchesType;
    }).toList();

    // Tri local par numéro, avec conversion en entier pour un tri correct
    filtered.sort((a, b) {
      // Vérifier si 'number' peut être converti en entier
      int aNumber = int.tryParse(a.number) ?? 0;  // Si non, attribuer la valeur 0
      int bNumber = int.tryParse(b.number) ?? 0;  // Si non, attribuer la valeur 0

      return aNumber.compareTo(bNumber);  // Tri par 'number' en tant qu'entiers
    });

    return filtered;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: LayoutBuilder(
          builder: (context, constraints) {
            // Si l'écran est plus petit (ex : téléphones)
            if (constraints.maxWidth < 600) {
              return Row(
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.layoutGrid,
                        color: view == 'grid' ? Colors.black87 : Colors.grey),
                    onPressed: () {
                      setState(() => view = 'grid');
                      _onViewChanged('grid');
                    },
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.calendar,
                        color: view == 'calendar' ? Colors.black87 : Colors.grey),
                    onPressed: () {
                      setState(() => view = 'calendar');
                      _onViewChanged('calendar');
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Rechercher des chambres...",
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
                  ),
                  IconButton(
                    onPressed: () async {
                      if (userId == null || userId!.isEmpty) {
                        print('Utilisateur non connecté');
                        return;
                      }

                      try {
                        print('Vérification de la limite pour l\'utilisateur: $userId');
                        Map<String, dynamic> result = await checkRoomCreationLimit(userId!);

                        if (result["canCreate"]) {
                          _showAddRoomBottomSheet();
                        } else {
                          // Si une erreur s'est produite lors de la vérification
                          if (result.containsKey("error")) {
                            throw Exception(result["error"]);
                          }

                          int roomCount = result["roomCount"];
                          int limit = result["limit"];

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Vous avez atteint votre limite de chambres ($roomCount/$limit). Veuillez mettre à niveau votre abonnement.'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 5),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Erreur lors de la vérification de la limite: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur lors de la vérification de votre limite. Veuillez réessayer.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(LucideIcons.plus, color: Colors.green),
                  ),
                ],
              );
            }

            // Si l'écran est plus grand (ex : tablettes et desktop)
            return Row(
              children: [
                IconButton(
                  icon: Icon(LucideIcons.layoutGrid,
                      color: view == 'grid' ? Colors.black87 : Colors.grey),
                  onPressed: () {
                    setState(() => view = 'grid');
                    _onViewChanged('grid');
                  },
                ),
                IconButton(
                  icon: Icon(LucideIcons.calendar,
                      color: view == 'calendar' ? Colors.black87 : Colors.grey),
                  onPressed: () {
                    setState(() => view = 'calendar');
                    _onViewChanged('calendar');
                  },
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Rechercher des chambres...",
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
                    DropdownMenuItem(value: 'tout', child: Text("Tous les statuts")),
                    DropdownMenuItem(value: 'disponible', child: Text("Disponible")),
                    DropdownMenuItem(value: 'occupée', child: Text("Occupée")),
                    DropdownMenuItem(value: 'réservée', child: Text("Réservée")),
                    DropdownMenuItem(value: 'maintenance', child: Text("En maintenance")),
                  ],
                  onChanged: (value) => setState(() => filterStatus = value!),
                ),
                SizedBox(width: 12),
                FutureBuilder<Map<String, dynamic>>(
                  future: HotelSettingsService().getHotelSettings(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Erreur: ${snapshot.error}');
                    } else {
                      final roomTypes = List<String>.from(snapshot.data?['roomTypes'] ?? []);

                      // Ajouter l'option "Tous les types"
                      final items = <DropdownMenuItem<String>>[
                        DropdownMenuItem(value: 'tout', child: Text("Tous les types")),
                        ...roomTypes.map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                      ];

                      // Vérifier si filterType est initialisé avec une valeur qui existe
                      if (filterType != null && !items.map((item) => item.value).contains(filterType)) {
                        filterType = 'tout'; // Réinitialiser filterType à "tout" si la valeur n'existe pas
                      }

                      return DropdownButton<String>(
                        value: filterType,
                        items: items,
                        onChanged: (value) => setState(() => filterType = value!),
                      );
                    }
                  },
                ),
                SizedBox(width: 12),
                DropdownButton<String>(
                  value: sortOrder,
                  items: [
                    DropdownMenuItem(value: 'asc', child: Text("Numéro croissant")),
                    DropdownMenuItem(value: 'desc', child: Text("Numéro décroissant")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      sortOrder = value!;
                      fetchRooms(); // Recharger les chambres avec le nouveau tri
                    });
                  },
                ),
                SizedBox(width: 12),
                IconButton(
                  onPressed: () async {
                    if (userId == null || userId!.isEmpty) {
                      print('Utilisateur non connecté');
                      return;
                    }

                    try {
                      print('Vérification de la limite pour l\'utilisateur: $userId');
                      Map<String, dynamic> result = await checkRoomCreationLimit(userId!);

                      if (result["canCreate"]) {
                        _showAddRoomBottomSheet();
                      } else {
                        // Si une erreur s'est produite lors de la vérification
                        if (result.containsKey("error")) {
                          throw Exception(result["error"]);
                        }

                        int roomCount = result["roomCount"];
                        int limit = result["limit"];

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Vous avez atteint votre limite de chambres ($roomCount/$limit). Veuillez mettre à niveau votre abonnement.'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 5),
                          ),
                        );
                      }
                    } catch (e) {
                      print('Erreur lors de la vérification de la limite: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la vérification de votre limite. Veuillez réessayer.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: Icon(LucideIcons.plus, color: Colors.green),
                ),
              ],
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchRooms,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final screenWidth = constraints.maxWidth;
            int crossAxisCount = 4;

            if (screenWidth < 600) {
              crossAxisCount = 1;
            } else if (screenWidth < 900) {
              crossAxisCount = 2;
            } else if (screenWidth < 1300) {
              crossAxisCount = 3;
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
                        ? filteredRooms.isEmpty
                        ? Center(
                      child: Text(
                        "Aucune chambre trouvée avec ces critères",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                        : GridView.builder(
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
                      bookings: bookings,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


