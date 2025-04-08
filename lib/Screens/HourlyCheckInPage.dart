import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../components/checkin/CustomerInfoSection.dart';
import '../components/checkin/PaiementInfoSection.dart';
import '../config/HotelSettingsService.dart';
import '../config/HourlyReceiptPrinter.dart';
import '../config/generationcode.dart';
import '../config/room_models.dart';
import '../widgets/side_menu.dart';

class HourlyCheckInPage extends StatefulWidget {
  @override
  _HourlyCheckInPageState createState() => _HourlyCheckInPageState();
}

class _HourlyCheckInPageState extends State<HourlyCheckInPage> {
  final _formKey = GlobalKey<FormState>();

  // Informations client
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _addressController = TextEditingController();

  // Informations séjour
  final _checkInDateController = TextEditingController();
  final _checkInTimeController = TextEditingController();
  final _durationController = TextEditingController();
  int _numberOfGuests = 1;
  String? _selectedRoomType;
  int _selectedDurationHours = 1; // Durée par défaut en heures

  // Information paiement
  String? _selectedPaymentMethod;
  final List<String> _paymentMethods = ['Espèces', 'Mobile Money', 'Carte de Crédit'];

  bool _isLoading = false;
  List<String> _roomTypes = [];
  List<Room> _availableRooms = [];
  Room? _selectedRoom;

  DateTime? checkInDateTime;
  DateTime? checkOutDateTime;

  // Liste des durées disponibles
  final List<int> _availableDurations = [1, 2, 3, 4, 6, 12];

  @override
  void initState() {
    super.initState();

    // Initialiser avec la date et l'heure actuelles
    final now = DateTime.now();
    _checkInDateController.text = DateFormat('dd/MM/yyyy').format(now);
    _checkInTimeController.text = DateFormat('HH:mm').format(now);
    _durationController.text = '1 heure';

    checkInDateTime = now;
    checkOutDateTime = now.add(Duration(hours: 1));

    // Charger les chambres disponibles
    fetchAvailableRooms();
  }

  // Compare les numéros de chambre qui peuvent être de format différent
  int compareRoomNumbers(String a, String b) {
    // Essayer de convertir en entiers si possible
    try {
      int numA = int.parse(a);
      int numB = int.parse(b);
      return numA.compareTo(numB);
    } catch (e) {
      // Si la conversion échoue, comparer comme des chaînes
      return a.compareTo(b);
    }
  }

  // Récupérer les chambres disponibles
  Future<void> fetchAvailableRooms() async {
    setState(() => _isLoading = true);

    try {
      // Vérifier si les dates et heures sont sélectionnées
      if (checkInDateTime == null || checkOutDateTime == null) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Veuillez sélectionner l\'heure et la durée');
        return;
      }

