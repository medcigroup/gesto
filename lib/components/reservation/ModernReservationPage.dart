import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../Screens/CheckInForm.dart';
import '../../config/HotelSettingsService.dart';
import '../../config/generationcode.dart';
import '../../config/printReservationReceipt.dart';
import '../../widgets/side_menu.dart';


class ModernReservationPage extends StatefulWidget {
  @override
  _ModernReservationPageState createState() => _ModernReservationPageState();
}

class _ModernReservationPageState extends State<ModernReservationPage> {
  // Etapes de réservation
  final int _totalSteps = 3;
  int _currentStep = 0;

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

  // Liste des réservations
  List<Reservation> reservationsList =[];

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  // ID de l'utilisateur connecté
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // Vérification de la disponibilité des chambres pour les dates sélectionnées
  Future<void> checkAvailableRooms() async {
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
      availableRooms =[];
      selectedRoom = null;
    });

    try {
      // 1. Récupérer toutes les chambres de l'utilisateur
      final roomsSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('userId', isEqualTo: userId)
          .get();

      // 2. Récupérer les réservations existantes pour cette période
      final reservationsSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .get();

      // Transformer les snapshots en listes d'objets
      List<Room> allRooms = roomsSnapshot.docs.map((doc) {
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
          datedisponible: (data['datedisponible'] as Timestamp?)?.toDate(), // Récupérer la date de disponibilité
        );
      }).toList();

      List<Reservation> existingReservations = reservationsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Reservation(
          id: doc.id,
          customerName: data['customerName'],
          roomNumber: data['roomNumber'],
          roomType: data['roomType'] ?? '',
          checkInDate: (data['checkInDate'] as Timestamp).toDate(),
          checkOutDate: (data['checkOutDate'] as Timestamp).toDate(),
          status: data['status'],
          roomId: data['roomId'],
          reservationCode: data['reservationCode'],
          customerEmail: data['customerEmail'] ?? '',
          customerPhone: data['customerPhone'] ?? '',
          numberOfGuests: data['numberOfGuests'] ?? 1,
          specialRequests: data['specialRequests'] ?? '',
        );
      }).toList();

      // 3. Filtrer les chambres disponibles
      for (Room room in allRooms) {
        bool isAvailable = true;

        // Vérifier si la date d'arrivée choisie est égale ou supérieure à la date de disponibilité de la chambre
        DateTime checkInDateOnly = DateTime(checkInDate!.year, checkInDate!.month, checkInDate!.day);
        DateTime availableDateOnly = DateTime(room.datedisponible!.year, room.datedisponible!.month, room.datedisponible!.day);

        if (checkInDateOnly.isBefore(availableDateOnly)) {
          isAvailable = false;
        }
        else {
          // Vérifier si la chambre est déjà réservée pour les dates demandées
          for (Reservation reservation in existingReservations) {
            if (reservation.roomId == room.id &&
                (reservation.status == 'réservée' || reservation.status == 'Confirmée')) {

              // Vérifier si les périodes se chevauchent
              bool overlap = (checkInDate!.isBefore(reservation.checkOutDate) ||
                  checkInDate!.isAtSameMomentAs(reservation.checkOutDate)) &&
                  (checkOutDate!.isAfter(reservation.checkInDate) ||
                      checkOutDate!.isAtSameMomentAs(reservation.checkInDate));

              if (overlap) {
                isAvailable = false;
                break;
              }
            }
          }
        }

        // Ajouter la chambre disponible à la liste
        if (isAvailable && (room.status == 'disponible' || room.status == 'réservée')) {
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
          // Passer à l'étape suivante si des chambres sont disponibles
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
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10) // Limiter aux 10 dernières réservations
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          reservationsList =[];
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
    _clientFormKey.currentState!.save(); // Correction: underscore manquant

    if (selectedRoom == null || checkInDate == null || checkOutDate == null) {
      _showErrorSnackBar('Informations de réservation incomplètes'); // Correction: underscore manquant
      return;
    }

    try {
      setState(() {
        isLoadingRooms = true;
      });

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
      };

      // Utilisation d'un batch pour effectuer toutes les opérations atomiquement
      final batch = FirebaseFirestore.instance.batch();

      // Création de la réservation
      final reservationRef = FirebaseFirestore.instance.collection('reservations').doc();
      batch.set(reservationRef, {
        'userId': userId,
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
      });

      // Mise à jour du statut de la chambre à 'occupée'
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(selectedRoom!.id);
      batch.update(roomRef, {'status': 'occupée'});

      await batch.commit();

      setState(() {
        isLoadingRooms = false;
      });

      _showSuccessSnackBar('Réservation effectuée avec succès! Code: $generatedReservationCode'); // Correction: underscore manquant

      final printerService = PrinterService();
      await printerService.printReservationReceipt(
        reservationData: reservationData,
        reservationCode: generatedReservationCode,
        hotelSettings: settings,
      );

      // Rafraîchir les données
      fetchReservations();

      // Réinitialiser le formulaire et retourner à la première étape
      _resetReservationForm(); // Correction: underscore manquant

    } catch (e) {
      setState(() {
        isLoadingRooms = false;
      });
      _showErrorSnackBar('Erreur lors de la création de la réservation: ${e.toString()}'); // Correction: underscore ajouté
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
          .where('userId', isEqualTo: userId)
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
      appBar: AppBar(
        title: Text('Réservation de Chambres'),
        centerTitle: true,
      ),
      drawer: const SideMenu(),
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
          return Row(
            children: [
              if (_currentStep < _totalSteps - 1)
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == 0
                      ? 'Vérifier disponibilité'
                      : 'Continuer'),
                ),
              if (_currentStep == _totalSteps - 1) // Dernière étape
                ElevatedButton(
                  onPressed: makeReservation,
                  child: const Text('Réserver'),
                ),
              if (_currentStep > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Retour'),
                  ),
                ),
            ],
          );
        },
        onStepContinue: () {
        if (_currentStep == 0) {
          checkAvailableRooms();
        } else if (_currentStep == 1 && selectedRoom != null) {
          setState(() {
            _currentStep = 2;
          });
        } else if (_currentStep == 2) {  // Vérifier si on est à la dernière étape
          makeReservation();  // Appeler directement la réservation
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
                        setState(() {
                          checkInDate = picked;
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
                        setState(() {
                          checkOutDate = picked;
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
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer l\'email du client';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    customerEmail = value!;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
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
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSearching ? null : _searchReservation,
              child: _isSearching
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Réservation #${_foundReservation!.reservationCode}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.blue),
                          tooltip: 'Imprimer le reçu',
                          onPressed: () => _reprintReceipt(_foundReservation!),
                        ),
                        Chip(
                          label: Text(_foundReservation!.status),
                          backgroundColor: _getStatusColor(_foundReservation!.status),
                        ),
                      ],
                    ),
                    const Divider(),
                    _infoRow('Client', _foundReservation!.customerName),
                    _infoRow('Chambre', '${_foundReservation!.roomNumber} (${_foundReservation!.roomType})'),
                    _infoRow('Arrivée', DateFormat('dd/MM/yyyy').format(_foundReservation!.checkInDate)),
                    _infoRow('Départ', DateFormat('dd/MM/yyyy').format(_foundReservation!.checkOutDate)),
                    _infoRow('Invités', '${_foundReservation!.numberOfGuests}'),
                    if (_foundReservation!.numberOfNights != null)
                      _infoRow('Nuits', '${_foundReservation!.numberOfNights}'),
                    if (_foundReservation!.pricePerNight != null)
                      _infoRow('Prix/nuit', '${_foundReservation!.pricePerNight?.toStringAsFixed(2)} FCFA'),
                    if (_foundReservation!.totalPrice != null)
                      _infoRow('Total', '${_foundReservation!.totalPrice?.toStringAsFixed(2)} FCFA'),
                    if (_foundReservation!.specialRequests.isNotEmpty)
                      _infoRow('Demandes', _foundReservation!.specialRequests),
                    if (_foundReservation!.customerEmail.isNotEmpty)
                      _infoRow('Email', _foundReservation!.customerEmail),
                    if (_foundReservation!.customerPhone.isNotEmpty)
                      _infoRow('Téléphone', _foundReservation!.customerPhone),
                    const SizedBox(height: 16),
                    if (_foundReservation!.status == 'réservée' || _foundReservation!.status == 'Confirmée')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _checkInClient(_foundReservation!),
                          icon: const Icon(Icons.login_outlined),
                          label: const Text('Enregistrer l\'arrivée'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[400],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher une ligne d'information
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Obtention de la couleur en fonction du statut de la réservation
  Color? _getStatusColor(String status) {
    switch (status) {
      case 'réservée':
        return Colors.orange[200];
      case 'Confirmée':
        return Colors.green[200];
      case 'Annulée':
        return Colors.red[200];
      case 'Terminée':
        return Colors.grey[300];
      default:
        return null;
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
          child: ListView.builder(
            itemCount: reservationsList.length,
            itemBuilder: (context, index) {
              final reservation = reservationsList[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Réservation #${reservation.reservationCode}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              // Bouton d'impression
                              IconButton(
                                icon: const Icon(Icons.print, color: Colors.blue),
                                tooltip: 'Imprimer le reçu',
                                onPressed: () => _reprintReceipt(reservation),
                              ),
                              const SizedBox(width: 8),
                              // Status chip
                              Chip(
                                label: Text(reservation.status),
                                backgroundColor: _getStatusColor(reservation.status),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _infoRowWithIcon(Icons.person_outline, 'Client:', reservation.customerName),
                      _infoRowWithIcon(Icons.hotel_outlined, 'Chambre:', reservation.roomNumber),
                      _infoRowWithIcon(Icons.calendar_today_outlined, 'Arrivée:', DateFormat('dd/MM/yyyy').format(reservation.checkInDate)),
                      _infoRowWithIcon(Icons.calendar_today_outlined, 'Départ:', DateFormat('dd/MM/yyyy').format(reservation.checkOutDate)),
                      if (reservation.numberOfNights != null)
                        _infoRowWithIcon(Icons.mode_night_rounded, 'Nuits:', '${reservation.numberOfNights}'),
                      if (reservation.pricePerNight != null)
                        _infoRowWithIcon(Icons.euro_symbol_outlined, 'Prix/nuit:', '${reservation.pricePerNight?.toStringAsFixed(2)} FCFA'),
                      if (reservation.totalPrice != null)
                        _infoRowWithIcon(Icons.money_outlined, 'Total:', '${reservation.totalPrice?.toStringAsFixed(2)} FCFA'),
                      const SizedBox(height: 16),
                      if (reservation.status == 'réservée' || reservation.status == 'Confirmée')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _checkInClient(reservation), // Pass the entire reservation object
                            icon: const Icon(Icons.login_outlined),
                            label: const Text('Enregistrer l\'arrivée'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[400],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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
        builder: (context) => CheckInForm(reservation: reservation),
      ),
    );
  }}

// Modèle pour une chambre
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
  final DateTime? datedisponible; // Ajouter le champ datedisponible

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
    this.datedisponible,
  });
}

// Modèle pour une réservation
// Modèle pour une réservation
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
  final int? numberOfNights; // Add this field
  final double? pricePerNight; // Add this field
  final double? totalPrice; // Add this field

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
  });
}