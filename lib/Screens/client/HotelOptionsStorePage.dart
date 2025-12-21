import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../components/checkin/options_package_section.dart';
import '../../services/TicketGeneratorService.dart';
import '../../models/OptionPurchase.dart';
import '../../config/getConnectedUserAdminId.dart';
import '../../config/generationcode.dart';
import 'package:intl/intl.dart';

class HotelOptionsStorePage extends StatefulWidget {
  final String? hotelId;
  final String? bookingId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? roomNumber;

  const HotelOptionsStorePage({
    Key? key,
    this.hotelId,
    this.bookingId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.roomNumber,
  }) : super(key: key);

  @override
  _HotelOptionsStorePageState createState() => _HotelOptionsStorePageState();
}

class _HotelOptionsStorePageState extends State<HotelOptionsStorePage> with SingleTickerProviderStateMixin {
  List<HotelPackage> _availableOptions = [];
  List<HotelPackage> _selectedOptions = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String _selectedCategory = 'all';
  String _paymentMethod = 'Espèces';
  
  // Onglets et historique
  late TabController _tabController;
  List<OptionPurchase> _purchaseHistory = [];
  bool _isLoadingHistory = false;
  
  // Stocker la période sélectionnée et la quantité pour chaque option
  Map<String, String> _selectedPeriods = {}; // optionId -> 'hour'|'day'|'week'|'month'
  Map<String, int> _selectedQuantities = {}; // optionId -> quantité
  
  // Pour clients avec réservation
  List<Map<String, dynamic>> _activeBookings = [];
  Map<String, dynamic>? _selectedBooking;
  bool _isLoadingBookings = false;
  String _clientType = 'booking'; // 'booking' ou 'external'
  
  // Pour clients externes
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roomNumberController = TextEditingController();

