import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../config/generationcode.dart';
import '../../config/printReservationReceipt.dart';
import 'MyReservationsPage.dart';

class ModernClientBookingPage extends StatefulWidget {
  final String? preselectedHotelId;
  final String? preselectedHotelName;

  const ModernClientBookingPage({
    Key? key,
    this.preselectedHotelId,
    this.preselectedHotelName,
  }) : super(key: key);

  @override
  State<ModernClientBookingPage> createState() => _ModernClientBookingPageState();
}

class _ModernClientBookingPageState extends State<ModernClientBookingPage> {
  // Données client
  Map<String, dynamic>? _clientData;
  bool _isLoading = true;

  // Filtres de recherche
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _numberOfGuests = 2;
  String? _selectedHotelId;
  String? _selectedHotelName;
  String _selectedRoomType = 'Tous';
  double _minPrice = 0;
  double _maxPrice = 100000;
  RangeValues _priceRange = const RangeValues(0, 100000);

  // Résultats
  List<Map<String, dynamic>> _availableHotels = [];
  List<Map<String, dynamic>> _allRooms = [];
  List<Map<String, dynamic>> _filteredRooms = [];
  String? _selectedRoomId;
  bool _isSearchingRooms = false;

  // Tri
  String _sortBy = 'price_asc';

  final _specialRequestsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClientData();
    _loadAvailableHotels();

