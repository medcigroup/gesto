import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:gesto/config/room_models.dart';
import 'package:intl/intl.dart';

import '../../../config/HotelSettingsService.dart';
import '../../../config/generationcode.dart';
import '../../../config/getConnectedUserAdminId.dart';
import '../../../config/printReservationReceipt.dart';
import 'CheckInFormEmployee.dart';




class ModernReservationPageEnploye extends StatefulWidget {
  @override
  _ModernReservationPageState createState() => _ModernReservationPageState();
}

class _ModernReservationPageState extends State<ModernReservationPageEnploye> {
  // Etapes de réservation
  final int _totalSteps = 4;
  int _currentStep = 0;

  // Ajouter dans la section des variables d'état de la classe
  // Dans la section des variables d'état de votre classe
  int selectedDepositPercentage = 30; // Initialiser avec une valeur par défaut (10%)
  double? depositAmount; // Garder comme nullable mais l'initialiser dans calculateDepositAmounts()
  String paymentMethod = 'Espèces'; // Valeur par défaut pour le moyen de paiement

  // Dates de réservation
  DateTime? checkInDate;
  DateTime? checkOutDate;

  // Informations sur la chambre
  List<Room> availableRooms =[];
  Room? selectedRoom;
  bool isLoadingRooms = false;

  // Informations du client
  final _clientFormKey = GlobalKey<FormState>();
  String customerName = '';
  String customerEmail = '';
  String customerPhone = '';
  int numberOfGuests = 1;
  String specialRequests = '';

  // Contrôleur pour la recherche
  final TextEditingController _searchController = TextEditingController();
  Reservation? _foundReservation;
  bool _isSearching = false;
  String? _errorMessage;
  String? idadmin;

  // Liste des réservations
  List<Reservation> reservationsList =[];

  // Heures par défaut de l'hôtel
  String? _defaultCheckInTime;
  String? _defaultCheckOutTime;

  @override
  void initState() {
    super.initState();
    _loadAdminId();
    String? userId = idadmin;
    // Ne pas appeler fetchReservations() ici mais dans _loadAdminId()
  }
// ID de l'utilisateur connecté