  // Catégories
  final List<Map<String, dynamic>> _categories = [
    {'key': 'all', 'name': 'Toutes', 'icon': Icons.grid_view, 'color': Colors.grey},
    {'key': 'breakfast', 'name': 'Restauration', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'key': 'amenities', 'name': 'Équipements', 'icon': Icons.pool, 'color': Colors.blue},
    {'key': 'services', 'name': 'Services', 'icon': Icons.room_service, 'color': Colors.green},
    {'key': 'transport', 'name': 'Transport', 'icon': Icons.airport_shuttle, 'color': Colors.purple},
    {'key': 'wellness', 'name': 'Bien-être', 'icon': Icons.spa, 'color': Colors.pink},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _purchaseHistory.isEmpty) {
        _loadPurchaseHistory();
      }
    });
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    // Pré-remplir les informations si disponibles
    if (widget.customerName != null) {
      _nameController.text = widget.customerName!;
      _clientType = 'external';
    }
    if (widget.customerEmail != null) _emailController.text = widget.customerEmail!;
    if (widget.customerPhone != null) _phoneController.text = widget.customerPhone!;
    if (widget.roomNumber != null) _roomNumberController.text = widget.roomNumber!;
    
    // Si pas d'informations fournies, charger les réservations actives par défaut
    if (widget.customerName == null && widget.bookingId == null) {
      await _loadActiveBookings();
    }

    await _loadOptions();
  }
  
  Future<void> _loadActiveBookings() async {
    setState(() => _isLoadingBookings = true);
    
    try {
      String hotelId = widget.hotelId ?? await _getDefaultHotelId();
      final now = DateTime.now();
      
      List<Map<String, dynamic>> activeBookings = [];
      
      // Récupérer les réservations depuis la collection 'bookings'
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: hotelId)
          .where('status', whereIn: ['enregistré', 'hourly'])
          .get();
      
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final checkInDate = (data['checkInDate'] as Timestamp?)?.toDate();
        final checkOutDate = (data['checkOutDate'] as Timestamp?)?.toDate();
        
        // Vérifier si la réservation est active (date actuelle entre check-in et check-out)
        if (checkInDate != null && checkOutDate != null) {
          if (now.isAfter(checkInDate.subtract(Duration(hours: 1))) && 
              now.isBefore(checkOutDate.add(Duration(hours: 1)))) {
            activeBookings.add({
              'id': doc.id,
              'collection': 'bookings',
              'customerName': data['customerName'] ?? '',
              'customerEmail': data['customerEmail'] ?? '',
              'customerPhone': data['customerPhone'] ?? '',
              'roomNumber': data['roomNumber'] ?? '',
              'checkInDate': checkInDate,
              'checkOutDate': checkOutDate,
            });
          }
        }
      }
      
      // Récupérer les réservations depuis la collection 'reservations'
      final reservationsSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: hotelId)
          .where('status', whereIn: ['réservée', 'Enregistré'])
          .get();
      
      for (var doc in reservationsSnapshot.docs) {
        final data = doc.data();
        final checkInDate = (data['checkInDate'] as Timestamp?)?.toDate();
        final checkOutDate = (data['checkOutDate'] as Timestamp?)?.toDate();
        
        // Vérifier si la réservation est active
        if (checkInDate != null && checkOutDate != null) {
          if (now.isAfter(checkInDate.subtract(Duration(hours: 1))) && 
              now.isBefore(checkOutDate.add(Duration(hours: 1)))) {
            activeBookings.add({
              'id': doc.id,
              'collection': 'reservations',
              'customerName': data['customerName'] ?? '',
              'customerEmail': data['customerEmail'] ?? '',
              'customerPhone': data['customerPhone'] ?? '',
              'roomNumber': data['roomNumber'] ?? '',
              'checkInDate': checkInDate,
              'checkOutDate': checkOutDate,
            });
          }
        }
      }
      
      // Récupérer les réservations horaires depuis 'bookingshours'
      final hourlyBookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookingshours')
          .where('userId', isEqualTo: hotelId)
          .where('status', isEqualTo: 'hourly')
          .get();
      
      for (var doc in hourlyBookingsSnapshot.docs) {
        final data = doc.data();
        final checkInDate = (data['checkInDate'] as Timestamp?)?.toDate();
        final checkOutDate = (data['checkOutDate'] as Timestamp?)?.toDate();
        
        // Vérifier si la réservation est active
        if (checkInDate != null && checkOutDate != null) {
          if (now.isAfter(checkInDate.subtract(Duration(hours: 1))) && 
              now.isBefore(checkOutDate.add(Duration(hours: 1)))) {
            activeBookings.add({
              'id': doc.id,
              'collection': 'bookingshours',
              'customerName': data['customerName'] ?? '',
              'customerEmail': data['customerEmail'] ?? '',
              'customerPhone': data['customerPhone'] ?? '',
              'roomNumber': data['roomNumber'] ?? '',
              'checkInDate': checkInDate,
              'checkOutDate': checkOutDate,
            });
          }
        }
      }
      
      // Dédupliquer par numéro de chambre (éviter les doublons entre collections)
      final Map<String, Map<String, dynamic>> uniqueBookings = {};
      for (var booking in activeBookings) {
        final roomNumber = booking['roomNumber'] as String;
        final customerName = booking['customerName'] as String;
        final key = '$roomNumber-$customerName';
        
        // Garder seulement la première occurrence de chaque combinaison chambre+client
        if (!uniqueBookings.containsKey(key)) {
          uniqueBookings[key] = booking;
        }
      }
      
      // Convertir en liste et trier par date de check-in
      final uniqueList = uniqueBookings.values.toList();
      uniqueList.sort((a, b) => 
        (a['checkInDate'] as DateTime).compareTo(b['checkInDate'] as DateTime));
      
      if (mounted) {
        setState(() {
          _activeBookings = uniqueList;
          _isLoadingBookings = false;
        });
        
        print('✅ ${uniqueList.length} réservations actives uniques trouvées');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des réservations: $e');
      if (mounted) {
        setState(() => _isLoadingBookings = false);
      }
    }
  }

  Future<void> _loadOptions() async {
    try {
      String hotelId = widget.hotelId ?? await _getDefaultHotelId();
      
      final packages = await PackageService.getAllHotelPackages(hotelId);
      
      // Filtrer seulement les options payantes
      final paidOptions = packages.where((p) => !p.isIncluded && p.pricing.hasAnyPrice()).toList();
      
      if (mounted) {
        setState(() {
          _availableOptions = paidOptions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des options: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage('Erreur lors du chargement des options');
      }
    }
  }

  Future<String> _getDefaultHotelId() async {
    // Utiliser l'ID de l'utilisateur connecté (admin/manager)
    try {
      final userId = await getConnectedUserAdminId();
      
      if (userId != null) {
        return userId;
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'ID hôtel: $e');
    }
    
    throw Exception('Impossible de trouver l\'hôtel. Veuillez vous connecter.');
  }

  List<HotelPackage> get _filteredOptions {
    if (_selectedCategory == 'all') {
      return _availableOptions;
    }
    return _availableOptions.where((option) => option.category == _selectedCategory).toList();
  }

  double get _totalAmount {
    double total = 0;
    for (var option in _selectedOptions) {
      final period = _selectedPeriods[option.id] ?? 'day';
      final quantity = _selectedQuantities[option.id] ?? 1;
      
      double price = 0;
      switch (period) {
        case 'hour':
          price = option.pricing.pricePerHour ?? 0;
          break;
        case 'day':
          price = option.pricing.pricePerDay ?? 0;
          break;
        case 'week':
          price = option.pricing.pricePerWeek ?? 0;
          break;
        case 'month':
          price = option.pricing.pricePerMonth ?? 0;
          break;
      }
      
      total += price * quantity;
    }
    return total;
  }

  void _toggleOption(HotelPackage option) {
    setState(() {
      if (_selectedOptions.contains(option)) {
        _selectedOptions.remove(option);
        _selectedPeriods.remove(option.id);
        _selectedQuantities.remove(option.id);
      } else {
        _selectedOptions.add(option);
        // Déterminer la période par défaut selon les prix disponibles
        if (option.pricing.pricePerDay != null) {
          _selectedPeriods[option.id] = 'day';
        } else if (option.pricing.pricePerHour != null) {
          _selectedPeriods[option.id] = 'hour';
        } else if (option.pricing.pricePerWeek != null) {
          _selectedPeriods[option.id] = 'week';
        } else if (option.pricing.pricePerMonth != null) {
          _selectedPeriods[option.id] = 'month';
        }
        _selectedQuantities[option.id] = 1;
      }
    });
  }

  bool _isClientExternal() {
    return widget.bookingId == null;
  }

  Future<void> _processPurchase() async {
    if (_selectedOptions.isEmpty) {
      _showErrorMessage('Veuillez sélectionner au moins une option');
      return;
    }

    // Validation selon le type de client
    if (_clientType == 'booking') {
      if (_selectedBooking == null) {
        _showErrorMessage('Veuillez sélectionner un client');
        return;
      }
    } else if (_clientType == 'external') {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      _formKey.currentState!.save();
    }

    setState(() => _isProcessing = true);

    try {
      String hotelId = widget.hotelId ?? await _getDefaultHotelId();
      
      // Récupérer le nom de l'hôtel depuis hotelSettings ou users
      String hotelName = 'Hôtel';
      try {
        // Essayer d'abord hotelSettings
        final hotelSettingsDoc = await FirebaseFirestore.instance
            .collection('hotelSettings')
            .doc(hotelId)
            .get();
        
        if (hotelSettingsDoc.exists) {
          final hotelData = hotelSettingsDoc.data();
          hotelName = hotelData?['hotelName'] ?? 'Hôtel';
          print('✅ Nom de l\'hôtel récupéré depuis hotelSettings: $hotelName');
        } else {
          // Si hotelSettings n'existe pas, essayer users
          print('⚠️ hotelSettings non trouvé, recherche dans users...');
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(hotelId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data();
            hotelName = userData?['displayName'] ?? 
                       userData?['hotelName'] ?? 
                       userData?['businessName'] ?? 
                       userData?['name'] ?? 
                       'Hôtel';
            print('✅ Nom de l\'hôtel récupéré depuis users: $hotelName');
          } else {
            print('⚠️ Document users non trouvé pour hotelId: $hotelId');
          }
        }
      } catch (e) {
        print('❌ Erreur récupération nom hôtel: $e');
      }
      
      // Déterminer les informations du client selon le type
      String customerName;
      String customerEmail;
      String customerPhone;
      String? roomNumber;
      String? bookingId;
      
      if (_clientType == 'booking' && _selectedBooking != null) {
        customerName = _selectedBooking!['customerName'];
        customerEmail = _selectedBooking!['customerEmail'];
        customerPhone = _selectedBooking!['customerPhone'];
        roomNumber = _selectedBooking!['roomNumber'];
        bookingId = _selectedBooking!['id'];
      } else {
        customerName = _nameController.text;
        customerEmail = _emailController.text;
        customerPhone = _phoneController.text;
        roomNumber = _roomNumberController.text.isEmpty ? null : _roomNumberController.text;
        bookingId = null;
      }
      
      // Créer la liste des options achetées avec leurs détails
      List<PurchasedOption> purchasedOptions = _selectedOptions.map((option) {
        final period = _selectedPeriods[option.id] ?? 'day';
        final quantity = _selectedQuantities[option.id] ?? 1;
        
        double unitPrice = 0;
        switch (period) {
          case 'hour':
            unitPrice = option.pricing.pricePerHour ?? 0;
            break;
          case 'day':
            unitPrice = option.pricing.pricePerDay ?? 0;
            break;
          case 'week':
            unitPrice = option.pricing.pricePerWeek ?? 0;
            break;
          case 'month':
            unitPrice = option.pricing.pricePerMonth ?? 0;
            break;
        }
        
        return PurchasedOption(
          package: option,
          period: period,
          quantity: quantity,
          unitPrice: unitPrice,
          subtotal: unitPrice * quantity,
        );
      }).toList();
      
      // Créer l'achat
      final purchase = OptionPurchase(
        id: '',
        hotelId: hotelId,
        hotelName: hotelName,
        bookingId: bookingId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        roomNumber: roomNumber,
        purchasedOptions: purchasedOptions,
        totalAmount: _totalAmount,
        paymentMethod: _paymentMethod,
        purchaseDate: DateTime.now(),
        status: 'paid',
      );
      
      print('🎫 Génération ticket avec hotelName: ${purchase.hotelName}');

      // Sauvegarder l'achat dans Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('option_purchases')
          .add(purchase.toMap());

      // Créer une transaction financière pour les finances de l'hôtel
      final transactionCode = await CodeGenerator.generateTransactionCode();
      await FirebaseFirestore.instance.collection('transactions').add({
        'transactionCode': transactionCode,
        'bookingId': bookingId,
        'roomId': roomNumber != null ? 'Room-$roomNumber' : null,
        'customerId': hotelId, // ID de l'hôtel pour retrouver la transaction dans les finances
        'customerName': customerName,
        'amount': _totalAmount,
        'date': Timestamp.now(),
        'type': 'option_purchase',
        'paymentMethod': _paymentMethod,
        'description': 'Achat d\'options: ${_selectedOptions.map((o) => o.name).join(', ')}',
        'optionPurchaseId': docRef.id,
        'createdAt': Timestamp.now(),
        'createdBy': hotelId,
      });

      // Générer le ticket
      final ticketBytes = await TicketGeneratorService.generateOptionTicket(
        purchase.copyWith(id: docRef.id),
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        
        // Afficher le ticket
        await _showTicketDialog(ticketBytes, docRef.id);
        
        _showSuccessMessage('Achat effectué avec succès !');
        
        // Réinitialiser la sélection
        setState(() {
          _selectedOptions.clear();
          _selectedPeriods.clear();
          _selectedQuantities.clear();
          _selectedBooking = null;
          if (_clientType == 'external') {
            _nameController.clear();
            _emailController.clear();
            _phoneController.clear();
            _roomNumberController.clear();
          }
        });
      }
    } catch (e) {
      print('❌ Erreur lors du traitement de l\'achat: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorMessage('Erreur lors du traitement de l\'achat: ${e.toString()}');
      }
    }
  }

  Future<void> _showTicketDialog(dynamic ticketBytes, String purchaseId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.green),
            SizedBox(width: 12),
            Text('Ticket généré'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 20),
            Text(
              'Votre ticket a été généré avec succès !',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Numéro de transaction: ${purchaseId.substring(0, 8).toUpperCase()}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              if (ticketBytes is Uint8List) {
                await TicketGeneratorService.saveAndShareTicket(ticketBytes, purchaseId);
              }
            },
            icon: Icon(Icons.share),
            label: Text('Partager'),
          ),
          TextButton.icon(
            onPressed: () async {
              if (ticketBytes is Uint8List) {
                await TicketGeneratorService.printTicket(ticketBytes);
              }
            },
            icon: Icon(Icons.print),
            label: Text('Imprimer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Boutique d\'options',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(
              icon: Icon(Icons.shopping_cart),
              text: 'Acheter',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Historique',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Acheter
          _buildPurchaseTab(),
          // Onglet Historique
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildPurchaseTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    return Row(
      children: [
        // Partie gauche - Liste des options
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Filtres de catégories
              _buildCategoryFilter(),
              
              // Liste des options
              Expanded(
                child: _filteredOptions.isEmpty
                    ? _buildEmptyState()
                    : _buildOptionsList(),
              ),
            ],
          ),
        ),
        
        // Partie droite - Panier et informations client
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // En-tête du panier
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Votre sélection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_selectedOptions.length}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Formulaire client (toujours affiché pour choisir le type de client)
                          _buildClientForm(),
                          
                          Divider(height: 40),
                          
                          // Liste des options sélectionnées
                          _buildSelectedOptionsList(),
                          
                          SizedBox(height: 20),
                          
                          // Méthode de paiement
                          _buildPaymentMethod(),
                          
                          SizedBox(height: 20),
                          
                          // Résumé du total
                          _buildTotalSummary(),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bouton de validation
                  _buildCheckoutButton(),
                ],
              ),
            ),
          ],
        );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['key'];
          
          return Padding(
            padding: EdgeInsets.only(right: 12),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : category['color'],
                  ),
                  SizedBox(width: 6),
                  Text(category['name'] as String),
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category['key'] as String;
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: category['color'] as Color,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionsList() {
    return GridView.builder(
      padding: EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredOptions.length,
      itemBuilder: (context, index) {
        final option = _filteredOptions[index];
        final isSelected = _selectedOptions.contains(option);
        
        return _buildOptionCard(option, isSelected);
      },
    );
  }

  Widget _buildOptionCard(HotelPackage option, bool isSelected) {
    final categoryInfo = _categories.firstWhere(
      (c) => c['key'] == option.category,
      orElse: () => _categories[0],
    );

    return GestureDetector(
      onTap: () => _toggleOption(option),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.1 : 0.04),
              blurRadius: isSelected ? 10 : 4,
              offset: Offset(0, isSelected ? 3 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône et badge
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (categoryInfo['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconFromString(option.icon),
                          color: categoryInfo['color'] as Color,
                          size: 20,
                        ),
                      ),
                      Spacer(),
                      if (isSelected)
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Nom
                  Text(
                    option.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 4),
                  
                  // Description
                  Expanded(
                    child: Text(
                      option.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Prix
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monetization_on, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            option.pricing.getPricingInfo(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'Aucune option disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Les options payantes apparaîtront ici',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations client',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        
        // Sélecteur de type de client
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _clientType = 'booking';
                      _selectedBooking = null;
                      // Charger les réservations si pas encore fait
                      if (_activeBookings.isEmpty && !_isLoadingBookings) {
                        _loadActiveBookings();
                      }
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _clientType == 'booking' ? Theme.of(context).primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hotel_outlined,
                          color: _clientType == 'booking' ? Colors.white : Colors.grey[600],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Client hôtel',
                          style: TextStyle(
                            color: _clientType == 'booking' ? Colors.white : Colors.grey[600],
                            fontWeight: _clientType == 'booking' ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _clientType = 'external';
                      _selectedBooking = null;
                      _nameController.clear();
                      _emailController.clear();
                      _phoneController.clear();
                      _roomNumberController.clear();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _clientType == 'external' ? Theme.of(context).primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: _clientType == 'external' ? Colors.white : Colors.grey[600],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Client externe',
                          style: TextStyle(
                            color: _clientType == 'external' ? Colors.white : Colors.grey[600],
                            fontWeight: _clientType == 'external' ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 16),
        
        // Si type booking, afficher la liste des réservations actives
        if (_clientType == 'booking') ...[
          if (_isLoadingBookings)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_activeBookings.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucun client avec réservation active pour le moment',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sélectionner un client',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _activeBookings.length,
                    itemBuilder: (context, index) {
                      final booking = _activeBookings[index];
                      final isSelected = _selectedBooking?['id'] == booking['id'];
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBooking = booking;
                            _nameController.text = booking['customerName'];
                            _emailController.text = booking['customerEmail'];
                            _phoneController.text = booking['customerPhone'];
                            _roomNumberController.text = booking['roomNumber'];
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: isSelected ? Colors.white : Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking['customerName'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.hotel, size: 12, color: Colors.grey[600]),
                                        SizedBox(width: 4),
                                        Text(
                                          'Chambre ${booking['roomNumber']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            booking['customerPhone'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).primaryColor,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
        
        // Si type externe, afficher le formulaire
        if (_clientType == 'external') ...[
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet*',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 12),
                
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email (optionnel)',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 12),
                
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Téléphone (optionnel)',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                
                SizedBox(height: 12),
                
                TextFormField(
                  controller: _roomNumberController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de chambre (optionnel)',
                    prefixIcon: Icon(Icons.hotel),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedOptionsList() {
    if (_selectedOptions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(Icons.shopping_cart_outlined, size: 50, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text(
              'Aucune option sélectionnée',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options sélectionnées',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        
        ..._selectedOptions.map((option) {
          final period = _selectedPeriods[option.id] ?? 'day';
          final quantity = _selectedQuantities[option.id] ?? 1;
          
          double price = 0;
          switch (period) {
            case 'hour':
              price = option.pricing.pricePerHour ?? 0;
              break;
            case 'day':
              price = option.pricing.pricePerDay ?? 0;
              break;
            case 'week':
              price = option.pricing.pricePerWeek ?? 0;
              break;
            case 'month':
              price = option.pricing.pricePerMonth ?? 0;
              break;
          }
          
          final subtotal = price * quantity;
          
          // Construire la liste des périodes disponibles
          List<DropdownMenuItem<String>> availablePeriods = [];
          if (option.pricing.pricePerHour != null) {
            availablePeriods.add(DropdownMenuItem(value: 'hour', child: Text('Heure')));
          }
          if (option.pricing.pricePerDay != null) {
            availablePeriods.add(DropdownMenuItem(value: 'day', child: Text('Jour')));
          }
          if (option.pricing.pricePerWeek != null) {
            availablePeriods.add(DropdownMenuItem(value: 'week', child: Text('Semaine')));
          }
          if (option.pricing.pricePerMonth != null) {
            availablePeriods.add(DropdownMenuItem(value: 'month', child: Text('Mois')));
          }
          
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ligne 1: Icône, Nom et Bouton supprimer
                Row(
                  children: [
                    Icon(
                      _getIconFromString(option.icon),
                      size: 24,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: Colors.red),
                      onPressed: () => _toggleOption(option),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                // Ligne 2: Période et Quantité
                Row(
                  children: [
                    // Sélecteur de période
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: period,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        items: availablePeriods,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPeriods[option.id] = value;
                            });
                          }
                        },
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    
                    SizedBox(width: 8),
                    
                    // Contrôle quantité
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, size: 16),
                            onPressed: quantity > 1 ? () {
                              setState(() {
                                _selectedQuantities[option.id] = quantity - 1;
                              });
                            } : null,
                            padding: EdgeInsets.all(4),
                            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              quantity.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, size: 16),
                            onPressed: () {
                              setState(() {
                                _selectedQuantities[option.id] = quantity + 1;
                              });
                            },
                            padding: EdgeInsets.all(4),
                            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                // Ligne 3: Prix unitaire et sous-total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${price.toStringAsFixed(0)} FCFA × $quantity',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${subtotal.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthode de paiement',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        
        DropdownButtonFormField<String>(
          value: _paymentMethod,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.payment),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: [
            DropdownMenuItem(value: 'Espèces', child: Text('Espèces')),
            DropdownMenuItem(value: 'Carte bancaire', child: Text('Carte bancaire')),
            DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
            DropdownMenuItem(value: 'Virement', child: Text('Virement')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _paymentMethod = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTotalSummary() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total à payer',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '${_selectedOptions.length} option(s)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'FCFA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _selectedOptions.isEmpty || _isProcessing ? null : _processPurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Valider l\'achat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'pool': Icons.pool,
      'spa': Icons.spa,
      'wifi': Icons.wifi,
      'parking': Icons.local_parking,
      'gym': Icons.fitness_center,
      'breakfast': Icons.free_breakfast,
      'room_service': Icons.room_service,
      'airport_shuttle': Icons.airport_shuttle,
      'laundry': Icons.local_laundry_service,
      'concierge': Icons.support_agent,
      'business': Icons.business_center,
    };
    
    return iconMap[iconName] ?? Icons.hotel;
  }

  // ============= HISTORIQUE DES ACHATS =============

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return Center(child: CircularProgressIndicator());
    }

    if (_purchaseHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'Aucun achat enregistré',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Les achats effectués apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _purchaseHistory.length,
      itemBuilder: (context, index) {
        final purchase = _purchaseHistory[index];
        return _buildPurchaseCard(purchase);
      },
    );
  }

  Widget _buildPurchaseCard(OptionPurchase purchase) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.shopping_bag, color: Colors.green),
        ),
        title: Text(
          purchase.customerName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Chambre: ${purchase.roomNumber}'),
            Text(
              dateFormat.format(purchase.purchaseDate),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${purchase.totalAmount.toStringAsFixed(0)} FCFA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            Text(
              purchase.paymentMethod,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Liste des options achetées
                ...purchase.purchasedOptions.map((option) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${option.packageName} (${option.quantity}x)',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '${option.subtotal.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                SizedBox(height: 12),
                Divider(),
                
                // Informations supplémentaires
                _buildInfoRow('Email', purchase.customerEmail),
                _buildInfoRow('Téléphone', purchase.customerPhone),
                if (purchase.bookingId != null)
                  _buildInfoRow('Réservation', purchase.bookingId!),
                
                SizedBox(height: 16),
                
                // Bouton réimprimer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _reprintTicket(purchase),
                    icon: Icon(Icons.print),
                    label: Text('Réimprimer le ticket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPurchaseHistory() async {
    setState(() => _isLoadingHistory = true);
    
    try {
      String hotelId = widget.hotelId ?? await _getDefaultHotelId();
      
      final snapshot = await FirebaseFirestore.instance
          .collection('option_purchases')
          .where('hotelId', isEqualTo: hotelId)
          .orderBy('purchaseDate', descending: true)
          .limit(50)
          .get();
      
      final purchases = snapshot.docs
          .map((doc) => OptionPurchase.fromMap(doc.data(), doc.id))
          .toList();
      
      // Récupérer le nom de l'hôtel si absent
      String? hotelName;
      for (var purchase in purchases) {
        if (purchase.hotelName == null || purchase.hotelName!.isEmpty) {
          // Récupérer le nom de l'hôtel une seule fois
          if (hotelName == null) {
            try {
              final hotelSettingsDoc = await FirebaseFirestore.instance
                  .collection('hotelSettings')
                  .doc(hotelId)
                  .get();
              
              if (hotelSettingsDoc.exists) {
                hotelName = hotelSettingsDoc.data()?['hotelName'] ?? 'Hôtel';
              } else {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(hotelId)
                    .get();
                
                if (userDoc.exists) {
                  final userData = userDoc.data();
                  hotelName = userData?['displayName'] ?? 
                             userData?['hotelName'] ?? 
                             userData?['businessName'] ?? 
                             userData?['name'] ?? 
                             'Hôtel';
                }
              }
            } catch (e) {
              print('⚠️ Erreur récupération nom hôtel pour historique: $e');
              hotelName = 'Hôtel';
            }
          }
        }
      }
      
      // Mettre à jour les achats avec le nom de l'hôtel si nécessaire
      final updatedPurchases = purchases.map((purchase) {
        if (purchase.hotelName == null || purchase.hotelName!.isEmpty) {
          return purchase.copyWith(hotelName: hotelName ?? 'Hôtel');
        }
        return purchase;
      }).toList();
      
      if (mounted) {
        setState(() {
          _purchaseHistory = updatedPurchases;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement historique: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _reprintTicket(OptionPurchase purchase) async {
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.print, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text('Réimprimer le ticket'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text('Ticket PDF (80x80mm)'),
                subtitle: Text('Format pour imprimantes thermiques'),
                onTap: () async {
                  Navigator.pop(context);
                  final pdfBytes = await TicketGeneratorService.generateOptionTicket(purchase);
                  await TicketGeneratorService.saveAndShareTicket(pdfBytes, purchase.id);
                },
              ),
              ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Aperçu du ticket'),
                subtitle: Text('Voir avant d\'imprimer'),
                onTap: () async {
                  Navigator.pop(context);
                  final pdfBytes = await TicketGeneratorService.generateOptionTicket(purchase);
                  await Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async => pdfBytes,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.print),
                title: Text('Imprimer directement'),
                subtitle: Text('Envoyer à l\'imprimante'),
                onTap: () async {
                  Navigator.pop(context);
                  final pdfBytes = await TicketGeneratorService.generateOptionTicket(purchase);
                  await TicketGeneratorService.printTicket(pdfBytes);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Ticket envoyé à l\'imprimante'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ Erreur réimpression: $e');
      _showErrorMessage('Erreur lors de la réimpression du ticket');
    }
  }
}

