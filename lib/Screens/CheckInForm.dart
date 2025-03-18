import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/reservation/ModernReservationPage.dart';
import '../config/generationcode.dart';


class CheckInForm extends StatefulWidget {
  final Reservation reservation;

  const CheckInForm({super.key, required this.reservation});

  @override
  State<CheckInForm> createState() => _CheckInFormState();
}
final userId = FirebaseAuth.instance.currentUser!.uid;
class _CheckInFormState extends State<CheckInForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _idNumberController = TextEditingController();
  TextEditingController _nationalityController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.reservation.customerName;
    _checkInDate = widget.reservation.checkInDate;
    _checkOutDate = widget.reservation.checkOutDate;
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
      // Call a function here to save the booking details
      // You'll need to pass the collected information and the original reservation ID
      final numberOfNights = _checkOutDate?.difference(_checkInDate!).inDays;
      final numberOfNightsCorrected = numberOfNights! + (_checkOutDate!.isAfter(_checkInDate!) ? 1 : 0);
      final bookingData = {
        'customerName': _fullNameController.text,
        'idNumber': _idNumberController.text,
        'nationality': _nationalityController.text,
        'address': _addressController.text,
        'checkInDate': _checkInDate,
        'checkOutDate': _checkOutDate,
        // Add other relevant details from widget.reservation
        'reservationId': widget.reservation.id,
        'roomId': widget.reservation.roomId,
        'roomNumber': widget.reservation.roomNumber,
        'roomType': widget.reservation.roomType,
        'customerEmail': widget.reservation.customerEmail,
        'customerPhone': widget.reservation.customerPhone,
        'numberOfGuests': widget.reservation.numberOfGuests,
        'specialRequests': widget.reservation.specialRequests,
        'nights': numberOfNightsCorrected, // Recalculate nights
        'pricePerNight': widget.reservation.pricePerNight,
        'totalAmount': widget.reservation.pricePerNight != null && _checkOutDate != null && _checkInDate != null
            ? widget.reservation.pricePerNight! * numberOfNightsCorrected
            : null,
        'userId': userId, // Assuming userId is available in this scope
      };

      // Call a function to save this bookingData to Firestore
      await _saveBookingData(bookingData);

      if (context.mounted) {
        Navigator.pop(context); // Go back to the previous screen
      }
    }
  }

  Future<void> _saveBookingData(Map<String, dynamic> bookingData) async {
    try {
      // Generate a unique EnregistrementCode
      final enregistrementCode = await CodeGenerator.generateRegistrationCode();

      // Create a new document in the 'bookings' collection
      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();
      await bookingRef.set({
        'EnregistrementCode': enregistrementCode,
        'actualCheckOutDate': DateTime.now().toUtc(), // Current UTC time as actual check-out (can be updated later)
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
        'paymentStatus': 'En attente', // You might need to handle payment status
        'roomId': bookingData['roomId'],
        'roomNumber': bookingData['roomNumber'],
        'roomPrice': bookingData['pricePerNight'],
        'roomType': bookingData['roomType'],
        'status': 'enregistré', // Status in the bookings collection
        'totalAmount': bookingData['totalAmount'],
        'userId': bookingData['userId'],
      });

      // Update the status in the 'reservations' collection
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(bookingData['reservationId'])
          .update({'status': 'Enregistré'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client enregistré avec succès')),
      );

      // You might want to refresh the reservations list here or navigate back
      // For now, let's just pop the current screen
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
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

                const SizedBox(height: 30),

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
                        Icon(Icons.check),
                        SizedBox(width: 8),
                        Text(
                          'Confirmer l\'enregistrement',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}