  Future<void> _loadAdminId() async {
    idadmin = await getConnectedUserAdminId();
    if (idadmin != null) {
      // Charger les heures par défaut de l'hôtel
      await _loadDefaultHotelHours();
      fetchReservations();
    } else {
      _showErrorSnackBar('Erreur: Impossible de récupérer l\'ID administrateur');
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



  // Vérification de la disponibilité des chambres pour les dates sélectionnées
  Future<void> getAvailableRooms() async {
    if (checkInDate == null || checkOutDate == null) {
      _showErrorSnackBar('Veuillez sélectionner les dates de séjour');
      return;
    }

    if (checkOutDate!.isBefore(checkInDate!)) {
      _showErrorSnackBar('La date de départ doit être après la date d\'arrivée');
      return;
    }

    setState(() {
      isLoadingRooms = true;
      availableRooms = [];
      selectedRoom = null;
    });

    try {
      // Récupérer toutes les chambres disponibles
      final roomsSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('userId', isEqualTo: idadmin)
          .get();

      List<Room> allRooms = roomsSnapshot.docs.map((doc) {
        final data = doc.data();
        String imageValue = '';

        // Gestion des différents formats d'image
        if (data['image'] is Map) {
          final imageMap = data['image'] as Map<String, dynamic>;
          imageValue = imageMap['path'] ?? '';
        } else if (data['image'] is String) {
          imageValue = data['image'];
        }

        return Room(
          id: doc.id,
          number: data['number'],
          type: data['type'],
          status: data['status'],
          price: data['price'].toDouble(),
          capacity: data['capacity'],
          amenities: List<String>.from(data['amenities']),
          floor: data['floor'],
          image: imageValue,
          imageUrl: data['imageUrl'] ?? '',
          userId: idadmin ?? '', // Utiliser une chaîne vide si idadmin est null
        );
      }).toList();

      // Vérifier si chaque chambre a une réservation qui chevauche les dates sélectionnées
      for (Room room in allRooms) {
        bool isAvailable = await _isRoomAvailable(room.id, checkInDate!, checkOutDate!);

        if (isAvailable && (room.status == 'disponible' || room.status == 'occupée')) {
          availableRooms.add(room);
        }
      }

      // Trier les chambres par numéro
      availableRooms.sort((a, b) => _compareRoomNumbers(a.number, b.number));

      setState(() {
        isLoadingRooms = false;
        if (availableRooms.isEmpty) {
          _showInfoSnackBar('Aucune chambre disponible pour ces dates');
        } else {
          _currentStep = 1;
        }
      });
    } catch (e) {
      setState(() {
        isLoadingRooms = false;
      });
      _showErrorSnackBar('Erreur lors de la recherche de chambres disponibles');
    }
  }

  Future<bool> _isRoomAvailable(String roomId, DateTime checkIn, DateTime checkOut) async {
    // Vérifier les deux collections en parallèle pour de meilleures performances
    final reservationsFuture = FirebaseFirestore.instance
        .collection('reservations')
        .where('roomId', isEqualTo: roomId)
        .where('status', whereIn: ['réservée', 'Enregistré'])
        .get();

    final bookingsFuture = FirebaseFirestore.instance
        .collection('bookings')
        .where('roomId', isEqualTo: roomId)
        .where('status', whereIn: ['réservée','enregistré'])
        .get();

    final bookingsHOURFuture = FirebaseFirestore.instance
        .collection('bookingshours')
        .where('roomId', isEqualTo: roomId)
        .where('status', whereIn: ['réservée','hourly'])
        .get();

    // Attendre les trois requêtes
    final results = await Future.wait([reservationsFuture, bookingsFuture,bookingsHOURFuture]);
    final reservationsSnapshot = results[0];
    final bookingsSnapshot = results[1];
    final bookingshoursSnapshot = results[2];

    // Fonction pour vérifier les chevauchements dans une liste de documents
    bool hasOverlap(List<QueryDocumentSnapshot> docs) {
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        DateTime resCheckIn = (data['checkInDate'] as Timestamp).toDate();
        DateTime resCheckOut = (data['checkOutDate'] as Timestamp).toDate();

        // Vérification de chevauchement
        bool overlap = !(checkOut.isBefore(resCheckIn.subtract(const Duration(days: 0))) || checkIn.isAfter(resCheckOut.subtract(const Duration(days: 0))));

        if (overlap) {
          return true; // Il y a chevauchement
        }
      }
      return false;
    }

    // Vérifier les chevauchements dans les deux collections
    if (hasOverlap(reservationsSnapshot.docs) || hasOverlap(bookingsSnapshot.docs) || hasOverlap(bookingshoursSnapshot.docs)) {
      return false; // La chambre n'est pas disponible
    }

    return true; // La chambre est disponible
  }


  // Comparaison des numéros de chambre
  int _compareRoomNumbers(String a, String b) {
    final intA = int.tryParse(a);
    final intB = int.tryParse(b);

    if (intA != null && intB != null) {
      return intA.compareTo(intB);
    }
    return a.compareTo(b);
  }

  // Récupération des réservations existantes
  Future<void> fetchReservations() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: idadmin)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          reservationsList = [];
        });
        return;
      }

      setState(() {
        reservationsList = snapshot.docs.map((doc) {
          final data = doc.data();

          // Conversion des dates en DateTime avec vérification
          DateTime? checkInDate = data['checkInDate'] is Timestamp
              ? (data['checkInDate'] as Timestamp).toDate()
              : null;
          DateTime? checkOutDate = data['checkOutDate'] is Timestamp
              ? (data['checkOutDate'] as Timestamp).toDate()
              : null;

          // Assurez-vous que les dates sont valides
          if (checkInDate == null || checkOutDate == null) {
            return null; // Ignorer cette réservation si les dates sont invalides
          }

          return Reservation(
            id: doc.id,
            customerName: data['customerName'] ?? 'Inconnu',
            roomNumber: data['roomNumber'] ?? 'Inconnu',
            roomType: data['roomType'] ?? 'Type inconnu',
            checkInDate: checkInDate,
            checkOutDate: checkOutDate,
            status: data['status'] ?? 'Inconnu',
            roomId: data['roomId'] ?? '',
            reservationCode: data['reservationCode'] ?? 'Code inconnu',
            customerEmail: data['customerEmail'] ?? '',
            customerPhone: data['customerPhone'] ?? '',
            numberOfGuests: data['numberOfGuests'] ?? 1,
            specialRequests: data['specialRequests'] ?? '',
            numberOfNights: data['numberOfNights'] as int?, // Retrieve number of nights
            pricePerNight: data['pricePerNight'] as double?, // Retrieve price per night
            totalPrice: data['totalPrice'] as double?, // Retrieve total price

            // Nouveaux champs d'acompte
            depositPercentage: data['depositPercentage'] as int?,
            depositAmount: data['depositAmount'] as double?,
            paymentMethod: data['paymentMethod'] as String?,
            depositPaid: data['depositPaid'] as bool? ?? false,
          );
        }).whereType<Reservation>().toList(); // Utiliser whereType<Reservation>() pour filtrer et caster correctement
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des réservations: ${e.toString()}');
    }
  }



  // Création d'une nouvelle réservation
  Future<void> makeReservation() async {
    if (!_clientFormKey.currentState!.validate()) return;
    _clientFormKey.currentState!.save();

    if (selectedRoom == null || checkInDate == null || checkOutDate == null) {
      _showErrorSnackBar('Informations de réservation incomplètes');
      return;
    }
    if (selectedDepositPercentage == null || depositAmount == null) {
      // Afficher une erreur ou définir des valeurs par défaut
      return;
    }

    try {
      // Définir l'état de chargement à true avant de commencer les opérations
      setState(() {
        isLoadingRooms = true;
      });

      // Afficher un dialogue de chargement
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // L'utilisateur ne peut pas fermer le dialogue en cliquant à l'extérieur
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text('Création de la réservation en cours...')
                ],
              ),
            );
          },
        );
      }

      // Récupérer les paramètres de l'hôtel
      final settingsService = HotelSettingsService();
      final settings = await settingsService.getHotelSettings();

      final checkInTime = settings['checkInTime']; // "12:00"
      final checkOutTime = settings['checkOutTime']; // "10:00"

      // Convertir checkInTime et checkOutTime en objets Duration
      final checkInHour = int.parse(checkInTime.split(":")[0]);
      final checkInMinute = int.parse(checkInTime.split(":")[1]);
      final checkOutHour = int.parse(checkOutTime.split(":")[0]);
      final checkOutMinute = int.parse(checkOutTime.split(":")[1]);

      // Ajouter les heures d'enregistrement et de départ aux objets DateTime
      final finalCheckInDate = checkInDate!.add(Duration(hours: checkInHour, minutes: checkInMinute));
      final finalCheckOutDate = checkOutDate!.add(Duration(hours: checkOutHour, minutes: checkOutMinute));

      // Calculer le nombre de nuits
      final numberOfNights = finalCheckOutDate.difference(finalCheckInDate).inDays;
      final numberOfNightsCorrected = numberOfNights + (finalCheckOutDate.isAfter(finalCheckInDate) ? 1 : 0);

      // Récupérer le prix par nuit de la chambre sélectionnée
      final pricePerNight = selectedRoom!.price;

      // Calculer le prix total de la réservation
      final totalPrice = numberOfNightsCorrected * pricePerNight;

      // Génération d'un code de réservation unique
      String generatedReservationCode = await CodeGenerator.generateReservationCode();

      // Création des données de réservation pour l'impression du reçu
      final reservationData = {
        'roomId': selectedRoom!.id,
        'roomNumber': selectedRoom!.number,
        'roomType': selectedRoom!.type,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'numberOfGuests': numberOfGuests,
        'specialRequests': specialRequests,
        'checkInDate': finalCheckInDate,
        'checkOutDate': finalCheckOutDate,
        'numberOfNights': numberOfNightsCorrected,
        'pricePerNight': pricePerNight,
        'totalPrice': totalPrice,
        'depositPercentage': selectedDepositPercentage,
        'depositAmount': depositAmount,
        'paymentMethod': paymentMethod,
      };

      // Utilisation d'un batch pour effectuer toutes les opérations atomiquement
      final batch = FirebaseFirestore.instance.batch();

      // Création de la réservation
      final reservationRef = FirebaseFirestore.instance.collection('reservations').doc();
      batch.set(reservationRef, {
        'userId': idadmin,
        'roomId': selectedRoom!.id,
        'roomNumber': selectedRoom!.number,
        'roomType': selectedRoom!.type,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'numberOfGuests': numberOfGuests,
        'specialRequests': specialRequests,
        'checkInDate': finalCheckInDate,
        'checkOutDate': finalCheckOutDate,
        'reservationCode': generatedReservationCode,
        'status': 'réservée',
        'createdAt': FieldValue.serverTimestamp(),
        'numberOfNights': numberOfNightsCorrected,
        'pricePerNight': pricePerNight,
        'totalPrice': totalPrice,
        'paymentMethod': paymentMethod,
        'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',

        // Ajout des informations d'acompte
        'depositPercentage': selectedDepositPercentage,
        'depositAmount': depositAmount,
        'balanceDue': totalPrice - depositAmount!, // Solde restant à payer
        'depositPaid': true, // Indique que l'acompte a été payé
        'depositDate': FieldValue.serverTimestamp(), // Date du paiement de l'acompte
      });

      // Mise à jour du statut de la chambre à 'occupée'
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(selectedRoom!.id);
      batch.update(roomRef, {'datedisponible': finalCheckOutDate,});

      await batch.commit();

      //Création d'une transaction pour la réservation
      // Date du paiement
      final paymentDate = Timestamp.now();
      final transactionCode = await CodeGenerator.generateTransactionCode();
      // Créer la transaction pour le paiement en espèces
      if (depositAmount! > 0) {
        await FirebaseFirestore.instance.collection('transactions').add({
          'transactionCode': transactionCode,
          'bookingId': reservationRef.id,
          'roomId': selectedRoom!.id,
          'customerId': idadmin,
          'customerName': customerName,
          'amount': depositAmount,
          'discountRate': 0,
          'discountAmount': 0,
          'date': paymentDate,
          'type': 'payment',
          'paymentMethod': paymentMethod,
          'description': 'Acompte pour la réservation $generatedReservationCode',
          'createdAt': paymentDate,
          'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        });
      }

      // Fermer le dialogue de chargement
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      final printerService = PrinterService();
      await printerService.printReservationReceipt(
        reservationData: reservationData,
        reservationCode: generatedReservationCode,
        hotelSettings: settings,
      );

      // Désactiver l'état de chargement
      setState(() {
        isLoadingRooms = false;
      });

      _showSuccessSnackBar('Réservation effectuée avec succès! Code: $generatedReservationCode');

      // Rafraîchir les données
      fetchReservations();

      // Réinitialiser le formulaire et retourner à la première étape
      _resetReservationForm();

    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      setState(() {
        isLoadingRooms = false;
      });
      _showErrorSnackBar('Erreur lors de la création de la réservation: ${e.toString()}');
    }
  }


  // Réinitialisation du formulaire
  void _resetReservationForm() {
    if (mounted) {
      setState(() {
        _currentStep = 0;
        checkInDate = null;
        checkOutDate = null;
        selectedRoom = null;
        availableRooms =[];
        customerName = '';
        customerEmail = '';
        customerPhone = '';
        numberOfGuests = 1;
        specialRequests = '';
      });

      if (_clientFormKey.currentState != null) {
        _clientFormKey.currentState!.reset();
      }
    }
  }

  // Recherche d'une réservation par code
  void _searchReservation() async {
    final searchCode = _searchController.text.trim();
    if (searchCode.isEmpty) {
      _updateSearchState(error: 'Veuillez entrer un code de réservation');
      return;
    }

    _updateSearchState(reset: true);
    setState(() {
      _isSearching = true;
    });

    try {
      // Recherche du code avec ou sans préfixe 'RES'
      String searchQuery = searchCode.toUpperCase().startsWith('RES') ? searchCode : 'RES$searchCode';

      final querySnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: idadmin)
          .where('reservationCode', isEqualTo: searchQuery)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _updateSearchState(error: 'Aucune réservation trouvée avec ce code');
        return;
      }

      // Récupérer la réservation
      final doc = querySnapshot.docs.first;
      final data = doc.data();

      // Vérifier et convertir checkInDate & checkOutDate
      DateTime? checkInDate, checkOutDate;
      if (data['checkInDate'] is Timestamp) {
        checkInDate = (data['checkInDate'] as Timestamp).toDate();
      } else if (data['checkInDate'] is String) {
        checkInDate = DateTime.tryParse(data['checkInDate']);
      }

      if (data['checkOutDate'] is Timestamp) {
        checkOutDate = (data['checkOutDate'] as Timestamp).toDate();
      } else if (data['checkOutDate'] is String) {
        checkOutDate = DateTime.tryParse(data['checkOutDate']);
      }

      if (checkInDate == null || checkOutDate == null) {
        _updateSearchState(error: "Erreur de format des dates");
        return;
      }

      // Récupérer les détails de la chambre associée
      Map<String, dynamic>? roomData;
      if (data['roomId'] != null) {
        final roomSnapshot = await FirebaseFirestore.instance.collection('rooms').doc(data['roomId']).get();
        if (roomSnapshot.exists) {
          roomData = roomSnapshot.data();
        }
      }

      // Mettre à jour l'état avec les détails de la réservation
      _updateSearchState(
        reservation: Reservation(
          id: doc.id,
          reservationCode: data['reservationCode'],
          customerName: data['customerName'],
          roomNumber: data['roomNumber'],
          roomType: roomData?['type'] ?? 'Type inconnu',
          checkInDate: checkInDate,
          checkOutDate: checkOutDate,
          status: data['status'],
          roomId: data['roomId'] ?? '',
          customerEmail: data['customerEmail'] ?? '',
          customerPhone: data['customerPhone'] ?? '',
          numberOfGuests: data['numberOfGuests'] ?? 1,
          specialRequests: data['specialRequests'] ?? '',
          numberOfNights: data['numberOfNights'] as int?, // Retrieve number of nights
          pricePerNight: data['pricePerNight'] as double?, // Retrieve price per night
          totalPrice: data['totalPrice'] as double?, // Retrieve total price
          depositPercentage: data['depositPercentage'] as int?,
          depositAmount: data['depositAmount'] as double?,
          paymentMethod: data['paymentMethod'] as String?,
          depositPaid: data['depositPaid'] as bool? ?? false,
        ),
      );
    } catch (e) {
      _updateSearchState(error: 'Erreur lors de la recherche de la réservation : ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }


  // Mise à jour de l'état de recherche
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

  // Affichage des messages
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

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ================= WIDGETS DE L'INTERFACE =================

  // Construction de l'interface principale
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Main content area
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title section
                  const Text(
                    'Gestion des Réservations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stepper widget for reservation flow
                  Expanded(child: _buildReservationStepper()),

                  // Recent reservations list
                  if (_currentStep == 0)
                    Expanded(
                      child: buildRecentReservationsSection(),
                    ),
                ],
              ),
            ),
          ),

          // Right sidebar for search and details
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search reservation section
                  _buildSearchSection(),

                  const SizedBox(height: 20),

                  // Reservation details (when found)
                  if (_foundReservation != null)
                    _buildReservationDetails(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour le stepper de réservation
  Widget _buildReservationStepper() {
    return Stepper(
      type: StepperType.horizontal,
      currentStep: _currentStep,
      controlsBuilder: (context, details) {
        return Padding(
          padding: const EdgeInsets.only(top: 15.0), // Ajouter un espace de 15 pixels en haut
          child: Row(
            children: [
              if (_currentStep < _totalSteps - 1)
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  // Définir un style avec des dimensions plus grandes
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    minimumSize: const Size(150, 50), // Largeur minimale et hauteur
                    backgroundColor: Colors.deepPurple, // Couleur violette
                    foregroundColor: Colors.white, // Texte en blanc
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5), // Forme presque carrée (légèrement arrondie)
                    ),
                  ),
                  child: Text(_currentStep == 0
                      ? 'Vérifier disponibilité'
                      : 'Continuer'),
                ),
              if (_currentStep == _totalSteps - 1) // Dernière étape
                ElevatedButton(
                  onPressed: makeReservation,
                  // Style pour le bouton Réserver
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    minimumSize: const Size(150, 50), // Largeur minimale et hauteur
                    backgroundColor: Colors.deepPurple, // Couleur violette
                    foregroundColor: Colors.white, // Texte en blanc
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5), // Forme presque carrée (légèrement arrondie)
                    ),
                  ),
                  child: const Text('Réserver'),
                ),
              if (_currentStep > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0), // Augmenter l'espacement
                  child: TextButton(
                    onPressed: details.onStepCancel,
                    // Style pour le bouton Retour
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                      minimumSize: const Size(100, 45), // Largeur minimale et hauteur
                      backgroundColor: Colors.deepPurple[200], // Couleur violet clair pour le bouton retour
                      foregroundColor: Colors.white, // Texte en blanc
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5), // Forme presque carrée (légèrement arrondie)
                      ),
                    ),
                    child: const Text('Retour'),
                  ),
                ),
            ],
          ),
        );
      },
      onStepContinue: () {
        if (_currentStep == 0) {
          getAvailableRooms();
        } else if (_currentStep == 1 && selectedRoom != null) {
          setState(() {
            _currentStep = 2;
          });
        } else if (_currentStep == 2) {
          if (_clientFormKey.currentState!.validate()) {
            _clientFormKey.currentState!.save();
            setState(() {
              _currentStep = 3;
              // Calculer le montant total de la réservation
              calculateDepositAmounts();
            });
          }
        } else if (_currentStep == 3) {  // Étape acompte
          makeReservation();  // Appeler la réservation
        }
      },
      onStepCancel: () {
        if (_currentStep > 0) {
          setState(() {
            _currentStep--;
          });
        }
      },
      steps: [
        Step(
          title: const Text('Dates'),
          content: _buildDateSelectionStep(),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text('Chambre'),
          content: _buildRoomSelectionStep(),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text('Client'),
          content: _buildCustomerInfoStep(),
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text('Acompte'),
          content: _buildDepositStep(),
          isActive: _currentStep >= 3,
          state: _currentStep > 3 ? StepState.complete : StepState.indexed,
        ),
      ],
    );
  }

  // Étape 1: Sélection des dates
  Widget _buildDateSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date d\'arrivée'),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        // Appliquer automatiquement l'heure de check-in par défaut
                        DateTime dateWithTime = picked;
                        if (_defaultCheckInTime != null) {
                          final timeParts = _defaultCheckInTime!.split(':');
                          final hour = int.parse(timeParts[0]);
                          final minute = int.parse(timeParts[1]);
                          dateWithTime = DateTime(picked.year, picked.month, picked.day, hour, minute);
                        }
                        setState(() {
                          checkInDate = dateWithTime;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            checkInDate != null
                                ? DateFormat('dd/MM/yyyy').format(checkInDate!)
                                : 'Sélectionner',
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date de départ'),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: checkInDate?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 1)),
                        firstDate: checkInDate?.add(const Duration(days: 1)) ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        // Appliquer automatiquement l'heure de check-out par défaut
                        DateTime dateWithTime = picked;
                        if (_defaultCheckOutTime != null) {
                          final timeParts = _defaultCheckOutTime!.split(':');
                          final hour = int.parse(timeParts[0]);
                          final minute = int.parse(timeParts[1]);
                          dateWithTime = DateTime(picked.year, picked.month, picked.day, hour, minute);
                        }
                        setState(() {
                          checkOutDate = dateWithTime;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            checkOutDate != null
                                ? DateFormat('dd/MM/yyyy').format(checkOutDate!)
                                : 'Sélectionner',
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Étape 2: Sélection de la chambre
  Widget _buildRoomSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLoadingRooms)
          const Center(child: CircularProgressIndicator())
        else if (availableRooms.isEmpty)
          const Text('Aucune chambre disponible pour ces dates')
        else
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: availableRooms.length,
              itemBuilder: (context, index) {
                final room = availableRooms[index];
                return Card(
                  elevation: selectedRoom?.id == room.id ? 4 : 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: selectedRoom?.id == room.id ? Theme.of(context).primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(room.image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      'Chambre ${room.number} - ${room.type}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prix: ${room.price.toStringAsFixed(2)} FCFA/Nuit'),
                        Text('Capacité: ${room.capacity} personne(s)'),
                        Text('Étage: ${room.floor}'),
                        Wrap(
                          spacing: 4,
                          children: room.amenities.map((amenity) {
                            return Chip(
                              label: Text(amenity, style: const TextStyle(fontSize: 10)),
                              backgroundColor: Colors.grey[200],
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        selectedRoom = room;
                      });
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Étape 3: Informations du client
  Widget _buildCustomerInfoStep() {
    return Form(
      key: _clientFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Nom du client',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le nom du client';
              }
              return null;
            },
            onSaved: (value) {
              customerName = value!;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    // Make the email field optional by returning null if it's empty.
                    if (value == null || value.isEmpty) {
                      return null; // No error message for empty email
                    }
                    // You can add more sophisticated email format validation here if needed.
                    if (!value.contains('@')) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    customerEmail = value ?? ''; // Save the value, or an empty string if null
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Téléphone/Whatsapp',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le téléphone du client';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    customerPhone = value!;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Nombre d\'invités',
                    border: OutlineInputBorder(),
                  ),
                  value: numberOfGuests,
                  items: List.generate(10, (index) => index + 1)
                      .map((count) => DropdownMenuItem<int>(
                    value: count,
                    child: Text('$count ${count > 1 ? 'personnes' : 'personne'}'),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      numberOfGuests = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Demandes spéciales',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            onSaved: (value) {
              specialRequests = value ?? '';
            },
          ),
        ],
      ),
    );
  }

  void calculateDepositAmounts() {
    if (selectedRoom != null && checkInDate != null && checkOutDate != null) {
      // Calculer le nombre de nuits
      final nights = checkOutDate!.difference(checkInDate!).inDays;
      if (nights <= 0) {
        // Gérer le cas où les dates sont invalides
        depositAmount = 0.0;
        return;
      }

      // Calculer le montant total
      final totalAmount = selectedRoom!.price * nights;

      // Calculer le montant de l'acompte
      depositAmount = (totalAmount * selectedDepositPercentage / 100).roundToDouble();
    } else {
      // Initialiser à 0 si des données sont manquantes
      depositAmount = 0.0;
    }
  }
  //Etape 4
  Widget _buildDepositStep() {
    if (selectedRoom == null || checkInDate == null || checkOutDate == null) {
      return const Center(
        child: Text('Données insuffisantes pour calculer l\'acompte. Veuillez revenir aux étapes précédentes.'),
      );
    }

    // Calculer le montant total si pas encore fait
    if (depositAmount == null) {
      calculateDepositAmounts();
    }

    // Calculer le nombre de nuits
    final nights = checkOutDate!.difference(checkInDate!).inDays;
    if (nights <= 0) {
      return const Center(
        child: Text('Dates de séjour invalides. Veuillez revenir à l\'étape des dates.'),
      );
    }

    final totalAmount = selectedRoom!.price * nights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Récapitulatif de la réservation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Chambre: ${selectedRoom!.number} - ${selectedRoom!.type}'),
                    ),
                    Text('${selectedRoom!.price.toStringAsFixed(2)} FCFA/Nuit'),
                  ],
                ),
                Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Text('Durée du séjour:'),
                    ),
                    Text('$nights nuit(s)'),
                  ],
                ),
                Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Text('Montant total:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text('${totalAmount.toStringAsFixed(2)} FCFA', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Sélectionner le pourcentage d\'acompte',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [0,10, 20, 30, 40,50].map((percentage) {
            return OutlinedButton(
              onPressed: () {
                setState(() {
                  selectedDepositPercentage = percentage;
                  depositAmount = (totalAmount * percentage / 100).roundToDouble();
                });
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: selectedDepositPercentage == percentage
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                side: BorderSide(
                  color: selectedDepositPercentage == percentage
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                  width: selectedDepositPercentage == percentage ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                child: Text('$percentage%'),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 20),
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Montant de l\'acompte:', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 4),
                    Text(
                      '${depositAmount?.toStringAsFixed(2) ?? "0.00"} FCFA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Restant à payer:', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 4),
                    Text(
                      '${(totalAmount - (depositAmount ?? 0)).toStringAsFixed(2)} FCFA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Moyen de paiement',
            border: OutlineInputBorder(),
          ),
          value: 'Espèces',
          items: [
            DropdownMenuItem(value: 'Espèces', child: Text('Espèces')),
            DropdownMenuItem(value: 'Card', child: Text('Carte bancaire')),
            DropdownMenuItem(value: 'Virement', child: Text('Virement')),
            DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
          ],
          onChanged: (value) {
            // Gérer le changement du moyen de paiement
          },
        ),
      ],
    );
  }
  // Section de recherche de réservation
  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rechercher une réservation',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Code de réservation',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                // Ajouter un gestionnaire pour la touche Entrée
                onSubmitted: (value) {
                  if (!_isSearching) {
                    _searchReservation();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSearching ? null : _searchReservation,
              // Style pour le bouton Rechercher en violet et carré
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                backgroundColor: Colors.deepPurple, // Couleur violette
                foregroundColor: Colors.white, // Texte en blanc
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5), // Forme presque carrée
                ),
                minimumSize: const Size(120, 48), // Taille minimale pour assurer un aspect carré
              ),
              child: _isSearching
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Pour que l'indicateur soit blanc
                ),
              )
                  : const Text('Rechercher'),
            ),
          ],
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  // Affichage des détails d'une réservation trouvée
  Widget _buildReservationDetails() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec code de réservation et statut
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Réservation #${_foundReservation!.reservationCode}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_foundReservation!.status),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _foundReservation!.status.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (_foundReservation!.status != 'Annulée' && _foundReservation!.status != 'Enregistré' && _foundReservation!.status != 'Terminé')
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                tooltip: 'Modifier la réservation',
                                onPressed: () => _editReservation(_foundReservation!),
                              ),
                            IconButton(
                              icon: const Icon(Icons.print, color: Colors.white),
                              tooltip: 'Imprimer le reçu',
                              onPressed: () => _reprintReceipt(_foundReservation!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Contenu de la réservation
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Client
                        _buildSectionTitle('Informations Client', Icons.person),
                        const SizedBox(height: 8),
                        _infoRow('Nom', _foundReservation!.customerName),
                        if (_foundReservation!.customerEmail.isNotEmpty)
                          _infoRow('Email', _foundReservation!.customerEmail),
                        if (_foundReservation!.customerPhone.isNotEmpty)
                          _infoRow('Téléphone', _foundReservation!.customerPhone),
                        _infoRow('Nombre d\'invités', '${_foundReservation!.numberOfGuests}'),
                        
                        const Divider(height: 24),
                        
                        // Section Séjour
                        _buildSectionTitle('Détails du Séjour', Icons.hotel),
                        const SizedBox(height: 8),
                        _infoRow('Chambre', '${_foundReservation!.roomNumber} (${_foundReservation!.roomType})'),
                        _infoRow('Arrivée', DateFormat('dd/MM/yyyy').format(_foundReservation!.checkInDate)),
                        _infoRow('Départ', DateFormat('dd/MM/yyyy').format(_foundReservation!.checkOutDate)),
                        if (_foundReservation!.numberOfNights != null)
                          _infoRow('Nombre de nuits', '${_foundReservation!.numberOfNights}'),
                        
                        const Divider(height: 24),
                        
                        // Section Tarifs
                        _buildSectionTitle('Informations Tarifaires', Icons.payments),
                        const SizedBox(height: 8),
                        if (_foundReservation!.pricePerNight != null)
                          _infoRow('Prix par nuit', '${_foundReservation!.pricePerNight?.toStringAsFixed(2)} FCFA'),
                        if (_foundReservation!.totalPrice != null)
                          _infoRow('Prix total', '${_foundReservation!.totalPrice?.toStringAsFixed(2)} FCFA', isBold: true),
                        if (_foundReservation!.depositAmount != null && _foundReservation!.depositAmount != 0)
                          _infoRow('Acompte versé', '${_foundReservation!.depositAmount?.toStringAsFixed(2)} FCFA', color: Colors.green),
                        if (_foundReservation!.depositAmount != null && _foundReservation!.depositAmount != 0)
                          _infoRow('Reste à payer', '${(_foundReservation!.totalPrice! - _foundReservation!.depositAmount!).toStringAsFixed(2)} FCFA', color: Colors.orange, isBold: true),
                        
                        if (_foundReservation!.specialRequests.isNotEmpty) ...[
                          const Divider(height: 24),
                          _buildSectionTitle('Demandes Spéciales', Icons.comment),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              _foundReservation!.specialRequests,
                              style: TextStyle(color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        // Boutons d'action
                        if (_foundReservation!.status != 'Annulée' && _foundReservation!.status != 'Enregistré' && _foundReservation!.status != 'Terminé')
                          Column(
                            children: [
                              // Bouton de confirmation pour les réservations en attente
                              if (_foundReservation!.status == 'en attente')
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _confirmReservation(_foundReservation!),
                                    icon: const Icon(Icons.check_circle_outline, size: 24),
                                    label: const Text('CONFIRMER LA RÉSERVATION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_foundReservation!.status == 'en attente')
                                const SizedBox(height: 10),
                              
                              // Bouton d'enregistrement pour les réservations confirmées
                              if (_foundReservation!.status == 'réservée' || _foundReservation!.status == 'Confirmée')
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _checkInClient(_foundReservation!),
                                    icon: const Icon(Icons.login_outlined, size: 24),
                                    label: const Text('ENREGISTRER L\'ARRIVÉE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_foundReservation!.status == 'réservée' || _foundReservation!.status == 'Confirmée')
                                const SizedBox(height: 10),
                              
                              // Bouton d'annulation
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _cancelReservation(_foundReservation!),
                                  icon: const Icon(Icons.cancel_outlined, size: 24),
                                  label: const Text('ANNULER LA RÉSERVATION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red, width: 2),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher un titre de section
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  // Widget pour afficher une ligne d'information
  Widget _infoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Obtention de la couleur en fonction du statut de la réservation
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en attente':
        return Colors.orange;
      case 'réservée':
        return Colors.blue;
      case 'confirmée':
        return Colors.green;
      case 'annulée':
        return Colors.red;
      case 'enregistré':
        return Colors.teal;
      case 'terminé':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  // Section pour afficher les réservations récentes
  Widget buildRecentReservationsSection() {
    if (reservationsList.isEmpty) {
      return const Center(child: Text('Aucune réservation récente.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Réservations Récentes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                dataRowColor: MaterialStateProperty.all(Colors.white),
                border: TableBorder.all(color: Colors.grey[300]!),
                columns: const [
                  DataColumn(label: Text('Réservation', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Chambre', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Arrivée', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Départ', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Nuits', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Prix/nuit', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: reservationsList.map((reservation) {
                  return DataRow(
                    cells: [
                      DataCell(Text('#${reservation.reservationCode}',
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(reservation.customerName)),
                      DataCell(Text(reservation.roomNumber)),
                      DataCell(Text(DateFormat('dd/MM/yyyy').format(reservation.checkInDate))),
                      DataCell(Text(DateFormat('dd/MM/yyyy').format(reservation.checkOutDate))),
                      DataCell(Text(reservation.numberOfNights != null
                          ? '${reservation.numberOfNights}' : '-')),
                      DataCell(Text(reservation.pricePerNight != null
                          ? '${reservation.pricePerNight?.toStringAsFixed(2)} FCFA' : '-')),
                      DataCell(Text(reservation.totalPrice != null
                          ? '${reservation.totalPrice?.toStringAsFixed(2)} FCFA' : '-')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(reservation.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            reservation.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icône Modifier
                            if (reservation.status != 'Annulée' && reservation.status != 'Enregistré' && reservation.status != 'Terminé')
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                                tooltip: 'Modifier la réservation',
                                onPressed: () => _editReservation(reservation),
                              ),
                            // Icône Imprimer
                            IconButton(
                              icon: const Icon(Icons.print, color: Colors.blue, size: 20),
                              tooltip: 'Imprimer le reçu',
                              onPressed: () => _reprintReceipt(reservation),
                            ),
                            // Boutons d'actions conditionnels
                            if (reservation.status != 'Annulée' && reservation.status != 'Enregistré' && reservation.status != 'Terminé')
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Bouton de confirmation pour les réservations en attente
                                  if (reservation.status == 'en attente')
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                      tooltip: 'Confirmer la réservation',
                                      onPressed: () => _confirmReservation(reservation),
                                    ),
                                  if (reservation.status == 'réservée' || reservation.status == 'Confirmée')
                                    IconButton(
                                      icon: const Icon(Icons.login_outlined, color: Colors.green, size: 20),
                                      tooltip: 'Enregistrer l\'arrivée',
                                      onPressed: () => _checkInClient(reservation),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                                    tooltip: 'Annuler la réservation',
                                    onPressed: () => _cancelReservation(reservation),
                                  ),
                                ],
                              ),
                            // Bouton Supprimer (disponible pour toutes les réservations)
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                              tooltip: 'Supprimer la réservation',
                              onPressed: () => _deleteReservation(reservation),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editReservation(Reservation reservation) async {
    final customerNameController = TextEditingController(text: reservation.customerName);
    final customerPhoneController = TextEditingController(text: reservation.customerPhone);
    final numberOfGuestsController = TextEditingController(text: reservation.numberOfGuests.toString());
    final specialRequestsController = TextEditingController(text: reservation.specialRequests ?? '');
    final pricePerNightController = TextEditingController(text: reservation.pricePerNight?.toString() ?? '0');
    final depositPercentageController = TextEditingController(text: reservation.depositPercentage.toString());

    final settingsService = HotelSettingsService();
    final settings = await settingsService.getHotelSettings();

    final checkInTimeParts = settings['checkInTime'].split(":");
    final checkOutTimeParts = settings['checkOutTime'].split(":");

    final checkInHour = int.parse(checkInTimeParts[0]);
    final checkInMinute = int.parse(checkInTimeParts[1]);
    final checkOutHour = int.parse(checkOutTimeParts[0]);
    final checkOutMinute = int.parse(checkOutTimeParts[1]);

    DateTime _checkInDate = reservation.checkInDate ?? DateTime.now();
    DateTime _checkOutDate = reservation.checkOutDate ?? _checkInDate.add(const Duration(days: 1));

    Future<bool> _isRoomAvailable(String roomId, DateTime checkIn, DateTime checkOut, String? currentReservationId) async {
      // Vérifier dans les réservations
      // Supporte le cycle hôtelier standard (check-out 12h, check-in 12h)
      // Une chambre est disponible si le départ <= arrivée suivante
      final reservationsSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('roomId', isEqualTo: roomId)
          .where('status', whereIn: ['en attente', 'réservée', 'Confirmée', 'Enregistré'])
          .get();

      for (var doc in reservationsSnapshot.docs) {
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

      // Vérifier également dans les bookings (enregistrements actuels)
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('roomId', isEqualTo: roomId)
          .where('status', whereNotIn: ['Terminé', 'Annulé'])
          .get();

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
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            int numberOfNights = _checkOutDate.difference(_checkInDate).inDays;
            double totalAmount = numberOfNights * (double.tryParse(pricePerNightController.text) ?? 0);
            double depositPercentage = double.tryParse(depositPercentageController.text) ?? 0;
            double depositAmount = (depositPercentage / 100) * totalAmount;
            double balanceDue = totalAmount - depositAmount;

            Future<void> _selectCheckInDate(BuildContext context) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _checkInDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2030),
              );
              if (picked != null && picked != _checkInDate) {
                setState(() {
                  // Appliquer les heures par défaut de l'hôtel
                  _checkInDate = DateTime(picked.year, picked.month, picked.day, checkInHour, checkInMinute);
                });
              }
            }

            Future<void> _selectCheckOutDate(BuildContext context) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _checkOutDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2030),
              );
              if (picked != null && picked != _checkOutDate) {
                setState(() {
                  // Appliquer les heures par défaut de l'hôtel
                  _checkOutDate = DateTime(picked.year, picked.month, picked.day, checkOutHour, checkOutMinute);
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // En-tête moderne
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Modifier la réservation',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '#${reservation.reservationCode}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    
                    // Contenu scrollable
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Client
                            _buildSectionTitle('Informations Client', Icons.person),
                            const SizedBox(height: 12),
                            TextField(
                              controller: customerNameController,
                              decoration: InputDecoration(
                                labelText: 'Nom du client',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: customerPhoneController,
                              decoration: InputDecoration(
                                labelText: 'Téléphone du client',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: numberOfGuestsController,
                              decoration: InputDecoration(
                                labelText: 'Nombre de personnes',
                                prefixIcon: const Icon(Icons.group_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),
                            
                            // Section Séjour
                            _buildSectionTitle('Dates du Séjour', Icons.calendar_today),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => _selectCheckInDate(context),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade50,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.login, color: Colors.deepPurple.shade400),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Date d\'arrivée',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('dd/MM/yyyy').format(_checkInDate),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => _selectCheckOutDate(context),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade50,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.deepPurple.shade400),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Date de départ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('dd/MM/yyyy').format(_checkOutDate),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),
                            
                            // Section Tarifs
                            _buildSectionTitle('Informations Tarifaires', Icons.payments),
                            const SizedBox(height: 12),
                            TextField(
                              controller: pricePerNightController,
                              decoration: InputDecoration(
                                labelText: 'Prix par nuit (FCFA)',
                                prefixIcon: const Icon(Icons.attach_money),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: depositPercentageController,
                              decoration: InputDecoration(
                                labelText: 'Pourcentage d\'acompte (%)',
                                prefixIcon: const Icon(Icons.percent),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => setState(() {}),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Récapitulatif financier
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade50, Colors.purple.shade50],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.deepPurple.shade200),
                              ),
                              child: Column(
                                children: [
                                  _buildSummaryRow('Nombre de nuits', '$numberOfNights', Icons.nights_stay),
                                  const Divider(height: 16),
                                  _buildSummaryRow('Montant total', '${totalAmount.toStringAsFixed(2)} FCFA', Icons.account_balance_wallet, isBold: true),
                                  const Divider(height: 16),
                                  _buildSummaryRow('Acompte ($depositPercentage%)', '${depositAmount.toStringAsFixed(2)} FCFA', Icons.payment, color: Colors.green),
                                  const Divider(height: 16),
                                  _buildSummaryRow('Solde dû', '${balanceDue.toStringAsFixed(2)} FCFA', Icons.money_off, color: Colors.orange, isBold: true),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Section Demandes spéciales
                            _buildSectionTitle('Demandes Spéciales', Icons.comment),
                            const SizedBox(height: 12),
                            TextField(
                              controller: specialRequestsController,
                              decoration: InputDecoration(
                                labelText: 'Demandes spéciales (optionnel)',
                                prefixIcon: const Icon(Icons.message_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Bouton d'action
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final finalCheckInDate = DateTime(
                                _checkInDate.year, _checkInDate.month, _checkInDate.day,
                                checkInHour, checkInMinute
                            );
                            final finalCheckOutDate = DateTime(
                                _checkOutDate.year, _checkOutDate.month, _checkOutDate.day,
                                checkOutHour, checkOutMinute
                            );

                            bool isAvailable = await _isRoomAvailable(
                                reservation.roomId,
                                finalCheckInDate,
                                finalCheckOutDate,
                                reservation.id
                            );

                            if (!isAvailable) {
                              if (context.mounted) {
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
                                        'Cette chambre est déjà réservée ou occupée pour les dates sélectionnées. Veuillez choisir d\'autres dates.',
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

                            await FirebaseFirestore.instance.collection('reservations').doc(reservation.id).update({
                              'customerName': customerNameController.text,
                              'customerPhone': customerPhoneController.text,
                              'numberOfGuests': int.tryParse(numberOfGuestsController.text) ?? reservation.numberOfGuests,
                              'specialRequests': specialRequestsController.text,
                              'checkInDate': finalCheckInDate,
                              'checkOutDate': finalCheckOutDate,
                              'pricePerNight': double.tryParse(pricePerNightController.text) ?? 0,
                              'numberOfNights': numberOfNights,
                              'totalPrice': totalAmount,
                              'depositPercentage': depositPercentage,
                              'depositAmount': depositAmount,
                              'balanceDue': balanceDue,
                              'updatedAt': DateTime.now(),
                            });

                            // Mise à jour de la transaction associée
                            try {
                              final transactionSnapshot = await FirebaseFirestore.instance
                                  .collection('transactions')
                                  .where('bookingId', isEqualTo: reservation.id)
                                  .get();

                              if (transactionSnapshot.docs.isNotEmpty) {
                                final transactionDoc = transactionSnapshot.docs.first;
                                await FirebaseFirestore.instance.collection('transactions').doc(transactionDoc.id).update({
                                  'customerName': customerNameController.text,
                                  'amount': depositAmount,
                                  'description': 'Acompte mis à jour pour la réservation ${reservation.reservationCode}',
                                  'updatedAt': DateTime.now(),
                                });
                              }
                            } catch (e) {
                              print('Erreur lors de la mise à jour de la transaction: $e');
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Réservation mise à jour avec succès!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                              fetchReservations();
                              
                              // Mettre à jour _foundReservation si c'est celle affichée
                              if (_foundReservation?.id == reservation.id) {
                                _searchReservation();
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ENREGISTRER LES MODIFICATIONS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Widget helper pour les lignes de récapitulatif
  Widget _buildSummaryRow(String label, String value, IconData icon, {bool isBold = false, Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.deepPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }


  // Méthode pour confirmer une réservation en attente
  Future<void> _confirmReservation(Reservation reservation) async {
    // Afficher une boîte de dialogue de confirmation
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Text('Confirmer la réservation'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Voulez-vous confirmer la réservation suivante ?',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildInfoRow('Code', '#${reservation.reservationCode}'),
                _buildInfoRow('Client', reservation.customerName),
                _buildInfoRow('Chambre', reservation.roomNumber),
                _buildInfoRow('Arrivée', DateFormat('dd/MM/yyyy').format(reservation.checkInDate)),
                _buildInfoRow('Départ', DateFormat('dd/MM/yyyy').format(reservation.checkOutDate)),
                if (reservation.totalPrice != null)
                  _buildInfoRow('Prix total', '${reservation.totalPrice!.toStringAsFixed(2)} FCFA'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Mettre à jour le statut dans Firestore
        await FirebaseFirestore.instance
            .collection('reservations')
            .doc(reservation.id)
            .update({'status': 'réservée'});

        // Mettre à jour visuellement _foundReservation si c'est la réservation affichée
        if (_foundReservation?.id == reservation.id) {
          setState(() {
            _foundReservation = Reservation(
              id: reservation.id,
              reservationCode: reservation.reservationCode,
              roomId: reservation.roomId,
              roomNumber: reservation.roomNumber,
              roomType: reservation.roomType,
              customerName: reservation.customerName,
              customerEmail: reservation.customerEmail,
              customerPhone: reservation.customerPhone,
              numberOfGuests: reservation.numberOfGuests,
              specialRequests: reservation.specialRequests,
              checkInDate: reservation.checkInDate,
              checkOutDate: reservation.checkOutDate,
              status: 'réservée',
              numberOfNights: reservation.numberOfNights,
              pricePerNight: reservation.pricePerNight,
              totalPrice: reservation.totalPrice,
              depositPercentage: reservation.depositPercentage,
              depositAmount: reservation.depositAmount,
              paymentMethod: reservation.paymentMethod,
              depositPaid: reservation.depositPaid,
            );
          });
        }

        // Rafraîchir les données de la liste
        fetchReservations();

        // Afficher un message de succès
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Réservation #${reservation.reservationCode} confirmée avec succès'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la confirmation: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // Widget helper pour afficher les informations de réservation
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelReservation(Reservation reservation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annulation de la réservation'),
          content: const Text('Voulez-vous vraiment annuler cette réservation ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Fermer la boîte de dialogue
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () async {
                // Mettre à jour Firestore
                await FirebaseFirestore.instance
                    .collection('reservations')
                    .doc(reservation.id)
                    .update({'status': 'Annulée'});

                // Rafraîchir les données depuis Firestore
                fetchReservations();

                Navigator.pop(context); // Fermer la boîte de dialogue
              },
              child: const Text('Oui', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteReservation(Reservation reservation) async {
    // Afficher une boîte de dialogue de confirmation
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer définitivement la réservation #${reservation.reservationCode} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    // Si l'utilisateur annule, ne pas continuer
    if (confirmDelete != true) {
      return;
    }

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Supprimer la réservation de Firestore
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservation.id)
          .delete();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation supprimée avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Rafraîchir la liste des réservations
      fetchReservations(); // Assurez-vous que cette méthode existe pour recharger les données
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      Navigator.of(context).pop();

      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print('Erreur lors de la suppression de la réservation: $e');
    }
  }




// Méthode pour réimprimer le reçu
  Future<void> _reprintReceipt(Reservation reservation) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Récupérer les paramètres de l'hôtel
      final settingsService = HotelSettingsService();
      final settings = await settingsService.getHotelSettings();

      // Préparer les données de réservation pour l'impression
      final reservationData = {
        'roomId': reservation.roomId,
        'roomNumber': reservation.roomNumber,
        'roomType': reservation.roomType,
        'customerName': reservation.customerName,
        'customerEmail': reservation.customerEmail,
        'customerPhone': reservation.customerPhone,
        'numberOfGuests': reservation.numberOfGuests,
        'specialRequests': reservation.specialRequests,
        'checkInDate': reservation.checkInDate,
        'checkOutDate': reservation.checkOutDate,
        'numberOfNights': reservation.numberOfNights,
        'pricePerNight': reservation.pricePerNight,
        'totalPrice': reservation.totalPrice,
        'depositPercentage': reservation.depositPercentage,
        'depositAmount': reservation.depositAmount,
      };

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      // Imprimer le reçu
      final printerService = PrinterService();
      await printerService.printReservationReceipt(
        reservationData: reservationData,
        reservationCode: reservation.reservationCode,
        hotelSettings: settings,
      );

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impression du reçu en cours...'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      Navigator.of(context).pop();

      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'impression: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Helper widget to display info with an icon
  Widget _infoRowWithIcon(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(width: 4),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

// Function to handle client check-in
  Future<void> _checkInClient(Reservation reservation) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInFormEmployee(reservation: reservation),
      ),
    );
  }}

// Modèle pour une chambre


// Modèle pour une réservation
// Modèle pour une réservation
class Reservations {
  final String id;
  late final String customerName;
  final String roomNumber;
  final String roomType;
  late final DateTime checkInDate;
  late final DateTime checkOutDate;
  late final String status;
  final String roomId;
  final String reservationCode;
  final String customerEmail;
  late final String customerPhone;
  late final int numberOfGuests;
  late final String specialRequests;
  final int? numberOfNights;
  final double? pricePerNight;
  final double? totalPrice;

  // Nouveaux champs pour l'acompte
  final int? depositPercentage;
  final double? depositAmount;
  final String? paymentMethod;
  final bool? depositPaid;

  Reservations({
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
    // Nouveaux paramètres pour l'acompte
    this.depositPercentage,
    this.depositAmount,
    this.paymentMethod,
    this.depositPaid = false,
  });

  // Calculer le montant restant à payer
  double? get remainingAmount {
    if (totalPrice != null && depositAmount != null) {
      return totalPrice! - depositAmount!;
    }
    return null;
  }
}