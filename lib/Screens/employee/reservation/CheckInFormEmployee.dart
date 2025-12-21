import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../components/checkin/options_package_section.dart';
import '../../../config/generationcode.dart';
import '../../../config/getConnectedUserAdminId.dart';
import '../../../config/HotelSettingsService.dart';
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

  // Heures par défaut de l'hôtel
  String? _defaultCheckInTime;
  String? _defaultCheckOutTime;

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

      // Charger les heures par défaut de l'hôtel
      await _loadDefaultHotelHours();

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

  // Charger les heures par défaut de l'hôtel
  Future<void> _loadDefaultHotelHours() async {
    try {
      final settingsService = HotelSettingsService();
      final settings = await settingsService.getHotelSettings();
      
      setState(() {
        _defaultCheckInTime = settings['checkInTime'] ?? '12:00';
        _defaultCheckOutTime = settings['checkOutTime'] ?? '10:00';
      });
      
      print('⏰ Heures par défaut chargées: Check-in: $_defaultCheckInTime, Check-out: $_defaultCheckOutTime');
    } catch (e) {
      print('Erreur lors du chargement des heures par défaut: $e');
      // Valeurs par défaut en cas d'erreur
      setState(() {
        _defaultCheckInTime = '12:00';
        _defaultCheckOutTime = '10:00';
      });
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
      // Appliquer automatiquement l'heure de check-in par défaut de l'hôtel
      DateTime dateWithTime = picked;
      if (_defaultCheckInTime != null) {
        final timeParts = _defaultCheckInTime!.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        dateWithTime = DateTime(picked.year, picked.month, picked.day, hour, minute);
      }
      
      setState(() {
        _checkInDate = dateWithTime;
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
      // Appliquer automatiquement l'heure de check-out par défaut de l'hôtel
      DateTime dateWithTime = picked;
      if (_defaultCheckOutTime != null) {
        final timeParts = _defaultCheckOutTime!.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        dateWithTime = DateTime(picked.year, picked.month, picked.day, hour, minute);
      }
      
      setState(() {
        _checkOutDate = dateWithTime;
      });
    }
  }

  // Vérifier la disponibilité de la chambre pour les nouvelles dates
  // Supporte le cycle hôtelier standard (check-out 12h, check-in 12h)
  // Une chambre est disponible si le départ <= arrivée suivante
  Future<bool> _isRoomAvailable(String roomId, DateTime checkIn, DateTime checkOut, String currentReservationId) async {
    try {
      // Vérifier dans les réservations
      final reservationsSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('roomId', isEqualTo: roomId)
          .where('status', whereIn: ['en attente', 'réservée', 'Confirmée', 'Enregistré']).get();

      for (var doc in reservationsSnapshot.docs) {
        // Ignorer la réservation actuelle
        if (doc.id == currentReservationId) continue;
        
        final data = doc.data();
        DateTime resCheckIn = (data['checkInDate'] as Timestamp).toDate();
        DateTime resCheckOut = (data['checkOutDate'] as Timestamp).toDate();

        // Vérifier le chevauchement des dates
        // Pas de conflit si: notre départ <= leur arrivée OU notre arrivée >= leur départ
        // Cela permet le cycle 12h-12h (départ 12h = arrivée 12h même jour)
        bool noOverlap = checkOut.isBefore(resCheckIn) || 
                         checkOut.isAtSameMomentAs(resCheckIn) ||
                         checkIn.isAfter(resCheckOut) || 
                         checkIn.isAtSameMomentAs(resCheckOut);
        
        if (!noOverlap) {
          return false;
        }
      }

      // Vérifier dans les enregistrements (bookings)
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('roomId', isEqualTo: roomId)
          .where('status', whereNotIn: ['Terminé', 'Annulé']).get();

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        DateTime resCheckIn = (data['checkInDate'] as Timestamp).toDate();
        DateTime resCheckOut = (data['checkOutDate'] as Timestamp).toDate();

        // Même logique pour les bookings
        bool noOverlap = checkOut.isBefore(resCheckIn) || 
                         checkOut.isAtSameMomentAs(resCheckIn) ||
                         checkIn.isAfter(resCheckOut) || 
                         checkIn.isAtSameMomentAs(resCheckOut);
        
        if (!noOverlap) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Erreur lors de la vérification de disponibilité: $e');
      return false;
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

      // Vérifier si les dates ont changé par rapport à la réservation originale
      final originalCheckIn = widget.reservation.checkInDate;
      final originalCheckOut = widget.reservation.checkOutDate;
      final datesChanged = !(_checkInDate!.isAtSameMomentAs(originalCheckIn) && 
                             _checkOutDate!.isAtSameMomentAs(originalCheckOut));

      // Si les dates ont changé, vérifier la disponibilité de la chambre
      if (datesChanged) {
        final isAvailable = await _isRoomAvailable(
          widget.reservation.roomId,
          _checkInDate!,
          _checkOutDate!,
          widget.reservation.id,
        );

        if (!isAvailable) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                      const SizedBox(width: 12),
                      const Text('Chambre non disponible'),
                    ],
                  ),
                  content: const Text(
                    'Cette chambre est déjà réservée ou occupée pour les dates sélectionnées. Veuillez choisir d\'autres dates ou contacter la réception.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
          return;
        }
      }

      // Calculer le nombre de nuits (différence en jours entre check-out et check-in)
      final numberOfNights = _checkOutDate!.difference(_checkInDate!).inDays;

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
        'nights': numberOfNights,
        'pricePerNight': widget.reservation.pricePerNight,
        'totalAmount': widget.reservation.pricePerNight != null
            ? widget.reservation.pricePerNight! * numberOfNights
            : null,
        'idEmploye': FirebaseAuth.instance.currentUser?.uid, // UID de l'utilisateur connecté
        'userId': idadmin, // ID admin récupéré
        'options': _selectedOptions, // AJOUT DES OPTIONS
      };

      // Enregistrer les données
      await _saveBookingData(bookingData);
      
      // Le retour à l'écran précédent est géré dans _saveBookingData()
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enregistrement du Client',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Réservation #${widget.reservation.reservationCode}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // En-tête avec informations sur la réservation
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.hotel, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Détails de la Réservation',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItemWhite(
                            'Chambre',
                            '${widget.reservation.roomNumber}',
                            Icons.meeting_room,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        Expanded(
                          child: _buildInfoItemWhite(
                            'Type',
                            widget.reservation.roomType,
                            Icons.home_work,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItemWhite(
                            'Client',
                            widget.reservation.customerName,
                            Icons.person,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        Expanded(
                          child: _buildInfoItemWhite(
                            'Invités',
                            '${widget.reservation.numberOfGuests}',
                            Icons.group,
                          ),
                        ),
                      ],
                    ),
                    if (widget.reservation.pricePerNight != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Prix par nuit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${widget.reservation.pricePerNight!.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Formulaire d'informations personnelles
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Section Informations personnelles
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.person, color: Colors.deepPurple.shade600),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Informations Personnelles',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                labelText: 'Nom Complet *',
                                hintText: 'Entrez le nom complet',
                                prefixIcon: Icon(Icons.person_outline, color: Colors.deepPurple.shade400),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
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
                                labelText: 'Numéro de pièce d\'identité *',
                                hintText: 'Entrez le numéro d\'identité',
                                prefixIcon: Icon(Icons.badge_outlined, color: Colors.deepPurple.shade400),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
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
                                labelText: 'Nationalité *',
                                hintText: 'Entrez la nationalité',
                                prefixIcon: Icon(Icons.flag_outlined, color: Colors.deepPurple.shade400),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
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
                                labelText: 'Adresse *',
                                hintText: 'Entrez l\'adresse complète',
                                prefixIcon: Icon(Icons.home_outlined, color: Colors.deepPurple.shade400),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
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

                    const SizedBox(height: 16),

                    // Section Dates du séjour
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
                                    '${_checkOutDate!.difference(_checkInDate!).inDays} nuit(s)',
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
      ]),
    ));
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

  // Widget pour afficher les informations sur fond coloré (blanc sur fond bleu)
  Widget _buildInfoItemWhite(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
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