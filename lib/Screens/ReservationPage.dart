import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReservationPage extends StatefulWidget {
  @override
  _ModernReservationPageState createState() => _ModernReservationPageState();
}

class _ModernReservationPageState extends State<ReservationPage> {
  List<Room> availableRooms = [];
  Room? selectedRoom;
  String customerName = '';
  String customerEmail = '';
  String customerPhone = '';
  int numberOfGuests = 1;
  String specialRequests = '';
  DateTime? checkInDate;
  DateTime? checkOutDate;
  bool isLoading = true;
  final _formKey = GlobalKey<FormState>();

  List<Reservation> reservationsList = [];

  @override
  void initState() {
    super.initState();
    fetchAvailableRooms();
    fetchReservations();
  }

  Future<void> fetchAvailableRooms() async {
    try {
      // Récupérer les chambres disponibles, triées par numéro
      final snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('status', isEqualTo: 'disponible')
           // Trier par numéro de chambre en ordre croissant
          .get();

      setState(() {
        availableRooms = snapshot.docs.map((doc) {
          final data = doc.data();
          return Room(
            id: doc.id,
            number: data['number'],
            type: data['type'],
            status: data['status'],
            price: data['price'].toDouble(),
            capacity: data['capacity'],
            amenities: List<String>.from(data['amenities']),
            floor: data['floor'],
            image: data['image'],
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement des chambres disponibles');
    }
  }

// Widget pour la sélection des chambres avec défilement
  Widget _buildRoomSelection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Bouton pour voir toutes les chambres
          GestureDetector(
            onTap: () {
              _showAllRoomsBottomSheet();
            },
            child: Container(
              width: 100,
              height: 150,
              margin: EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list, color: Colors.blue, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'Toutes les\nchambres',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
          // Liste des chambres disponibles
          ...availableRooms.map((room) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedRoom = room;
                });
              },
              child: RoomCard(
                room: room,
                isSelected: selectedRoom == room,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

// Méthode pour afficher toutes les chambres dans un bottom sheet
  void _showAllRoomsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Toutes les Chambres Disponibles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: availableRooms.length,
                      itemBuilder: (context, index) {
                        final room = availableRooms[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              room.image,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.hotel, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          title: Text(
                            'Chambre ${room.number}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${room.type} - ${room.capacity} personnes',
                          ),
                          trailing: Text(
                            '${room.price.toStringAsFixed(2)} FCFA/nuit',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              selectedRoom = room;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> fetchReservations() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .orderBy('checkInDate', descending: true)
          .get();

      setState(() {
        reservationsList = snapshot.docs.map((doc) {
          final data = doc.data();
          return Reservation(
            id: doc.id,
            customerName: data['customerName'],
            roomNumber: data['roomNumber'], // Vous devrez peut-être récupérer le numéro de chambre
            checkInDate: (data['checkInDate'] as Timestamp).toDate(),
            checkOutDate: (data['checkOutDate'] as Timestamp).toDate(),
            status: data['status'],
          );
        }).toList();
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des réservations');
    }
  }

  Future<void> makeReservation() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedRoom == null || checkInDate == null || checkOutDate == null) {
      _showErrorSnackBar('Veuillez remplir tous les champs obligatoires');
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _showErrorSnackBar('Utilisateur non authentifié');
        return;
      }

      // Mise à jour de la chambre
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(selectedRoom!.id)
          .update({
        'status': 'réservée',
      });

      // Ajouter la réservation
      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': userId,
        'roomId': selectedRoom!.id,
        'roomNumber': selectedRoom?.number,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'numberOfGuests': numberOfGuests,
        'specialRequests': specialRequests,
        'checkInDate': checkInDate,
        'checkOutDate': checkOutDate,
        'status': 'réservée',
      });

      _showSuccessSnackBar('Réservation effectuée avec succès');

      // Rafraîchir les listes
      fetchAvailableRooms();
      fetchReservations();

      // Réinitialiser le formulaire
      _formKey.currentState!.reset();
      setState(() {
        selectedRoom = null;
        checkInDate = null;
        checkOutDate = null;
        customerName = '';
        customerEmail = '';
        customerPhone = '';
        numberOfGuests = 1;
        specialRequests = '';
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la réservation');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showConfirmationSheet(BuildContext context, Reservation reservation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Confirmer la réservation",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: "Remarque (optionnel)",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _confirmReservation(reservation);
                  Navigator.pop(context);
                },
                child: Text("Confirmer"),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _confirmReservation(Reservation reservation) {
    FirebaseFirestore.instance
        .collection('reservations')
        .doc(reservation.id)
        .update({'status': 'Confirmée'});
    setState(() {
      reservation.status = 'Confirmée';
    });
  }

  void _cancelReservation(Reservation reservation) {
    FirebaseFirestore.instance
        .collection('reservations')
        .doc(reservation.id)
        .update({'status': 'Annulée'});
    setState(() {
      reservation.status = 'Annulée';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Réservations'),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // Partie Réservation (2/3)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouvelle Réservation',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 20),

                      // Sélection de chambre
                      Text(
                        'Choisir une chambre',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      _buildRoomSelection(),

                      SizedBox(height: 20),

                      // Informations du client
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Nom complet',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un nom';
                          }
                          return null;
                        },
                        onChanged: (value) => customerName = value,
                      ),
                      SizedBox(height: 15),

                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un email';
                          }
                          // Validation d'email simple
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Veuillez entrer un email valide';
                          }
                          return null;
                        },
                        onChanged: (value) => customerEmail = value,
                      ),
                      SizedBox(height: 15),

                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Téléphone',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un numéro de téléphone';
                          }
                          return null;
                        },
                        onChanged: (value) => customerPhone = value,
                      ),
                      SizedBox(height: 15),

