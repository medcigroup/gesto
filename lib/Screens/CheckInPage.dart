import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../components/checkin/CustomerInfoSection.dart';
import '../config/generationcode.dart';
import '../config/room_models.dart';
import '../widgets/side_menu.dart';
 // Nouveau widget pour les infos client

class CheckInPage extends StatefulWidget {
  @override
  _CheckInPageState createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
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
  final _checkOutDateController = TextEditingController();
  int _numberOfGuests = 1;
  String? _selectedRoomType;

  bool _isLoading = false;
  List<String> _roomTypes = [];
  List<Room> _availableRooms = [];
  Room? _selectedRoom;

  @override
  void initState() {
    super.initState();
    // Initialiser les dates avec aujourd'hui et demain
    final now = DateTime.now();
    final tomorrow = now.add(Duration(days: 1));
    _checkInDateController.text = DateFormat('dd/MM/yyyy').format(now);
    _checkOutDateController.text = DateFormat('dd/MM/yyyy').format(tomorrow);

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
      // Obtenir l'ID de l'utilisateur connecté
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer les chambres disponibles
      final snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('status', isEqualTo: 'disponible')
          .where('userId', isEqualTo: userId)
          .get();

      final rooms = snapshot.docs.map((doc) {
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
          userId: '',
        );
      }).toList();

      // Trier les chambres par numéro
      rooms.sort((a, b) => compareRoomNumbers(a.number, b.number));

      // Extraire les types de chambres uniques
      final types = rooms.map((room) => room.type).toSet().toList();

      setState(() {
        _availableRooms = rooms;
        _roomTypes = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement des chambres: ${e.toString()}');
    }
  }

  // Filtrer les chambres selon le type sélectionné
  List<Room> _getFilteredRooms() {
    if (_selectedRoomType == null) return [];

    return _availableRooms.where((room) =>
    room.type == _selectedRoomType &&
        room.capacity >= _numberOfGuests
    ).toList();
  }

