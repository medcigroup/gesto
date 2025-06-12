import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/checkin/options_package_section.dart';
import '../../components/reservation/ModernReservationPage.dart';
import '../../config/generationcode.dart';
import '../../config/getConnectedUserAdminId.dart'; // Ajout pour récupérer l'userId admin


class CheckInForm extends StatefulWidget {
  final Reservation reservation;

  const CheckInForm({super.key, required this.reservation});

  @override
  State<CheckInForm> createState() => _CheckInFormState();
}

class _CheckInFormState extends State<CheckInForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _idNumberController = TextEditingController();
  TextEditingController _nationalityController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  // Variables pour les options
  Map<String, bool> _selectedOptions = {};
  String? _userId;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.reservation.customerName;
    _checkInDate = widget.reservation.checkInDate;
    _checkOutDate = widget.reservation.checkOutDate;
    _initializeUserId();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _idNumberController.dispose();
    _nationalityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Initialiser l'userId
  Future<void> _initializeUserId() async {
    try {
      // Récupérer l'ID admin connecté
      _userId = await getConnectedUserAdminId();
      print('✅ UserId récupéré pour CheckInForm: $_userId');

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'userId: $e');
      // Fallback vers l'userId Firebase Auth
      _userId = FirebaseAuth.instance.currentUser?.uid;
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  // Gérer les changements d'options
  void _onOptionsChanged(Map<String, bool> options) {
    setState(() {
      _selectedOptions = options;
    });
    print('🎛️ Options sélectionnées dans CheckInForm: ${options.toString()}');
  }

  Future<void> _selectCheckInDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _checkInDate) {
      setState(() {
        _checkInDate = picked;
      });
    }
  }

  Future<void> _selectCheckOutDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _checkOutDate) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }

  void _confirmCheckIn() async {
    if (_formKey.currentState!.validate()) {
      final numberOfNights = _checkOutDate?.difference(_checkInDate!).inDays;
      final numberOfNightsCorrected = numberOfNights! + (_checkOutDate!.isAfter(_checkInDate!) ? 1 : 0);

      final bookingData = {
        'customerName': _fullNameController.text,
        'idNumber': _idNumberController.text,
        'nationality': _nationalityController.text,
        'address': _addressController.text,
        'checkInDate': _checkInDate,
        'checkOutDate': _checkOutDate,
        'reservationId': widget.reservation.id,
        'roomId': widget.reservation.roomId,
        'roomNumber': widget.reservation.roomNumber,
        'roomType': widget.reservation.roomType,
        'customerEmail': widget.reservation.customerEmail,
        'customerPhone': widget.reservation.customerPhone,
        'numberOfGuests': widget.reservation.numberOfGuests,
        'specialRequests': widget.reservation.specialRequests,
        'nights': numberOfNightsCorrected,
        'pricePerNight': widget.reservation.pricePerNight,
        'totalAmount': widget.reservation.pricePerNight != null && _checkOutDate != null && _checkInDate != null
            ? widget.reservation.pricePerNight! * numberOfNightsCorrected
            : null,
        'userId': _userId ?? FirebaseAuth.instance.currentUser!.uid,
        'options': _selectedOptions, // AJOUT DES OPTIONS
      };

      await _saveBookingData(bookingData);

      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveBookingData(Map<String, dynamic> bookingData) async {
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
      // Generate a unique EnregistrementCode
      final enregistrementCode = await CodeGenerator.generateRegistrationCode();

      // Récupérer les informations d'acompte de la réservation originale
      final reservationDoc = await FirebaseFirestore.instance
          .collection('reservations')
          .doc(bookingData['reservationId'])
          .get();

      // Extraire les données d'acompte
      final depositAmount = reservationDoc.data()?['depositAmount'] ?? 0;
      final depositPercentage = reservationDoc.data()?['depositPercentage'] ?? 0;
      final depositPaid = reservationDoc.data()?['depositPaid'] ?? false;

      // Calculer le montant restant à payer
      final totalAmount = bookingData['totalAmount'] ?? 0;
      final balanceDue = totalAmount - depositAmount;

      // Create a new document in the 'bookings' collection
      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();
      await bookingRef.set({
        'EnregistrementCode': enregistrementCode,
        'reservationId': bookingData['reservationId'],
        'actualCheckOutDate': DateTime.now().toUtc(),
        'address': bookingData['address'],
        'checkInDate': bookingData['checkInDate'],
        'checkOutDate': bookingData['checkOutDate'],
        'createdAt': FieldValue.serverTimestamp(),
        'customerEmail': bookingData['customerEmail'],
        'customerName': bookingData['customerName'],
        'customerPhone': bookingData['customerPhone'],
        'idNumber': bookingData['idNumber'],
        'isWalkIn': false,
        'nationality': bookingData['nationality'],
        'nights': bookingData['nights'],
        'numberOfGuests': bookingData['numberOfGuests'],
        'paymentStatus': balanceDue > 0 ? 'Partiellement payé' : 'Payé',
        'roomId': bookingData['roomId'],
        'roomNumber': bookingData['roomNumber'],
        'roomPrice': bookingData['pricePerNight'],
        'roomType': bookingData['roomType'],
        'status': 'enregistré',
        'totalAmount': bookingData['totalAmount'],
        'userId': bookingData['userId'],
        'depositAmount': depositAmount,
        'depositPercentage': depositPercentage,
        'depositPaid': depositPaid,
        'balanceDue': balanceDue,
        'options': bookingData['options'], // SAUVEGARDER LES OPTIONS
      });

      // Update the status in the 'reservations' collection
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(bookingData['reservationId'])
          .update({'status': 'Enregistré'});

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(bookingData['roomId'])
          .update({
        'status': 'occupée',
        'datedisponible': Timestamp.fromDate(_checkOutDate!),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Fermer le dialogue de chargement
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un écran de chargement pendant l'initialisation
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: const Text('Enregistrement du Client'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initialisation...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Enregistrement du Client'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Informations de la réservation
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text(
                              'Informations de la Réservation',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Chambre:', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text('N° ${widget.reservation.roomNumber}', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Type:', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text(widget.reservation.roomType),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Personnes:', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text('${widget.reservation.numberOfGuests}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Informations Personnelles
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations Personnelles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Nom Complet*',
                            hintText: 'Entrez le nom complet',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le nom complet';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _idNumberController,
                          decoration: InputDecoration(
                            labelText: 'Numéro de pièce d\'identité*',
                            hintText: 'Entrez le numéro d\'identité',
                            prefixIcon: const Icon(Icons.badge),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le numéro de pièce d\'identité';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nationalityController,
                          decoration: InputDecoration(
                            labelText: 'Nationalité*',
                            hintText: 'Entrez la nationalité',
                            prefixIcon: const Icon(Icons.flag),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer la nationalité';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Adresse*',
                            hintText: 'Entrez l\'adresse complète',
                            prefixIcon: const Icon(Icons.home),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer l\'adresse';
                            }
                            return null;
                          },
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Dates du Séjour
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dates du Séjour',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectCheckInDate(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Date d\'arrivée*',
                                    prefixIcon: const Icon(Icons.calendar_today),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    _checkInDate == null
                                        ? 'Sélectionner'
                                        : DateFormat('dd/MM/yyyy').format(_checkInDate!),
                                    style: _checkInDate == null
                                        ? TextStyle(color: Theme.of(context).hintColor)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectCheckOutDate(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Date de départ*',
                                    prefixIcon: const Icon(Icons.event_available),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    _checkOutDate == null
                                        ? 'Sélectionner'
                                        : DateFormat('dd/MM/yyyy').format(_checkOutDate!),
                                    style: _checkOutDate == null
                                        ? TextStyle(color: Theme.of(context).hintColor)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION OPTIONS GRATUITES
                OptionsSection(
                  selectedOptions: _selectedOptions,
                  onOptionsChanged: _onOptionsChanged,
                  userId: _userId,
                ),

                const SizedBox(height: 30),

                // Bouton de confirmation
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _checkInDate != null && _checkOutDate != null) {
                      if (_checkOutDate!.isBefore(_checkInDate!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('La date de départ doit être après la date d\'arrivée'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        _confirmCheckIn();
                      }
                    } else if (_checkInDate == null || _checkOutDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez sélectionner les dates d\'arrivée et de départ'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle),
                        SizedBox(width: 8),
                        Text(
                          'Confirmer l\'enregistrement',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}