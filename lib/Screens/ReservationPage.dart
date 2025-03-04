import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../config/generationcode.dart';

class ReservationPage extends StatefulWidget {
  @override
  _ModernReservationPageState createState() => _ModernReservationPageState();
}

class _ModernReservationPageState extends State<ReservationPage> {
  final TextEditingController _searchController = TextEditingController();
  Reservation? _foundReservation;
  bool _isSearching = false;
  String? _errorMessage;

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
      // Fetch available rooms, sorted by room number in ascending order
      final snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('status', isEqualTo: 'disponible')
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

        // Additional sorting to ensure correct order for string-based room numbers
        availableRooms.sort((a, b) => _compareRoomNumbers(a.number, b.number));

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
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        reservationsList = snapshot.docs.map((doc) {
          final data = doc.data();
          return Reservation(
            id: doc.id,
            customerName: data['customerName'],
            roomNumber: data['roomNumber'],
            roomType: data['roomType'],
            checkInDate: (data['checkInDate'] as Timestamp).toDate(),
            checkOutDate: (data['checkOutDate'] as Timestamp).toDate(),
            status: data['status'],
            roomId: data['roomId'],
            reservationCode: data['reservationCode'],
            customerEmail: data['customerEmail'], // Ajout de l'email du client
            customerPhone: data['customerPhone'], // Ajout du téléphone du client
            numberOfGuests: data['numberOfGuests'], // Ajout du nombre de clients
            specialRequests: data['specialRequests'], // Ajout des demandes spéciales
          );
        }).toList();
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des réservations');
    }
  }

  int _compareRoomNumbers(String a, String b) {
    // First, try to parse as integers if possible
    final intA = int.tryParse(a);
    final intB = int.tryParse(b);

    if (intA != null && intB != null) {
      return intA.compareTo(intB);
    }

    // If parsing fails, do a string comparison
    return a.compareTo(b);
  }

  Future<void> makeReservation() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save(); // Sauvegarde les valeurs du formulaire

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

      final batch = FirebaseFirestore.instance.batch(); // Utilisation d'un batch write
      String generatedReservationCode = await CodeGenerator.generateReservationCode();
      // Mise à jour de la chambre
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(selectedRoom!.id);
      batch.update(roomRef, {'status': 'réservée'});

      // Création de la réservation
      final reservationRef = FirebaseFirestore.instance.collection('reservations').doc();
      batch.set(reservationRef, {
        'userId': userId,
        'roomId': selectedRoom!.id,
        'roomNumber': selectedRoom!.number, // Utilisation de ! au lieu de ?
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'numberOfGuests': numberOfGuests,
        'specialRequests': specialRequests,
        'checkInDate': checkInDate,
        'checkOutDate': checkOutDate,
        'reservationCode': generatedReservationCode,
        'status': 'réservée',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit(); // Commit atomique des deux opérations

      _showSuccessSnackBar('Réservation effectuée avec succès');


      // Rafraîchir les listes avec gestion d'erreur
      try {
        await fetchAvailableRooms();
        await fetchReservations();
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Réservation réussie mais erreur de rafraîchissement');
        }
      }

      // Réinitialisation plus sûre
      if (mounted) {
        _formKey.currentState?.reset();
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
      }
    } catch (e) {
      debugPrint('Erreur de réservation: $e');
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la réservation');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showConfirmationSheet(BuildContext context, Reservation reservation) async {
    // Récupérer les informations de la chambre
    DocumentSnapshot roomSnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(reservation.roomId)
        .get();
    Map<String, dynamic> roomData = roomSnapshot.data() as Map<String, dynamic>;
    List<String> amenities = List<String>.from(roomData['amenities'] ?? []);
    String generatedRegistrationCode = await CodeGenerator.generateRegistrationCode();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String fullName = '';
        String idNumber = '';
        String nationality = '';
        String address = '';
        String phoneNumber = '';
        String email = '';
        int numberOfGuests = 1;
        DateTime? arrivalTime;
        String? paymentMethod;
        double deposit = 0.0;
        String companyBilling = '';
        String specialRequests = '';
        bool termsAccepted = false;

        // Calcul du nombre de jours
        int numberOfDays = reservation.checkOutDate.difference(reservation.checkInDate).inDays;

        // Calcul du montant à payer
        double totalPrice = (roomData['price'] ?? 0.0) * numberOfDays;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Informations de réservation",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),

                    // Informations de la chambre
                    Text("Informations de la chambre", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Numéro de chambre: ${reservation.roomNumber}"),
                    Text("Type de chambre: ${roomData['type']}"),
                    Text("Commodités: ${amenities.join(', ')}"),
                    SizedBox(height: 20),

                    // Informations de la réservation
                    Text("Informations de la réservation", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Nom du client: ${reservation.customerName}"),
                    Text("Date d'arrivée: ${DateFormat('dd/MM/yyyy').format(reservation.checkInDate)}"),
                    Text("Date de départ: ${DateFormat('dd/MM/yyyy').format(reservation.checkOutDate)}"),
                    SizedBox(height: 20),

                    // 1. Informations personnelles du client
                    TextField(
                      decoration: InputDecoration(labelText: "Nom complet", border: OutlineInputBorder()),
                      onChanged: (value) => fullName = value,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: "Numéro de pièce d'identité/passeport", border: OutlineInputBorder()),
                      onChanged: (value) => idNumber = value,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: "Nationalité", border: OutlineInputBorder()),
                      onChanged: (value) => nationality = value,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: "Adresse", border: OutlineInputBorder()),
                      onChanged: (value) => address = value,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: "Numéro de téléphone", border: OutlineInputBorder()),
                      onChanged: (value) => phoneNumber = value,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: "Adresse email", border: OutlineInputBorder()),
                      onChanged: (value) => email = value,
                    ),
                    SizedBox(height: 20),

                    // 2. Détails de la réservation
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(labelText: "Nombre d'occupants", border: OutlineInputBorder()),
                      value: numberOfGuests,
                      items: List.generate(10, (index) => index + 1)
                          .map((number) => DropdownMenuItem(value: number, child: Text('$number'))).toList(),
                      onChanged: (value) => numberOfGuests = value!,
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      title: Text("Heure d'arrivée"),
                      trailing: Text(arrivalTime != null ? DateFormat('HH:mm').format(arrivalTime!) : 'Sélectionner'),
                      onTap: () async {
                        final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (time != null) {
                          setState(() => arrivalTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, time.hour, time.minute));
                        }
                      },
                    ),

                    // 3. Informations de paiement
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Mode de paiement", border: OutlineInputBorder()),
                      value: paymentMethod,
                      items: ['Carte bancaire', 'Espèces', 'Virement', 'Mobile Money']
                          .map((method) => DropdownMenuItem(value: method, child: Text(method))).toList(),
                      onChanged: (value) => paymentMethod = value,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: "Dépôt de garantie (si requis)", border: OutlineInputBorder()),
                      onChanged: (value) => deposit = double.tryParse(value) ?? 0.0,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: "Facturation entreprise (si applicable)", border: OutlineInputBorder()),
                      onChanged: (value) => companyBilling = value,
                    ),
                    SizedBox(height: 20),

                    // Affichage du montant à payer
                    Text("Montant à payer: ${totalPrice.toStringAsFixed(2)} FCFA"),
                    SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(labelText: "Demandes spéciales", border: OutlineInputBorder()),
                      onChanged: (value) => specialRequests = value,
                      maxLines: 3,
                    ),
                    SizedBox(height: 20),

                    // 5. Signature et confirmation
                    CheckboxListTile(
                      title: Text("J'accepte les conditions générales"),
                      value: termsAccepted,
                      onChanged: (value) => setState(() => termsAccepted = value!),
                    ),
                    SizedBox(height: 20),

                    // Bouton de confirmation
                    Center(
                      child: ElevatedButton(
                        onPressed: termsAccepted && paymentMethod != null
                            ? () {
                          // Enregistrez toutes les informations dans Firebase
                          FirebaseFirestore.instance
                              .collection('reservations')
                              .doc(reservation.id)
                              .update({
                            'codeEnregistrement':generatedRegistrationCode ,
                            'fullName': fullName,
                            'idNumber': idNumber,
                            'nationality': nationality,
                            'address': address,
                            'phoneNumber': phoneNumber,
                            'email': email,
                            'numberOfGuests': numberOfGuests,
                            'arrivalTime': arrivalTime,
                            'paymentMethod': paymentMethod,
                            'deposit': deposit,
                            'companyBilling': companyBilling,
                            'specialRequests': specialRequests,
                            'status': 'Confirmée',
                          }).then((_) {
                            _confirmReservation(reservation);
                            Navigator.pop(context);
                            _showSuccessSnackBar('Réservation confirmée avec succès');
                            fetchReservations();
                          });
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        child: Text("Confirmer"),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  void _confirmReservation(Reservation reservation) {
    FirebaseFirestore.instance
        .collection('reservations')
        .doc(reservation.id)
        .update({'status': 'Confirmée'}).then((_) {
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(reservation.roomId)
          .update({'status': 'occupée'});

      setState(() {
        reservation.status = 'Confirmée';
      });


    });
  }

  void _cancelReservation(Reservation reservation) {
    FirebaseFirestore.instance
        .collection('reservations')
        .doc(reservation.id)
        .update({'status': 'Annulée'}).then((_) {
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(reservation.roomId)
          .update({'status': 'disponible'});

      setState(() {
        reservation.status = 'Annulée';
      });
    });
  }

  // Méthode de recherche améliorée
  void _searchReservation() async {
    final searchCode = _searchController.text.trim();
    if (searchCode.isEmpty) {
      _updateSearchState(error: 'Veuillez entrer un code de réservation');
      return;
    }

    _updateSearchState(reset: true);

    try {
      // Recherche par le champ reservationCode
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('reservationCode', isEqualTo: 'RES'+searchCode) // Recherche par champ
          .get();

      // Vérifier si des résultats ont été trouvés
      if (querySnapshot.docs.isEmpty) {
        _updateSearchState(error: 'Aucune réservation trouvée avec ce code');
        return;
      }

      // Récupérer le premier document trouvé
      final doc = querySnapshot.docs.first;
      final data = doc.data();

      // Récupérer les détails de la chambre associée
      final room = await _fetchRoomDetails(data['roomId']);

      // Mettre à jour l'état avec les détails de la réservation
      _updateSearchState(
        reservation: Reservation(
          id: doc.id,
          reservationCode: data['reservationCode'],
          customerName: data['customerName'],
          roomNumber: room?['number']?.toString() ?? 'Inconnu',
          roomType: room?['type']?.toString(), // Récupérer le type de chambre
          checkInDate: _parseDate(data['checkInDate']),
          checkOutDate: _parseDate(data['checkOutDate']),
          status: data['status'],
          roomId: data['roomId'],
          customerEmail: data['customerEmail'], // Récupération correcte
          customerPhone: data['customerPhone'], // Récupération correcte
          numberOfGuests: data['numberOfGuests'], // Récupération correcte
          specialRequests: data['specialRequests'], // Récupération correcte
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors de la recherche: $e');
      _updateSearchState(error: 'Erreur lors de la recherche de la réservation');
    }
  }

// Nouvelle méthode pour gérer l'état de la recherche
  void _updateSearchState({
    bool reset = false,
    Reservation? reservation,
    String? error,
  }) {
    if (!mounted) return;

    setState(() {
      if (reset) {
        _foundReservation = null;
        _errorMessage = null;
      }
      if (reservation != null) _foundReservation = reservation;
      if (error != null) _errorMessage = error;
      _isSearching = false;
    });
  }

// Helper method pour récupérer les détails de la chambre
  Future<Map<String, dynamic>?> _fetchRoomDetails(String roomId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get();
      return snapshot.data();
    } catch (e) {
      debugPrint('Erreur récupération chambre: $e');
      return null;
    }
  }

// Gestion des erreurs améliorée
  String _handleSearchError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied'
          ? 'Accès refusé'
          : 'Erreur serveur';
    }
    return 'Erreur lors de la recherche';
  }

// Affichage amélioré des résultats
  Widget _buildSearchReservation() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 3,
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchHeader(),
          const SizedBox(height: 16),
          _buildSearchInput(),
          if (_isSearching) _buildLoadingIndicator(),
          if (_errorMessage != null) _buildErrorDisplay(),
          if (_foundReservation != null) _buildReservationDetails(),
        ],
      ),
    );
  }
  // Ajout des fonctions pour les boutons

  Widget _buildSearchHeader() {
    return Row(
      children: [
        const Icon(Icons.search, size: 28),
        const SizedBox(width: 12),
        Text(
          'Recherche de réservation',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInput() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Code de réservation (ex: 000123)',
        prefixIcon: const Icon(Icons.confirmation_number),
        suffixIcon: _buildSearchActions(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _searchReservation(),
    );
  }

  Widget _buildSearchActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              _searchController.clear();
              _updateSearchState(reset: true);
            },
          ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.search, size: 20),
          label: const Text('Rechercher'),
          onPressed: _isSearching ? null : _searchReservation,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
  DateTime _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is DateTime) {
      return date;
    } else if (date is String) {
      return DateTime.parse(date);
    }
    throw FormatException('Format de date non supporté: $date');
  }
  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ),
    );
  }
  Widget _buildErrorDisplay() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        _errorMessage!,
        style: TextStyle(
          color: Colors.red,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blueGrey[800],
        ),
      ),
    );
  }

  void _canceleReservation() {
    if (_foundReservation != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmer l\'annulation'),
            content: const Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('reservations')
                        .doc(_foundReservation!.id)
                        .update({'status': 'Annulée'});

                    await FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(_foundReservation!.roomId)
                        .update({'status': 'disponible'});

                    setState(() {
                      _foundReservation!.status = 'Annulée';
                    });

                    Navigator.pop(context);
                    _showSuccessSnackBar('Réservation annulée avec succès.');
                    fetchReservations();
                  } catch (e) {
                    Navigator.pop(context);
                    _showErrorSnackBar('Erreur lors de l\'annulation de la réservation: $e');
                    debugPrint('Erreur lors de l\'annulation de la réservation: $e');
                  }
                },
                child: const Text('Confirmer'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showModifyReservationSheet(BuildContext context, Reservation reservation) {
    // Initialiser les variables avec les données de la réservation existante
    customerName = reservation.customerName;
    customerEmail = reservation.customerEmail ?? ''; // Récupérer l'email si disponible
    customerPhone = reservation.customerPhone ?? ''; // Récupérer le téléphone si disponible
    numberOfGuests = reservation.numberOfGuests ?? 1; // Récupérer le nombre de clients si disponible
    specialRequests = reservation.specialRequests ?? ''; // Récupérer les demandes spéciales si disponibles
    checkInDate = reservation.checkInDate;
    checkOutDate = reservation.checkOutDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Modifier la réservation",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),

                    // Champs de modification
                    TextField(
                      decoration: InputDecoration(labelText: "Nom du client", border: OutlineInputBorder()),
                      controller: TextEditingController(text: customerName),
                      onChanged: (value) => customerName = value,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: "Email du client", border: OutlineInputBorder()),
                      controller: TextEditingController(text: customerEmail),
                      onChanged: (value) => customerEmail = value,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: "Téléphone du client", border: OutlineInputBorder()),
                      controller: TextEditingController(text: customerPhone),
                      onChanged: (value) => customerPhone = value,
                    ),
                    SizedBox(height: 10),
                    // Ajouter d'autres champs de modification (nombre de clients, demandes spéciales, etc.)

                    // Sélection des dates
                    ListTile(
                      title: Text("Date d'arrivée"),
                      trailing: Text(DateFormat('dd/MM/yyyy').format(checkInDate!)),
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: checkInDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                        if (date != null) {
                          setState(() => checkInDate = date);
                        }
                      },
                    ),
                    ListTile(
                      title: Text("Date de départ"),
                      trailing: Text(DateFormat('dd/MM/yyyy').format(checkOutDate!)),
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: checkOutDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                        if (date != null) {
                          setState(() => checkOutDate = date);
                        }
                      },
                    ),

                    SizedBox(height: 20),

                    // Bouton de sauvegarde
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          _modifyReservation(reservation.id); // Appel de la fonction de modification
                          Navigator.pop(context); // Fermer le BottomSheet
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        child: Text("Sauvegarder"),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Fonction pour modifier une réservation (à implémenter)
  Future<void> _modifyReservation(String reservationId) async {
    try {
      final reservationRef = FirebaseFirestore.instance.collection('reservations').doc(reservationId);

      await reservationRef.update({
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'checkInDate': checkInDate,
        'checkOutDate': checkOutDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Réservation modifiée avec succès.');
      fetchReservations();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la modification de la réservation: $e');
      debugPrint('Erreur lors de la modification de la réservation: $e');
    }
  }



  Widget _buildReservationDetails() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 0,
        color: Colors.grey[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Détails de la réservation'),
                  _buildStatusBadge(), // Statut en haut à droite
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoTile(Icons.person, 'Client', _foundReservation!.customerName),
              _buildInfoTile(Icons.meeting_room, 'Chambre',
                  'N°${_foundReservation!.roomNumber} (${_foundReservation!.roomType ?? 'Type inconnu'})'),
              _buildDateRange(),
              const SizedBox(height: 16),
              if (_foundReservation!.status != 'Annulée' &&
                  _foundReservation!.status != 'Confirmée')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end, // Alignement à droite
                  children: [
                    IconButton(
                      onPressed: () => _showConfirmationSheet(context, _foundReservation!),
                      style: IconButton.styleFrom(backgroundColor: Colors.green),
                      icon: const Icon(Icons.check),
                    ),
                    IconButton(
                      onPressed: () => _canceleReservation(),
                      style: IconButton.styleFrom(backgroundColor: Colors.red),
                      icon: const Icon(Icons.cancel),
                    ),
                    IconButton(
                      onPressed: () =>_showModifyReservationSheet(context, _foundReservation!),
                      style: IconButton.styleFrom(backgroundColor: Colors.blue),
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: Colors.blueGrey[600]),
      title: Row(
        children: [
          Text('$label : ', style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDateRange() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildDateChip('Arrivée', _foundReservation!.checkInDate),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          ),
          _buildDateChip('Départ', _foundReservation!.checkOutDate),
        ],
      ),
    );
  }

  Widget _buildDateChip(String label, DateTime date) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: _getStatusColor(_foundReservation!.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusColor(_foundReservation!.status),
              width: 1.5,
            ),
          ),
          child: Text(
            _foundReservation!.status.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(_foundReservation!.status),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
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
                      Text(
                        'Choisir une chambre',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      _buildRoomSelection(),
                      SizedBox(height: 20),
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
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[100],
              child: Column(
                children: [
                  _buildSearchReservation(),
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
                                Text('Code: ${reservation.reservationCode}', style: TextStyle(fontSize: 12)), // Ajout du code de réservation
                                Text('Chambre: ${reservation.roomNumber}', style: TextStyle(fontSize: 12)),
                                Text(
                                  '${DateFormat('dd/MM/yyyy').format(reservation.checkInDate)} - ${DateFormat('dd/MM/yyyy').format(reservation.checkOutDate)}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Container( // Suppression de la logique des boutons
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
      case 'Confirmée':
        return Colors.green;
      case 'Annulée':
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
  final String? roomType;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  late String status;
  final String roomId;
  final String reservationCode; // Assurez-vous qu'il n'y a pas 'late' ici
  final String? customerEmail;
  final String? customerPhone;
  final int? numberOfGuests;
  final String? specialRequests;

  Reservation({
    required this.id,
    required this.customerName,
    required this.roomNumber,
    this.roomType,
    required this.checkInDate,
    required this.checkOutDate,
    required this.status,
    required this.roomId,
    required this.reservationCode,
    this.customerEmail,
    this.customerPhone,
    this.numberOfGuests,
    this.specialRequests,
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