  Future<void> _registerWalkInGuest() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRoom == null) {
        _showErrorSnackBar('Veuillez sélectionner une chambre');
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Obtenir l'ID de l'utilisateur connecté
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          throw Exception('Utilisateur non connecté');
        }

        // Créer un nouveau document de réservation
        final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();

        // Générer un code de réservation unique
        String generatedReservationCode = await CodeGenerator.generateRegistrationCode();

        // Convertir les dates
        final checkInDate = DateFormat('dd/MM/yyyy').parse(_checkInDateController.text);
        final checkOutDate = DateFormat('dd/MM/yyyy').parse(_checkOutDateController.text);

        // Calculer le nombre de nuits
        final nights = checkOutDate.difference(checkInDate).inDays;

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
          'checkInDate': Timestamp.fromDate(checkInDate),
          'checkOutDate': Timestamp.fromDate(checkOutDate),
          'numberOfGuests': _numberOfGuests,
          'nights': nights,
          'totalAmount': _selectedRoom!.price * nights,
          'status': 'enregistré',
          'createdAt': FieldValue.serverTimestamp(),
          'userId': userId,
          'isWalkIn': true,
        });

        // Mettre à jour le statut de la chambre
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(_selectedRoom!.id)
            .update({
          'status': 'occupée',
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        _showSuccessSnackBar('Client enregistré avec succès');
        _resetForm();
      } catch (e) {
        _showErrorSnackBar('Erreur lors de l\'enregistrement: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();

    // Réinitialiser les dates
    final now = DateTime.now();
    final tomorrow = now.add(Duration(days: 1));

    setState(() {
      _customerNameController.clear();
      _customerEmailController.clear();
      _customerPhoneController.clear();
      _idNumberController.clear();
      _nationalityController.clear();
      _addressController.clear();
      _checkInDateController.text = DateFormat('dd/MM/yyyy').format(now);
      _checkOutDateController.text = DateFormat('dd/MM/yyyy').format(tomorrow);
      _numberOfGuests = 1;
      _selectedRoomType = null;
      _selectedRoom = null;

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

  Future<void> _selectDate(BuildContext context, TextEditingController controller, {bool isCheckOut = false}) async {
    DateTime initialDate;
    DateTime firstDate;

    if (isCheckOut && _checkInDateController.text.isNotEmpty) {
      try {
        // Pour le check-out, la date initiale est au moins un jour après le check-in
        final checkInDate = DateFormat('dd/MM/yyyy').parse(_checkInDateController.text);
        initialDate = checkInDate.add(Duration(days: 1));
        firstDate = checkInDate.add(Duration(days: 1));
      } catch (e) {
        initialDate = DateTime.now();
        firstDate = DateTime.now();
      }
    } else {
      initialDate = DateTime.now();
      firstDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(Duration(days: 365)),
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
      controller.text = DateFormat('dd/MM/yyyy').format(picked);

      // Si on change la date d'arrivée, vérifier que la date de départ est toujours valide
      if (!isCheckOut && _checkOutDateController.text.isNotEmpty) {
        try {
          final checkOutDate = DateFormat('dd/MM/yyyy').parse(_checkOutDateController.text);
          if (!checkOutDate.isAfter(picked)) {
            // Mettre à jour la date de départ pour être le lendemain de l'arrivée
            _checkOutDateController.text = DateFormat('dd/MM/yyyy').format(picked.add(Duration(days: 1)));
          }
        } catch (e) {
          // Ignorer les erreurs de parsing
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir les chambres filtrées basées sur le type sélectionné
    final filteredRooms = _getFilteredRooms();

    return Scaffold(
      appBar: AppBar(
        title: Text('Enregistrement client'),
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
              StayInfoSection(
                checkInDateController: _checkInDateController,
                checkOutDateController: _checkOutDateController,
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
                selectDate: _selectDate,
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
                Text('Prix par nuit:'),
                Text(
                  '${_selectedRoom!.price.toStringAsFixed(0)} FCFA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),

            Builder(
              builder: (context) {
                try {
                  final checkInDate = DateFormat('dd/MM/yyyy').parse(_checkInDateController.text);
                  final checkOutDate = DateFormat('dd/MM/yyyy').parse(_checkOutDateController.text);
                  final nights = checkOutDate.difference(checkInDate).inDays;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Durée du séjour:'),
                          Text('$nights nuit${nights > 1 ? 's' : ''}'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:'),
                          Text(
                            '${(_selectedRoom!.price * nights).toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } catch (e) {
                  return SizedBox();
                }
              },
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
          onPressed: _registerWalkInGuest,
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


class StayInfoSection extends StatelessWidget {
  final TextEditingController checkInDateController;
  final TextEditingController checkOutDateController;
  final int numberOfGuests;
  final Function(int) onGuestsChanged;
  final String? selectedRoomType;
  final List<String> roomTypes;
  final Function(String?) onRoomTypeChanged;
  final List<Room> filteredRooms;
  final Room? selectedRoom;
  final Function(Room) onRoomSelected;
  final Future<void> Function(BuildContext, TextEditingController, {bool isCheckOut}) selectDate;

  const StayInfoSection({
    Key? key,
    required this.checkInDateController,
    required this.checkOutDateController,
    required this.numberOfGuests,
    required this.onGuestsChanged,
    required this.selectedRoomType,
    required this.roomTypes,
    required this.onRoomTypeChanged,
    required this.filteredRooms,
    required this.selectedRoom,
    required this.onRoomSelected,
    required this.selectDate,
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
              'Informations séjour',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            SizedBox(height: 10),

            // Dates
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
                    onTap: () => selectDate(context, checkInDateController),
                    validator: (value) =>
                    value!.isEmpty ? 'Date requise' : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: checkOutDateController,
                    decoration: InputDecoration(
                      labelText: 'Date de départ',
                      prefixIcon: Icon(Icons.event_available),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    readOnly: true,
                    onTap: () => selectDate(
                        context,
                        checkOutDateController,
                        isCheckOut: true
                    ),
                    validator: (value) =>
                    value!.isEmpty ? 'Date requise' : null,
                  ),
                ),
              ],
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
            if (filteredRooms.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chambres disponibles',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: filteredRooms.length,
                      itemBuilder: (context, index) {
                        final room = filteredRooms[index];
                        final isSelected = selectedRoom?.id == room.id;

                        return Card(
                          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                          margin: EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => onRoomSelected(room),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // Image de la chambre (ou icône par défaut)
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: room.image.isNotEmpty
                                          ? DecorationImage(
                                        image: NetworkImage(room.image),
                                        fit: BoxFit.cover,
                                      )
                                          : null,
                                      color: room.image.isEmpty ? Colors.grey.shade200 : null,
                                    ),
                                    child: room.image.isEmpty
                                        ? Icon(Icons.hotel, size: 40, color: Colors.grey)
                                        : null,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Chambre ${room.number}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Étage: ${room.floor}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Capacité: ${room.capacity} personne${room.capacity > 1 ? 's' : ''}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        if (room.amenities.isNotEmpty)
                                          Text(
                                            '${room.amenities.take(8).join(", ")}${room.amenities.length > 8 ? "..." : ""}',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${room.price.toStringAsFixed(0)} FCFA',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      Text(
                                        'par nuit',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

            if (selectedRoomType != null && filteredRooms.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Aucune chambre disponible pour ce type et ces critères',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}