    // Pré-sélectionner l'hôtel si fourni
    if (widget.preselectedHotelId != null) {
      _selectedHotelId = widget.preselectedHotelId;
      _selectedHotelName = widget.preselectedHotelName;
    }
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _loadClientData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('clients')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            _clientData = doc.data();
            _isLoading = false;
          });
        }
      } else {
        // Utilisateur non connecté, on peut quand même afficher la page
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement données client: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAvailableHotels() async {
    try {
      print('🔍 Chargement des hôtels publics...');
      final hotelsSnapshot = await FirebaseFirestore.instance
          .collection('hotels')
          .where('isPublic', isEqualTo: true)
          .get();

      print('📊 Nombre d\'hôtels publics trouvés: ${hotelsSnapshot.docs.length}');

      if (mounted) {
        setState(() {
          _availableHotels = hotelsSnapshot.docs.map((doc) {
            final data = doc.data();
            final hotel = {
              'id': doc.id,
              'name': data['name'] ?? data['hotelName'] ?? 'Hôtel',
              'slug': data['slug'] ?? '',
              'userId': data['userId'] ?? '',
              'address': data['address'] ?? '',
              'isPublic': data['isPublic'] ?? false,
              'imageUrl': data['imageUrl'] ?? '',
              'description': data['description'] ?? '',
            };
            print('🏨 Hôtel: ${hotel['name']}, userId: ${hotel['userId']}');
            return hotel;
          }).toList();
        });
      }
    } catch (e) {
      print('❌ Erreur chargement hôtels: $e');
    }
  }

  Future<void> _searchAvailableRooms() async {
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner les dates de séjour')),
      );
      return;
    }

    if (_checkOutDate!.isBefore(_checkInDate!) || _checkOutDate!.isAtSameMomentAs(_checkInDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date de départ doit être après la date d\'arrivée')),
      );
      return;
    }

    setState(() {
      _isSearchingRooms = true;
      _allRooms = [];
      _filteredRooms = [];
      _selectedRoomId = null;
    });

    try {
      print('🔍 Début de la recherche de chambres...');
      print('📅 CheckIn: $_checkInDate, CheckOut: $_checkOutDate');
      print('👥 Nombre de personnes: $_numberOfGuests');

      List<Map<String, dynamic>> allAvailableRooms = [];

      // Si un hôtel spécifique est sélectionné
      if (_selectedHotelId != null) {
        print('🏨 Recherche pour l\'hôtel spécifique: $_selectedHotelId');
        final hotelDoc = await FirebaseFirestore.instance
            .collection('hotels')
            .doc(_selectedHotelId!)
            .get();

        final hotelData = hotelDoc.data();
        final hotelUserId = hotelData?['userId'];
        _selectedHotelName = hotelData?['name'] ?? 'Hôtel';

        print('🔑 Hotel userId: $hotelUserId');
        if (hotelUserId != null) {
          final rooms = await _getRoomsForHotel(hotelUserId, hotelData?['name'] ?? 'Hôtel');
          print('🛏️ Chambres trouvées pour cet hôtel: ${rooms.length}');
          allAvailableRooms.addAll(rooms);
        }
      } else {
        // Rechercher dans tous les hôtels publics
        print('🌐 Recherche dans tous les hôtels publics (${_availableHotels.length} hôtels)');
        for (var hotel in _availableHotels) {
          final hotelUserId = hotel['userId'];
          final hotelName = hotel['name'];
          print('🏨 Recherche dans: $hotelName (userId: $hotelUserId)');
          if (hotelUserId != null && hotelUserId.toString().isNotEmpty) {
            final rooms = await _getRoomsForHotel(hotelUserId, hotelName ?? 'Hôtel');
            print('  ➡️ ${rooms.length} chambres trouvées');
            allAvailableRooms.addAll(rooms);
          } else {
            print('  ⚠️ userId vide ou null pour $hotelName');
          }
        }
      }

      print('📊 Total chambres avant filtrage: ${allAvailableRooms.length}');

      if (mounted) {
        setState(() {
          _allRooms = allAvailableRooms;
          _applyFilters();
          _isSearchingRooms = false;
        });

        print('✅ Chambres après filtrage: ${_filteredRooms.length}');

        if (_filteredRooms.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune chambre disponible pour ces critères')),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur recherche chambres: $e');
      if (mounted) {
        setState(() => _isSearchingRooms = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getRoomsForHotel(String hotelUserId, String hotelName) async {
    List<Map<String, dynamic>> rooms = [];

    try {
      print('  🔍 _getRoomsForHotel pour: $hotelName (userId: $hotelUserId)');

      // Utiliser la méthode directe comme dans ModernReservationPage
      final roomsSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('userId', isEqualTo: hotelUserId)
          .get();

      print('  ✅ ${roomsSnapshot.docs.length} chambres trouvées');

      if (roomsSnapshot.docs.isEmpty) {
        print('  ℹ️ Aucune chambre trouvée pour cet hôtel');
        return rooms;
      }

      print('  🛏️ Traitement de ${roomsSnapshot.docs.length} chambres...');

      for (var roomDoc in roomsSnapshot.docs) {
        final roomData = roomDoc.data() as Map<String, dynamic>;
        final capacity = roomData['capacity'] as int? ?? 1;
        final status = roomData['status'] as String? ?? 'disponible';
        final roomNumber = roomData['number'] ?? roomData['roomNumber'] ?? 'N/A';

        print('    - Chambre $roomNumber: capacité=$capacity, status=$status');

        // Vérifier la capacité
        if (capacity < _numberOfGuests) {
          print('      ❌ Capacité insuffisante (${capacity} < $_numberOfGuests)');
          continue;
        }

        // Vérifier la disponibilité
        bool isAvailable = await _isRoomAvailable(roomDoc.id, hotelUserId, _checkInDate!, _checkOutDate!);
        print('      Disponible: $isAvailable');

        if (isAvailable && (status == 'disponible' || status == 'occupée')) {
          String imageValue = '';
          if (roomData['image'] is Map) {
            final imageMap = roomData['image'] as Map<String, dynamic>;
            imageValue = imageMap['path'] ?? '';
          } else if (roomData['image'] is String) {
            imageValue = roomData['image'];
          }

          final room = {
            'id': roomDoc.id,
            'userId': hotelUserId,
            'hotelName': hotelName,
            'roomNumber': roomNumber,
            'roomType': roomData['type'] ?? roomData['roomType'] ?? 'Standard',
            'capacity': capacity,
            'price': (roomData['price'] as num?)?.toDouble() ?? 0.0,
            'amenities': roomData['amenities'] ?? [],
            'imageUrl': roomData['imageUrl'] ?? imageValue,
            'status': status,
            'floor': roomData['floor'] ?? 0,
          };
          rooms.add(room);
          print('      ✅ Chambre ajoutée');
        } else {
          print('      ❌ Chambre non disponible ou status non valide');
        }
      }

      print('  📊 Résultat: ${rooms.length} chambres disponibles pour $hotelName');
    } catch (e) {
      print('  ❌ Erreur dans _getRoomsForHotel: $e');
    }

    return rooms;
  }

  Future<bool> _isRoomAvailable(String roomId, String hotelUserId, DateTime checkIn, DateTime checkOut) async {
    try {
      // Vérifier les trois collections en parallèle comme dans ModernReservationPage
      final reservationsFuture = FirebaseFirestore.instance
          .collection('reservations')
          .where('roomId', isEqualTo: roomId)
          .where('status', whereIn: ['réservée', 'Enregistré', 'en attente', 'confirmée'])
          .get();

      final bookingsFuture = FirebaseFirestore.instance
          .collection('bookings')
          .where('roomId', isEqualTo: roomId)
          .where('status', whereIn: ['réservée', 'enregistré', 'en attente', 'confirmée'])
          .get();

      final bookingsHoursFuture = FirebaseFirestore.instance
          .collection('bookingshours')
          .where('roomId', isEqualTo: roomId)
          .where('status', whereIn: ['réservée', 'hourly'])
          .get();

      // Attendre les trois requêtes
      final results = await Future.wait([reservationsFuture, bookingsFuture, bookingsHoursFuture]);
      final reservationsSnapshot = results[0];
      final bookingsSnapshot = results[1];
      final bookingsHoursSnapshot = results[2];

      // Fonction pour vérifier les chevauchements dans une liste de documents
      bool hasOverlap(List<QueryDocumentSnapshot> docs) {
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['checkInDate'] == null || data['checkOutDate'] == null) continue;

          DateTime resCheckIn = (data['checkInDate'] as Timestamp).toDate();
          DateTime resCheckOut = (data['checkOutDate'] as Timestamp).toDate();

          // Normaliser les dates à minuit pour comparaison précise
          final checkInNormalized = DateTime(checkIn.year, checkIn.month, checkIn.day);
          final checkOutNormalized = DateTime(checkOut.year, checkOut.month, checkOut.day);
          final resCheckInNormalized = DateTime(resCheckIn.year, resCheckIn.month, resCheckIn.day);
          final resCheckOutNormalized = DateTime(resCheckOut.year, resCheckOut.month, resCheckOut.day);

          // Il y a chevauchement si :
          // - La nouvelle arrivée est avant le départ existant ET
          // - Le nouveau départ est après l'arrivée existante
          // Note: Si checkOut == resCheckIn, pas de chevauchement (checkout le matin, checkin l'après-midi)
          bool overlap = checkInNormalized.isBefore(resCheckOutNormalized) && 
                         checkOutNormalized.isAfter(resCheckInNormalized);

          if (overlap) {
            print('      ⚠️ Chevauchement détecté: ${DateFormat('dd/MM').format(resCheckIn)}-${DateFormat('dd/MM').format(resCheckOut)}');
            return true; // Il y a chevauchement
          }
        }
        return false;
      }

      // Vérifier les chevauchements dans les trois collections
      if (hasOverlap(reservationsSnapshot.docs) || 
          hasOverlap(bookingsSnapshot.docs) || 
          hasOverlap(bookingsHoursSnapshot.docs)) {
        return false; // La chambre n'est pas disponible
      }

      return true; // La chambre est disponible
    } catch (e) {
      print('❌ Erreur vérification disponibilité: $e');
      // En cas d'erreur, considérer comme disponible pour ne pas bloquer l'affichage
      return true;
    }
  }

  Future<void> _printNewReservationReceipt(String reservationCode, Map<String, dynamic> selectedRoom) async {
    try {
      // Charger les paramètres de l'hôtel
      final hotelUserId = selectedRoom['userId'];
      final hotelDoc = await FirebaseFirestore.instance
          .collection('hotels')
          .where('userId', isEqualTo: hotelUserId)
          .limit(1)
          .get();

      Map<String, dynamic> hotelSettings = {
        'hotelName': selectedRoom['hotelName'] ?? 'Hôtel',
        'address': '',
        'phoneNumber': '',
        'email': '',
        'currency': 'FCFA',
      };

      if (hotelDoc.docs.isNotEmpty) {
        final hotelData = hotelDoc.docs.first.data();
        hotelSettings = {
          'hotelName': hotelData['name'] ?? hotelData['hotelName'] ?? 'Hôtel',
          'address': hotelData['address'] ?? '',
          'phoneNumber': hotelData['phone'] ?? hotelData['phoneNumber'] ?? '',
          'email': hotelData['email'] ?? '',
          'currency': hotelData['currency'] ?? 'FCFA',
        };
      }

      final numberOfNights = _checkOutDate!.difference(_checkInDate!).inDays;
      final pricePerNight = selectedRoom['price'] as num? ?? 0;
      final totalPrice = numberOfNights * pricePerNight;

      final reservationData = {
        'userId': selectedRoom['userId'],
        'roomId': _selectedRoomId,
        'roomNumber': selectedRoom['roomNumber'] ?? 'N/A',
        'roomType': selectedRoom['roomType'] ?? 'Standard',
        'customerName': _clientData!['fullName'] ?? '',
        'customerEmail': _clientData!['email'] ?? '',
        'customerPhone': _clientData!['phone'] ?? '',
        'numberOfGuests': _numberOfGuests,
        'specialRequests': _specialRequestsController.text.trim(),
        'checkInDate': _checkInDate!,
        'checkOutDate': _checkOutDate!,
        'reservationCode': reservationCode,
        'numberOfNights': numberOfNights,
        'pricePerNight': pricePerNight,
        'totalPrice': totalPrice,
        'hotelName': selectedRoom['hotelName'],
      };

      final printerService = PrinterService();
      await printerService.printReservationReceipt(
        reservationData: reservationData,
        reservationCode: reservationCode,
        hotelSettings: hotelSettings,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reçu généré avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erreur impression reçu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur impression: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allRooms);

    // Filtre par type de chambre
    if (_selectedRoomType != 'Tous') {
      filtered = filtered.where((room) => room['roomType'] == _selectedRoomType).toList();
    }

    // Filtre par prix
    filtered = filtered.where((room) {
      final price = room['price'] as double;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    // Tri
    switch (_sortBy) {
      case 'price_asc':
        filtered.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
        break;
      case 'price_desc':
        filtered.sort((a, b) => (b['price'] as double).compareTo(a['price'] as double));
        break;
      case 'capacity_asc':
        filtered.sort((a, b) => (a['capacity'] as int).compareTo(b['capacity'] as int));
        break;
      case 'capacity_desc':
        filtered.sort((a, b) => (b['capacity'] as int).compareTo(a['capacity'] as int));
        break;
    }

    setState(() {
      _filteredRooms = filtered;
    });
  }

  Future<void> _confirmBooking() async {
    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une chambre')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Afficher le dialogue de connexion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour effectuer une réservation'),
          backgroundColor: Colors.orange,
        ),
      );
      _showClientLoginDialog(context);
      return;
    }

    if (_clientData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Impossible de charger vos informations'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final selectedRoom = _filteredRooms.firstWhere((room) => room['id'] == _selectedRoomId);
      final numberOfNights = _checkOutDate!.difference(_checkInDate!).inDays;
      final pricePerNight = selectedRoom['price'] as num? ?? 0;
      final totalPrice = numberOfNights * pricePerNight;

      final reservationCode = await CodeGenerator.generateReservationCode();

      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': selectedRoom['userId'],
        'clientId': user.uid,
        'roomId': _selectedRoomId,
        'roomNumber': selectedRoom['roomNumber'] ?? 'N/A',
        'roomType': selectedRoom['roomType'] ?? 'Standard',
        'customerName': _clientData!['fullName'] ?? '',
        'customerEmail': _clientData!['email'] ?? '',
        'customerPhone': _clientData!['phone'] ?? '',
        'numberOfGuests': _numberOfGuests,
        'specialRequests': _specialRequestsController.text.trim(),
        'checkInDate': Timestamp.fromDate(_checkInDate!),
        'checkOutDate': Timestamp.fromDate(_checkOutDate!),
        'reservationCode': reservationCode,
        'status': 'en attente',
        'createdAt': FieldValue.serverTimestamp(),
        'numberOfNights': numberOfNights,
        'pricePerNight': pricePerNight,
        'totalPrice': totalPrice,
        'paymentMethod': 'En attente',
        'depositPercentage': 0,
        'depositAmount': 0,
        'balanceDue': totalPrice,
        'depositPaid': false,
      });

      if (mounted) {
        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Réservation confirmée !'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code de réservation:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reservationCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Vous recevrez une confirmation par email. L\'hôtel validera votre réservation sous peu.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Imprimer le reçu
                  await _printNewReservationReceipt(reservationCode, selectedRoom);
                },
                child: const Text('Imprimer le reçu'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _checkInDate = null;
                    _checkOutDate = null;
                    _selectedHotelId = null;
                    _selectedRoomId = null;
                    _allRooms = [];
                    _filteredRooms = [];
                    _numberOfGuests = 2;
                    _specialRequestsController.clear();
                  });
                },
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isUserLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Hero Header avec image de fond - Plus compact
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1A237E),
            actions: [
              if (isUserLoggedIn)
                IconButton(
                  icon: const Icon(Icons.book_online, color: Colors.white),
                  tooltip: 'Mes Réservations',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyReservationsPage()),
                  ),
                ),
              if (!isUserLoggedIn)
                TextButton.icon(
                  onPressed: () => _showClientLoginDialog(context),
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Connexion', style: TextStyle(color: Colors.white)),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Trouvez votre chambre',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=1200',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barre de recherche principale
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchCard(),
            ),
          ),

          // Filtres et résultats
          if (_allRooms.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredRooms.length} chambre${_filteredRooms.length > 1 ? 's' : ''} trouvée${_filteredRooms.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    _buildSortDropdown(),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _buildFiltersSection(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildRoomCard(_filteredRooms[index]),
                  childCount: _filteredRooms.length,
                ),
              ),
            ),
            // Espace en bas pour le FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],

          // État vide
          if (_allRooms.isEmpty && !_isSearchingRooms)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Recherchez une chambre',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sélectionnez vos dates et critères ci-dessus',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // Bouton flottant de réservation
      floatingActionButton: _selectedRoomId != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUserLoggedIn)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.info_outline, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Connexion requise',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                FloatingActionButton.extended(
                  onPressed: () => _showBookingConfirmation(),
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'Réserver',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildSearchCard() {
    final bool isHotelPreselected = widget.preselectedHotelId != null;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hôtel
            if (isHotelPreselected)
              // Affichage de l'hôtel pré-sélectionné (non modifiable)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hotel, color: Color(0xFF1A237E)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hôtel sélectionné',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedHotelName ?? 'Hôtel',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: Color(0xFF1A237E)),
                  ],
                ),
              )
            else
              // Sélection normale d'hôtel
              DropdownButtonFormField<String>(
                value: _selectedHotelId,
                decoration: InputDecoration(
                  labelText: 'Hôtel (optionnel)',
                  prefixIcon: const Icon(Icons.hotel, color: Color(0xFF1A237E)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tous les hôtels'),
                  ),
                  ..._availableHotels.map((hotel) {
                    return DropdownMenuItem<String>(
                      value: hotel['id'] as String?,
                      child: Text(hotel['name'] ?? 'Hôtel sans nom'),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedHotelId = value;
                    _allRooms = [];
                    _filteredRooms = [];
                    _selectedRoomId = null;
                  });
                },
              ),
            const SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    label: 'Arrivée',
                    date: _checkInDate,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _checkInDate = date);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateSelector(
                    label: 'Départ',
                    date: _checkOutDate,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _checkInDate?.add(const Duration(days: 1)) ?? DateTime.now(),
                        firstDate: _checkInDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _checkOutDate = date);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Personnes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, color: Color(0xFF1A237E)),
                      const SizedBox(width: 12),
                      Text(
                        '$_numberOfGuests personne${_numberOfGuests > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _numberOfGuests > 1
                            ? () => setState(() => _numberOfGuests--)
                            : null,
                        color: const Color(0xFF1A237E),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _numberOfGuests++),
                        color: const Color(0xFF1A237E),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bouton recherche
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSearchingRooms ? null : _searchAvailableRooms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: _isSearchingRooms
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 24),
                label: Text(
                  _isSearchingRooms ? 'Recherche...' : 'Rechercher',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector({required String label, DateTime? date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null ? DateFormat('dd MMM yyyy').format(date) : 'Sélectionner',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: date != null ? Colors.black : Colors.grey.shade400,
                  ),
                ),
                Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    // Extraire les types de chambres uniques
    final roomTypes = _allRooms.map((r) => r['roomType'] as String).toSet().toList();
    roomTypes.insert(0, 'Tous');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type de chambre - Horizontal scrollable
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: roomTypes.map((type) {
              final isSelected = _selectedRoomType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedRoomType = type;
                      _applyFilters();
                    });
                  },
                  selectedColor: const Color(0xFF1A237E),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  elevation: isSelected ? 4 : 1,
                  pressElevation: 2,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Prix - Compact
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Prix par nuit',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    '${_priceRange.start.round()} - ${_priceRange.end.round()} FCFA',
                    style: TextStyle(
                      color: const Color(0xFF1A237E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 100000,
                divisions: 20,
                activeColor: const Color(0xFF1A237E),
                labels: RangeLabels(
                  '${_priceRange.start.round()}',
                  '${_priceRange.end.round()}',
                ),
                onChanged: (values) {
                  setState(() {
                    _priceRange = values;
                    _applyFilters();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButton<String>(
      value: _sortBy,
      icon: const Icon(Icons.sort, color: Color(0xFF1A237E)),
      underline: Container(),
      items: const [
        DropdownMenuItem(value: 'price_asc', child: Text('Prix croissant')),
        DropdownMenuItem(value: 'price_desc', child: Text('Prix décroissant')),
        DropdownMenuItem(value: 'capacity_asc', child: Text('Capacité croissante')),
        DropdownMenuItem(value: 'capacity_desc', child: Text('Capacité décroissante')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _sortBy = value;
            _applyFilters();
          });
        }
      },
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final isSelected = _selectedRoomId == room['id'];
    final pricePerNight = room['price'] as double;
    final numberOfNights = _checkInDate != null && _checkOutDate != null
        ? _checkOutDate!.difference(_checkInDate!).inDays
        : 0;
    final totalPrice = numberOfNights * pricePerNight;
    final amenities = room['amenities'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1A237E) : Colors.transparent,
          width: 3,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedRoomId = room['id']),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - Plus petite et à gauche
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: room['imageUrl'] != null && room['imageUrl'].isNotEmpty
                      ? Image.network(
                          room['imageUrl'],
                          height: 160,
                          width: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 160,
                            width: 140,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey.shade300, Colors.grey.shade100],
                              ),
                            ),
                            child: Icon(Icons.hotel, size: 50, color: Colors.grey.shade400),
                          ),
                        )
                      : Container(
                          height: 160,
                          width: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey.shade300, Colors.grey.shade100],
                            ),
                          ),
                          child: Icon(Icons.hotel, size: 50, color: Colors.grey.shade400),
                        ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A237E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),

            // Détails - À droite
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre et Prix
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chambre ${room['roomNumber']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              Text(
                                room['roomType'] ?? 'Standard',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${pricePerNight.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            Text(
                              'FCFA/nuit',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Hôtel et Capacité
                    if (room['hotelName'] != null)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              room['hotelName'],
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${room['capacity']} pers.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Équipements - Plus compact
                    if (amenities.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: amenities.take(3).map((amenity) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              amenity.toString(),
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 10),

                    // Prix total
                    if (numberOfNights > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$numberOfNights nuit${numberOfNights > 1 ? 's' : ''}: ',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${totalPrice.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ],
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

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade300, Colors.grey.shade100],
        ),
      ),
      child: Icon(Icons.hotel, size: 80, color: Colors.grey.shade400),
    );
  }

  void _showBookingConfirmation() {
    if (_selectedRoomId == null) return;

    final selectedRoom = _filteredRooms.firstWhere((room) => room['id'] == _selectedRoomId);
    final numberOfNights = _checkOutDate!.difference(_checkInDate!).inDays;
    final pricePerNight = selectedRoom['price'] as double;
    final totalPrice = numberOfNights * pricePerNight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Confirmer la réservation',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Résumé
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chambre ${selectedRoom['roomNumber']} - ${selectedRoom['roomType']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('${selectedRoom['hotelName']}'),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.calendar_today, 'Arrivée', DateFormat('dd/MM/yyyy').format(_checkInDate!)),
                    _buildInfoRow(Icons.calendar_today, 'Départ', DateFormat('dd/MM/yyyy').format(_checkOutDate!)),
                    _buildInfoRow(Icons.people, 'Personnes', '$_numberOfGuests'),
                    _buildInfoRow(Icons.nights_stay, 'Nuits', '$numberOfNights'),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.attach_money, 'Prix/nuit', '${pricePerNight.toStringAsFixed(0)} FCFA'),
                    _buildInfoRow(Icons.attach_money, 'Total', '${totalPrice.toStringAsFixed(0)} FCFA',
                        isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Demandes spéciales
              TextField(
                controller: _specialRequestsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Demandes spéciales (optionnel)',
                  hintText: 'Ex: Chambre non-fumeur, vue mer, étage élevé...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Bouton confirmation
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmBooking();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: const Text(
                    'Confirmer et réserver',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade700)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Dialogue de connexion client
  void _showClientLoginDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Connexion Client',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Connexion réussie !'), backgroundColor: Colors.green),
                        );
                        setState(() {
                          _loadClientData();
                        });
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Se Connecter', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showClientRegisterDialog(context);
                  },
                  child: const Text('Pas encore de compte ? Créer un compte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialogue d'inscription client
  void _showClientRegisterDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Créer un Compte Client',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );
                        
                        // Enregistrer les informations client dans Firestore
                        await FirebaseFirestore.instance
                            .collection('clients')
                            .doc(userCredential.user!.uid)
                            .set({
                          'fullName': nameController.text.trim(),
                          'email': emailController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Compte créé avec succès !'), backgroundColor: Colors.green),
                          );
                          setState(() {
                            _loadClientData();
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Créer mon Compte', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showClientLoginDialog(context);
                    },
                    child: const Text('Déjà un compte ? Se connecter'),
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
