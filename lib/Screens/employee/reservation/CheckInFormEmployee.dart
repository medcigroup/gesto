import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../components/checkin/options_package_section.dart';
import '../../../config/generationcode.dart';
import '../../../config/getConnectedUserAdminId.dart';
class CheckInFormEmployee extends StatefulWidget {
  final Reservation reservation;

  const CheckInFormEmployee({Key? key, required this.reservation}) : super(key: key);

  @override
  State<CheckInFormEmployee> createState() => _CheckInFormEmployeeState();
}

class _CheckInFormEmployeeState extends State<CheckInFormEmployee> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs de texte
  late TextEditingController _fullNameController;
  late TextEditingController _idNumberController;
  late TextEditingController _nationalityController;
  late TextEditingController _addressController;

  // Dates de séjour
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  // ID admin
  String? idadmin;
  bool _isLoading = true;

  // Variables pour les options
  Map<String, bool> _selectedOptions = {};

  @override
  void initState() {
    super.initState();

    // Initialiser les contrôleurs
    _fullNameController = TextEditingController(text: widget.reservation.customerName);
    _idNumberController = TextEditingController();
    _nationalityController = TextEditingController();
    _addressController = TextEditingController();

    // Initialiser les dates
    _checkInDate = widget.reservation.checkInDate;
    _checkOutDate = widget.reservation.checkOutDate;

    // Charger l'ID admin
    _loadAdminId();
  }

  @override
  void dispose() {
    // Libérer les ressources des contrôleurs
    _fullNameController.dispose();
    _idNumberController.dispose();
    _nationalityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Gérer les changements d'options
  void _onOptionsChanged(Map<String, bool> options) {
    setState(() {
      _selectedOptions = options;
    });
    print('🎛️ Options sélectionnées dans CheckInFormEmployee: ${options.toString()}');
  }

  // Méthode pour charger l'ID admin
  Future<void> _loadAdminId() async {
    try {
      idadmin = await getConnectedUserAdminId();
      print('✅ UserId récupéré pour CheckInFormEmployee: $idadmin');

      setState(() {
        _isLoading = false;
      });

      if (idadmin == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Impossible de récupérer l\'ID administrateur'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Sélection de la date d'arrivée
  Future<void> _selectCheckInDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _checkInDate && mounted) {
      setState(() {
        _checkInDate = picked;
      });
    }
  }

  // Sélection de la date de départ
  Future<void> _selectCheckOutDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate ?? (DateTime.now().add(const Duration(days: 1))),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _checkOutDate && mounted) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }

  // Confirmation de l'enregistrement
  void _confirmCheckIn() async {
    if (_formKey.currentState!.validate()) {
      if (idadmin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: ID administrateur non disponible'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Calculer le nombre de nuits
      final numberOfNights = _checkOutDate!.difference(_checkInDate!).inDays;
      final numberOfNightsCorrected = numberOfNights + (_checkOutDate!.isAfter(_checkInDate!) ? 1 : 0);

      // Préparer les données de réservation
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
        'totalAmount': widget.reservation.pricePerNight != null
            ? widget.reservation.pricePerNight! * numberOfNightsCorrected
            : null,
        'idEmploye': FirebaseAuth.instance.currentUser?.uid, // UID de l'utilisateur connecté
        'userId': idadmin, // ID admin récupéré
        'options': _selectedOptions, // AJOUT DES OPTIONS
      };

      // Enregistrer les données
      await _saveBookingData(bookingData);

      if (mounted) {
        Navigator.pop(context); // Retour à l'écran précédent après enregistrement
      }
    }
  }

  // Sauvegarde des données d'enregistrement dans Firestore
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
      // Générer un code d'enregistrement unique
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

      // Créer un nouveau document dans la collection 'bookings'
      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();
      await bookingRef.set({
        'EnregistrementCode': enregistrementCode,
        'reservationId': bookingData['reservationId'],
        'actualCheckOutDate': null, // Sera mis à jour lors du départ
        'address': bookingData['address'],
        'checkInDate': bookingData['checkInDate'],
        'checkOutDate': bookingData['checkOutDate'],
        'createdAt': FieldValue.serverTimestamp(),
        'customerEmail': bookingData['customerEmail'],
        'customerName': bookingData['customerName'],
        'customerPhone': bookingData['customerPhone'],
        'idNumber': bookingData['idNumber'],
        'isWalkIn': false, // Réservation préalable, pas une arrivée sans réservation
        'nationality': bookingData['nationality'],
        'nights': bookingData['nights'],
        'numberOfGuests': bookingData['numberOfGuests'],
        'paymentStatus': balanceDue > 0 ? 'Partiellement payé' : 'Payé',
        'roomId': bookingData['roomId'],
        'roomNumber': bookingData['roomNumber'],
        'roomPrice': bookingData['pricePerNight'],
        'roomType': bookingData['roomType'],
        'specialRequests': bookingData['specialRequests'],
        'status': 'enregistré',
        'totalAmount': bookingData['totalAmount'],
        'userId': bookingData['userId'],
        'idEmploye': bookingData['idEmploye'],
        // Informations d'acompte
        'depositAmount': depositAmount,
        'depositPercentage': depositPercentage,
        'depositPaid': depositPaid,
        'balanceDue': balanceDue,
        'options': bookingData['options'], // SAUVEGARDER LES OPTIONS
      });

      // Mettre à jour le statut dans la collection 'reservations'
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(bookingData['reservationId'])
          .update({
        'status': 'Enregistré',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Mettre à jour le statut de la chambre
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

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Retourner à l'écran précédent
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Afficher le message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un indicateur de chargement pendant le chargement de l'idadmin
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chargement...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
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
                // En-tête avec informations sur la réservation
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
                              'Détails de la Réservation',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                'Chambre',
                                '${widget.reservation.roomNumber} (${widget.reservation.roomType})',
                                Icons.hotel,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'Client',
                                widget.reservation.customerName,
                                Icons.person,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                'Téléphone',
                                widget.reservation.customerPhone,
                                Icons.phone,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'Invités',
                                '${widget.reservation.numberOfGuests} personne(s)',
                                Icons.group,
                              ),
                            ),
                          ],
                        ),
                        if (widget.reservation.pricePerNight != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  'Prix/nuit',
                                  '${widget.reservation.pricePerNight!.toStringAsFixed(0)} FCFA',
                                  Icons.monetization_on,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  'Code Réservation',
                                  widget.reservation.reservationCode,
                                  Icons.confirmation_number,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Informations personnelles
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations Personnelles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
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

                // Dates du séjour
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dates du Séjour',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
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
                        if (_checkInDate != null && _checkOutDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Durée du séjour:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '${_checkOutDate!.difference(_checkInDate!).inDays + 1} nuit(s)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                  userId: idadmin,
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

  // Widget pour afficher les éléments d'information
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Classe Reservation pour utilisation dans CheckInFormEmployee
class Reservation {
  final String id;
  final String customerName;
  final String roomNumber;
  final String roomType;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String status;
  final String roomId;
  final String reservationCode;
  final String customerEmail;
  final String customerPhone;
  final int numberOfGuests;
  final String specialRequests;
  final int? numberOfNights;
  final double? pricePerNight;
  final double? totalPrice;
  final int? depositPercentage;
  final double? depositAmount;
  final String? paymentMethod;
  final bool? depositPaid;

  Reservation({
    required this.id,
    required this.customerName,
    required this.roomNumber,
    required this.roomType,
    required this.checkInDate,
    required this.checkOutDate,
    required this.status,
    required this.roomId,
    required this.reservationCode,
    required this.customerEmail,
    required this.customerPhone,
    required this.numberOfGuests,
    required this.specialRequests,
    this.numberOfNights,
    this.pricePerNight,
    this.totalPrice,
    this.depositPercentage,
    this.depositAmount,
    this.paymentMethod,
    this.depositPaid = false,
  });
}