                      // Nombre de personnes
                      Row(
                        children: [
                          Text('Nombre de personnes:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(width: 10),
                          DropdownButton<int>(
                            value: numberOfGuests,
                            items: List.generate(10, (index) => index + 1)
                                .map((number) => DropdownMenuItem(
                              value: number,
                              child: Text('$number'),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                numberOfGuests = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 15),

                      // Dates
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePickerCard(
                              context,
                              title: 'Date d\'arrivée',
                              date: checkInDate,
                              onDateSelected: (selectedDate) {
                                setState(() {
                                  checkInDate = selectedDate;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _buildDatePickerCard(
                              context,
                              title: 'Date de départ',
                              date: checkOutDate,
                              onDateSelected: (selectedDate) {
                                setState(() {
                                  checkOutDate = selectedDate;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),

                      // Demandes spéciales
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Demandes spéciales',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (value) => specialRequests = value,
                      ),
                      SizedBox(height: 20),

                      // Bouton de réservation
                      Center(
                        child: ElevatedButton(
                          onPressed: makeReservation,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                          ),
                          child: Text('Confirmer la Réservation'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),


          // Partie Liste des Réservations (1/3)
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[100],
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Réservations Récentes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: reservationsList.length,
                      itemBuilder: (context, index) {
                        final reservation = reservationsList[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(
                              reservation.customerName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Chambre: ${reservation.roomNumber}', style: TextStyle(fontSize: 12)),
                                Text(
                                  '${DateFormat('dd/MM/yyyy').format(reservation.checkInDate)} - ${DateFormat('dd/MM/yyyy').format(reservation.checkOutDate)}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: reservation.status == "En attente"
                                ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () => _showConfirmationSheet(context, reservation),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _cancelReservation(reservation),
                                ),
                              ],
                            )
                                : Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(reservation.status),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                reservation.status,
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode de date picker
  Widget _buildDatePickerCard(
      BuildContext context, {
        required String title,
        required DateTime? date,
        required Function(DateTime) onDateSelected,
      }) {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : 'Sélectionner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour obtenir la couleur du statut
  Color _getStatusColor(String status) {
    switch (status) {
      case 'réservée':
        return Colors.blue;
      case 'confirmée':
        return Colors.green;
      case 'annulée':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Classes supplémentaires pour compléter l'implémentation

class Reservation {
  final String id;
  final String customerName;
  final String roomNumber;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  late final String status;

  Reservation({
    required this.id,
    required this.customerName,
    required this.roomNumber,
    required this.checkInDate,
    required this.checkOutDate,
    required this.status,
  });
}

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
  });
}

// Widget pour la carte de chambre
class RoomCard extends StatelessWidget {
  final Room room;
  final bool isSelected;

  const RoomCard({
    Key? key,
    required this.room,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              room.image,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Icon(
                      Icons.hotel,
                      size: 50,
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chambre ${room.number}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '${room.type} - ${room.capacity} personnes',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${room.price.toStringAsFixed(2)} FCFA/nuit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// Room class remains the same as in the original code