      // Vérifier la validité des dates/heures
      if (checkOutDateTime!.isBefore(checkInDateTime!)) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('L\'heure de fin doit être après l\'heure de début');
        return;
      }

      // Obtenir l'ID de l'utilisateur connecté
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer les chambres de l'utilisateur qui ont l'attribut passage=true
      final snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('userId', isEqualTo: userId)
          .where('passage', isEqualTo: true)
          .get();

      // Transformer les documents en objets Room
      final allRooms = snapshot.docs.map((doc) {
        final data = doc.data();
        return Room(
          id: doc.id,
          number: data['number'],
          type: data['type'],
          status: data['status'],
          price: data['pricehour'].toDouble(),
          capacity: data['capacity'],
          amenities: List<String>.from(data['amenities']),
          floor: data['floor'],
          image: data['image'],
          userId: userId,
        );
      }).toList();

      // Filtrer les chambres disponibles pour les dates/heures sélectionnées
      List<Room> roomsAvailable = [];
      for (Room room in allRooms) {
        if (room.status == 'disponible') {
          bool isAvailable = await isRoomAvailableForHourly(
              room.id, checkInDateTime!, checkOutDateTime!);
          if (isAvailable) {
            roomsAvailable.add(room);
          }
        }
      }

      // Trier les chambres par numéro
      roomsAvailable.sort((a, b) => compareRoomNumbers(a.number, b.number));

      // Extraire les types de chambres uniques des chambres disponibles
      final types = roomsAvailable.map((room) => room.type).toSet().toList();

      setState(() {
        _availableRooms = roomsAvailable;
        _roomTypes = types;
        _isLoading = false;

        if (_availableRooms.isEmpty) {
          _showErrorSnackBar('Aucune chambre disponible pour cette période');
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(
          'Erreur lors du chargement des chambres: ${e.toString()}');
    }
  }

  // Méthode pour vérifier si une chambre est disponible pour les heures spécifiées
  Future<bool> isRoomAvailableForHourly(String roomId, DateTime checkIn, DateTime checkOut) async {
    // Vérifier les deux collections en parallèle pour de meilleures performances
    final reservationsFuture = FirebaseFirestore.instance
        .collection('reservations')
        .where('roomId', isEqualTo: roomId)
        .where('status', whereIn: ['réservée', 'Enregistré'])
        .get();

    final bookingsFuture = FirebaseFirestore.instance
        .collection('bookings')
        .where('roomId', isEqualTo: roomId)
        .where('status', whereIn: ['réservée', 'enregistré', 'hourly'])
        .get();

    // Attendre les deux requêtes
    final results = await Future.wait([reservationsFuture, bookingsFuture]);
    final reservationsSnapshot = results[0];
    final bookingsSnapshot = results[1];

    // Fonction pour vérifier les chevauchements dans une liste de documents
    bool hasOverlap(List<QueryDocumentSnapshot> docs) {
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;

        DateTime resCheckIn = (data['checkInDate'] as Timestamp).toDate();
        DateTime resCheckOut;

        // Vérifier si c'est un enregistrement horaire ou journalier
        if (data['isHourly'] == true && data['checkOutDate'] != null) {
          // Pour les enregistrements horaires, utiliser directement checkOutDate
          resCheckOut = (data['checkOutDate'] as Timestamp).toDate();
        } else {
          // Pour les enregistrements journaliers, utiliser la date complète
          resCheckOut = (data['checkOutDate'] as Timestamp).toDate();
        }

        // Vérification de chevauchement
        bool overlap = !(checkOut.isBefore(resCheckIn) || checkIn.isAfter(resCheckOut));

        if (overlap) {
          return true; // Il y a chevauchement
        }
      }
      return false;
    }

    // Vérifier les chevauchements dans les deux collections
    if (hasOverlap(reservationsSnapshot.docs) || hasOverlap(bookingsSnapshot.docs)) {
      return false; // La chambre n'est pas disponible
    }

    return true; // La chambre est disponible
  }

  // Filtrer les chambres selon le type sélectionné
  List<Room> _getFilteredRooms() {
    if (_selectedRoomType == null) return [];

    return _availableRooms.where((room) =>
    room.type == _selectedRoomType &&
        room.capacity >= _numberOfGuests
    ).toList();
  }

  Future<void> _registerHourlyGuest() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRoom == null) {
        _showErrorSnackBar('Veuillez sélectionner une chambre');
        return;
      }
      if (_selectedPaymentMethod == null) {
        _showErrorSnackBar('Veuillez sélectionner un mode de paiement');
        return;
      }

      setState(() => _isLoading = true);

      // Afficher le dialogue de chargement
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text('Enregistrement du client en cours...')
                ],
              ),
            );
          },
        );
      }

      try {
        // Obtenir l'ID de l'utilisateur connecté
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          throw Exception('Utilisateur non connecté');
        }

        // Récupérer les paramètres de l'hôtel
        final settingsService = HotelSettingsService();
        final settings = await settingsService.getHotelSettings();

        // Créer un nouveau document de réservation
        final bookingRef = FirebaseFirestore.instance.collection('bookingshours').doc();

        // Générer un code de réservation unique
        String generatedReservationCode = await CodeGenerator.generateRegistrationCode();

        // Calcul du montant total basé sur la durée
        final tarif = _selectedRoom!.price * _selectedDurationHours;

        // Enregistrer la réservation
        await bookingRef.set({
          'EnregistrementCode': generatedReservationCode,
          'customerName': _customerNameController.text,
          'customerEmail': _customerEmailController.text,
          'customerPhone': _customerPhoneController.text,
          'idNumber': _idNumberController.text,
          'nationality': _nationalityController.text,
          'address': _addressController.text,
          'roomId': _selectedRoom!.id,
          'roomNumber': _selectedRoom!.number,
          'roomType': _selectedRoom!.type,
          'roomPrice': _selectedRoom!.price,
          'checkInDate': Timestamp.fromDate(checkInDateTime!),
          'checkOutDate': Timestamp.fromDate(checkOutDateTime!),
          'numberOfGuests': _numberOfGuests,
          'hours': _selectedDurationHours,
          'totalAmount': tarif,
          'status': 'hourly',
          'createdAt': FieldValue.serverTimestamp(),
          'userId': userId,
          'depositPaid': false,
          'balanceDue': tarif,
          'depositAmount': 0,
          'depositPercentage': 0,
          'isHourly': true,
          'isWalkIn': true,
          'paymentStatus':'payé',
          'paymentMethod': _selectedPaymentMethod, // Ajouter le mode de paiement
        });

        // Mettre à jour le statut de la chambre
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(_selectedRoom!.id)
            .update({
          'status': 'occupée',
          'datedisponible': Timestamp.fromDate(checkOutDateTime!),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        //Création d'une transaction pour la réservation
        // Date du paiement
        final paymentDate = Timestamp.now();
        final transactionCode = await CodeGenerator.generateTransactionCode();
        // Créer la transaction pour le paiement

        await FirebaseFirestore.instance.collection('transactions').add({
          'transactionCode': transactionCode,
          'bookingId': bookingRef.id,
          'roomId': _selectedRoom!.id,
          'customerId': userId,
          'customerName': _customerNameController.text,
          'amount': tarif,
          'discountRate': 0,
          'discountAmount': 0,
          'date': paymentDate,
          'type': 'payment',
          'paymentMethod': _selectedPaymentMethod!, // Utiliser le mode de paiement sélectionné
          'description': 'Paiement du passage $generatedReservationCode',
          'createdAt': paymentDate,
          'createdBy': userId
        });


        // Fermer le dialogue de chargement avant d'afficher le SnackBar
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        _showSuccessSnackBar('Client enregistré avec succès pour une durée de $_selectedDurationHours ${_selectedDurationHours > 1 ? "heures" : "heure"}');

        // Imprimer le reçu automatiquement après l'enregistrement
        await HourlyReceiptPrinter.printHourlyReceipt(context, bookingRef.id,showPreview: false);

        _resetForm();
      } catch (e) {
        // Fermer le dialogue de chargement en cas d'erreur
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        _showErrorSnackBar('Erreur lors de l\'enregistrement: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();

    // Réinitialiser avec la date et l'heure actuelles
    final now = DateTime.now();

    setState(() {
      _customerNameController.clear();
      _customerEmailController.clear();
      _customerPhoneController.clear();
      _idNumberController.clear();
      _nationalityController.clear();
      _addressController.clear();
      _checkInDateController.text = DateFormat('dd/MM/yyyy').format(now);
      _checkInTimeController.text = DateFormat('HH:mm').format(now);
      _durationController.text = '1 heure';
      _numberOfGuests = 1;
      _selectedRoomType = null;
      _selectedRoom = null;
      _selectedDurationHours = 1;
      _selectedPaymentMethod = null; // Réinitialiser le mode de paiement

      checkInDateTime = now;
      checkOutDateTime = now.add(Duration(hours: 1));

      // Recharger les chambres disponibles
      fetchAvailableRooms();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: checkInDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 7)), // Limite pour la réservation horaire
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Conserver l'heure actuelle
      final currentTime = checkInDateTime ?? DateTime.now();
      final newDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        currentTime.hour,
        currentTime.minute,
      );

      setState(() {
        checkInDateTime = newDateTime;
        _checkInDateController.text = DateFormat('dd/MM/yyyy').format(newDateTime);

        // Mise à jour de l'heure de fin
        checkOutDateTime = newDateTime.add(Duration(hours: _selectedDurationHours));
      });

      fetchAvailableRooms();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(checkInDateTime ?? DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Combiner la date actuelle avec la nouvelle heure
      final currentDate = checkInDateTime ?? DateTime.now();
      final newDateTime = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        picked.hour,
        picked.minute,
      );

      setState(() {
        checkInDateTime = newDateTime;
        _checkInTimeController.text = DateFormat('HH:mm').format(newDateTime);

        // Mise à jour de l'heure de fin
        checkOutDateTime = newDateTime.add(Duration(hours: _selectedDurationHours));
      });

      fetchAvailableRooms();
    }
  }

  void _updateDuration(int hours) {
    setState(() {
      _selectedDurationHours = hours;
      _durationController.text = '$hours ${hours > 1 ? "heures" : "heure"}';

      // Mise à jour de l'heure de fin
      if (checkInDateTime != null) {
        checkOutDateTime = checkInDateTime!.add(Duration(hours: hours));
      }
    });

    fetchAvailableRooms();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir les chambres filtrées basées sur le type sélectionné
    final filteredRooms = _getFilteredRooms();

    return Scaffold(
      appBar: AppBar(
        title: Text('Enregistrement client (passage par heure)'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchAvailableRooms,
            tooltip: 'Actualiser les chambres',
          ),
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _resetForm,
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      drawer: const SideMenu(),
      body: _isLoading && _availableRooms.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Séjour d'abord (avant les informations client)
              HourlyStayInfoSection(
                checkInDateController: _checkInDateController,
                checkInTimeController: _checkInTimeController,
                durationController: _durationController,
                numberOfGuests: _numberOfGuests,
                onGuestsChanged: (value) => setState(() => _numberOfGuests = value),
                selectedRoomType: _selectedRoomType,
                roomTypes: _roomTypes,
                onRoomTypeChanged: (value) {
                  setState(() {
                    _selectedRoomType = value;
                    _selectedRoom = null;
                  });
                },
                filteredRooms: filteredRooms,
                selectedRoom: _selectedRoom,
                onRoomSelected: (room) => setState(() => _selectedRoom = room),
                selectDate: () => _selectDate(context),
                selectTime: () => _selectTime(context),
                availableDurations: _availableDurations,
                selectedDuration: _selectedDurationHours,
                onDurationChanged: _updateDuration,
              ),

              SizedBox(height: 20),

              // Ensuite les informations client
              CustomerInfoSection(
                nameController: _customerNameController,
                emailController: _customerEmailController,
                phoneController: _customerPhoneController,
                idNumberController: _idNumberController,
                nationalityController: _nationalityController,
                addressController: _addressController,
              ),

              SizedBox(height: 20),

              // Section pour choisir le mode de paiement
              PaimentInfoSection(
                onPaymentMethodChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                },
              ),

              SizedBox(height: 24),

              // Récapitulatif (si une chambre est sélectionnée)
              if (_selectedRoom != null)
                _buildSummaryCard(context),

              SizedBox(height: 24),

              // Boutons d'action
              if (_isLoading && _availableRooms.isNotEmpty)
                Center(child: CircularProgressIndicator())
              else
                _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    // Calcul du montant en fonction de la durée
    final tarif = _selectedRoom!.price  * _selectedDurationHours;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Récapitulatif',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Chambre:'),
                Text(
                  'N° ${_selectedRoom!.number}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Type:'),
                Text(_selectedRoom!.type),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Prix horaire:'),
                Text(
                  '${_selectedRoom!.price.toStringAsFixed(0)} FCFA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Heure d\'arrivée:'),
                Text(
                  checkInDateTime != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(checkInDateTime!)
                      : '',
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Heure de départ:'),
                Text(
                  checkOutDateTime != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(checkOutDateTime!)
                      : '',
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Durée:'),
                Text('$_selectedDurationHours ${_selectedDurationHours > 1 ? "heures" : "heure"}'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mode de paiement:'),
                Text(
                  _selectedPaymentMethod ?? 'Non sélectionné',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:'),
                Text(
                  '${tarif.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.check_circle),
          label: Text('Enregistrer le client'),
          onPressed: _registerHourlyGuest,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 15),
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        SizedBox(height: 12),
        OutlinedButton.icon(
          icon: Icon(Icons.cancel),
          label: Text('Annuler'),
          onPressed: _resetForm,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 15),
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class HourlyStayInfoSection extends StatelessWidget {
  final TextEditingController checkInDateController;
  final TextEditingController checkInTimeController;
  final TextEditingController durationController;
  final int numberOfGuests;
  final Function(int) onGuestsChanged;
  final String? selectedRoomType;
  final List<String> roomTypes;
  final Function(String?) onRoomTypeChanged;
  final List<Room> filteredRooms;
  final Room? selectedRoom;
  final Function(Room) onRoomSelected;
  final VoidCallback selectDate;
  final VoidCallback selectTime;
  final List<int> availableDurations;
  final int selectedDuration;
  final Function(int) onDurationChanged;

  const HourlyStayInfoSection({
    Key? key,
    required this.checkInDateController,
    required this.checkInTimeController,
    required this.durationController,
    required this.numberOfGuests,
    required this.onGuestsChanged,
    required this.selectedRoomType,
    required this.roomTypes,
    required this.onRoomTypeChanged,
    required this.filteredRooms,
    required this.selectedRoom,
    required this.onRoomSelected,
    required this.selectDate,
    required this.selectTime,
    required this.availableDurations,
    required this.selectedDuration,
    required this.onDurationChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations séjour horaire',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            SizedBox(height: 10),

            // Date et heure d'arrivée
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: checkInDateController,
                    decoration: InputDecoration(
                      labelText: 'Date d\'arrivée',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    readOnly: true,
                    onTap: selectDate,
                    validator: (value) =>
                    value!.isEmpty ? 'Date requise' : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: checkInTimeController,
                    decoration: InputDecoration(
                      labelText: 'Heure d\'arrivée',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    readOnly: true,
                    onTap: selectTime,
                    validator: (value) =>
                    value!.isEmpty ? 'Heure requise' : null,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Durée du séjour
            TextFormField(
              controller: durationController,
              decoration: InputDecoration(
                labelText: 'Durée du séjour',
                prefixIcon: Icon(Icons.timer),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: PopupMenuButton<int>(
                  icon: Icon(Icons.arrow_drop_down),
                  onSelected: onDurationChanged,
                  itemBuilder: (context) {
                    return availableDurations.map((hours) {
                      return PopupMenuItem<int>(
                        value: hours,
                        child: Text('$hours ${hours > 1 ? "heures" : "heure"}'),
                      );
                    }).toList();
                  },
                ),
              ),
              readOnly: true,
              validator: (value) => value!.isEmpty ? 'Durée requise' : null,
            ),

            SizedBox(height: 16),

            // Nombre de personnes
            Row(
              children: [
                Expanded(
                  child: Text('Nombre de personnes'),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      onPressed: numberOfGuests > 1
                          ? () => onGuestsChanged(numberOfGuests - 1)
                          : null,
                    ),
                    Text(
                      '$numberOfGuests',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      onPressed: () => onGuestsChanged(numberOfGuests + 1),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),

            // Type de chambre
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Type de chambre',
                prefixIcon: Icon(Icons.hotel),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: selectedRoomType,
              validator: (value) =>
              value == null ? 'Veuillez sélectionner un type de chambre' : null,
              items: roomTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: onRoomTypeChanged,
            ),

            SizedBox(height: 16),

            // Liste des chambres disponibles
            // Liste des chambres disponibles
            if (filteredRooms.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chambres disponibles:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 200, // Hauteur fixe pour la liste
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: filteredRooms.length,
                      itemBuilder: (context, index) {
                        final room = filteredRooms[index];
                        final isSelected = selectedRoom?.id == room.id;

                        return ListTile(
                          title: Text(
                            'Chambre ${room.number} - ${room.type}',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            'Capacité: ${room.capacity} pers. - ${(room.price  * selectedDuration).toStringAsFixed(0)} FCFA',
                          ),
                          selected: isSelected,
                          selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          onTap: () => onRoomSelected(room),
                          leading: Icon(
                            Icons.hotel,
                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              )
            else if (selectedRoomType != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Aucune chambre disponible pour ce type et cette période',
                    style: TextStyle(
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}