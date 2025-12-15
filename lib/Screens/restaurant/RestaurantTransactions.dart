import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/HotelSettingsService.dart';
import '../../config/getConnectedUserAdminId.dart';
import '../../config/restaurant_models.dart';
import 'ReceiptService.dart';


class RestaurantTransactions extends StatefulWidget {
  @override
  _RestaurantTransactionsState createState() => _RestaurantTransactionsState();
}

class _RestaurantTransactionsState extends State<RestaurantTransactions> {
  String? _userId;
  bool _isLoading = true;

  List<RestaurantOrder> _allTransactions = [];
  List<RestaurantOrder> _filteredTransactions = [];

  // Filtres
  TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all'; // all, en_cours, terminée, payée, annulée
  String _selectedCustomerType = 'all'; // all, hotel_guest, external
  String _selectedPaymentMethod = 'all'; // all, espèces, carte, chambre...
  DateTime? _startDate;
  DateTime? _endDate;

  // Cache des informations du personnel
  Map<String, Map<String, dynamic>> _staffCache = {};

  // ✅ NOUVEAU : Paramètres du restaurant
  final HotelSettingsService _hotelSettingsService = HotelSettingsService();
  String _restaurantName = 'Restaurant';
  String _restaurantAddress = '';
  String _restaurantPhone = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      _userId = await getConnectedUserAdminId();
      // ✅ NOUVEAU : Charger les paramètres du restaurant
      await _loadRestaurantSettings();
      await _loadTransactions();
    } catch (e) {
      print('❌ Erreur initialisation transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  // ✅ NOUVELLE MÉTHODE : Charger les paramètres du restaurant
  Future<void> _loadRestaurantSettings() async {
    try {
      final settings = await _hotelSettingsService.getHotelSettings();
      setState(() {
        _restaurantName = settings['restaurantName'] ?? settings['hotelName'] ?? 'Restaurant';
        _restaurantAddress = settings['restaurantAddress'] ?? settings['address'] ?? '';
        _restaurantPhone = settings['restaurantPhone'] ?? settings['phoneNumber'] ?? '';
      });
      print('✅ Paramètres restaurant chargés pour transactions: $_restaurantName');
    } catch (e) {
      print('⚠️ Erreur chargement paramètres restaurant: $e');
    }
  }

  Future<void> _loadTransactions() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();

      _allTransactions = snapshot.docs
          .map((doc) => RestaurantOrder.fromFirestore(doc))
          .toList();

      _applyFilters();

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erreur chargement transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _allTransactions.where((transaction) {
        // Recherche par numéro de transaction
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            transaction.id.toLowerCase().contains(searchQuery) ||
            transaction.tableNumber.toLowerCase().contains(searchQuery) ||
            (transaction.guestName?.toLowerCase().contains(searchQuery) ?? false) ||
            (transaction.roomNumber?.toLowerCase().contains(searchQuery) ?? false);

        // Filtre par statut
        final matchesStatus = _selectedStatus == 'all' || transaction.status == _selectedStatus;

        // Filtre par type de client
        final matchesCustomerType = _selectedCustomerType == 'all' ||
            transaction.customerType == _selectedCustomerType;

        // Filtre par méthode de paiement
        final matchesPaymentMethod = _selectedPaymentMethod == 'all' ||
            transaction.paymentMethod == _selectedPaymentMethod;

        // Filtre par date
        final matchesDateRange = (_startDate == null || transaction.createdAt.isAfter(_startDate!)) &&
            (_endDate == null || transaction.createdAt.isBefore(_endDate!));

        return matchesSearch && matchesStatus && matchesCustomerType &&
            matchesPaymentMethod && matchesDateRange;
      }).toList();
    });
  }

  Future<Map<String, dynamic>?> _getStaffInfo(String? waiterId) async {
    if (waiterId == null || waiterId.isEmpty) return null;

    // Vérifier le cache
    if (_staffCache.containsKey(waiterId)) {
      return _staffCache[waiterId];
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('staff')
          .doc(waiterId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final staffInfo = {
          'nom': data['nom'] ?? '',
          'prenom': data['prenom'] ?? '',
          'poste': data['poste'] ?? '',
          'departement': data['departement'] ?? '',
          'email': data['email'] ?? '',
          'photoUrl': data['photoUrl'],
        };

        // Mettre en cache
        _staffCache[waiterId] = staffInfo;
        return staffInfo;
      }
    } catch (e) {
      print('❌ Erreur chargement info serveur: $e');
    }

    return null;
  }

  // ✅ NOUVELLE MÉTHODE : Imprimer le reçu d'une transaction
  Future<void> _printReceipt(RestaurantOrder transaction) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Génération du reçu...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Générer le reçu
      await ReceiptService.generateReceiptWithStaff(
        order: transaction,
        restaurantName: _restaurantName,
        restaurantAddress: _restaurantAddress,
        restaurantPhone: _restaurantPhone,
        waiterId: transaction.waiterId,
        autoPrint: true,
      );

      // Fermer le dialogue de chargement
      Navigator.pop(context);

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('✅ Reçu généré avec succès'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      Navigator.pop(context);

      print('❌ Erreur génération reçu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de la génération du reçu: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
        title: Text('Transactions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          _buildStatsSummary(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                ? _buildEmptyState()
                : _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par N°, table, client, chambre...',
          prefixIcon: Icon(Icons.search, color: Colors.cyan),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'Tout',
              _selectedStatus == 'all' && _selectedCustomerType == 'all' && _selectedPaymentMethod == 'all',
                  () {
                setState(() {
                  _selectedStatus = 'all';
                  _selectedCustomerType = 'all';
                  _selectedPaymentMethod = 'all';
                  _applyFilters();
                });
              },
              Colors.grey,
            ),
            SizedBox(width: 8),
            _buildFilterChip(
              'En cours',
              _selectedStatus == 'en_cours',
                  () {
                setState(() {
                  _selectedStatus = _selectedStatus == 'en_cours' ? 'all' : 'en_cours';
                  _applyFilters();
                });
              },
              Colors.orange,
            ),
            SizedBox(width: 8),
            _buildFilterChip(
              'Payées',
              _selectedStatus == 'payée',
                  () {
                setState(() {
                  _selectedStatus = _selectedStatus == 'payée' ? 'all' : 'payée';
                  _applyFilters();
                });
              },
              Colors.green,
            ),
            SizedBox(width: 8),
            _buildFilterChip(
              'Clients Hôtel',
              _selectedCustomerType == 'hotel_guest',
                  () {
                setState(() {
                  _selectedCustomerType = _selectedCustomerType == 'hotel_guest' ? 'all' : 'hotel_guest';
                  _applyFilters();
                });
              },
              Colors.blue,
            ),
            SizedBox(width: 8),
            _buildFilterChip(
              'Externes',
              _selectedCustomerType == 'external',
                  () {
                setState(() {
                  _selectedCustomerType = _selectedCustomerType == 'external' ? 'all' : 'external';
                  _applyFilters();
                });
              },
              Colors.purple,
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.filter_list, color: Colors.cyan),
              onPressed: _showAdvancedFilters,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    final total = _filteredTransactions.fold<double>(
      0,
          (sum, transaction) => sum + transaction.total,
    );

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan, Colors.cyan.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '${_filteredTransactions.length}',
            'Transactions',
            Icons.receipt_long,
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.5)),
          _buildStatItem(
            '${total.toStringAsFixed(0)} F',
            'Total',
            Icons.attach_money,
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.5)),
          _buildStatItem(
            '${_filteredTransactions.isEmpty ? 0 : (total / _filteredTransactions.length).toStringAsFixed(0)} F',
            'Moyenne',
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucune transaction trouvée',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          SizedBox(height: 8),
          Text(
            'Modifiez vos filtres ou créez une nouvelle commande',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(RestaurantOrder transaction) {
    Color statusColor;
    IconData statusIcon;

    switch (transaction.status) {
      case 'en_cours':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'terminée':
        statusColor = Colors.blue;
        statusIcon = Icons.done;
        break;
      case 'payée':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'annulée':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTransactionDetails(transaction),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyan.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt, color: Colors.cyan, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'N° ${transaction.id.substring(0, 8).toUpperCase()}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 14, color: statusColor),
                                  SizedBox(width: 4),
                                  Text(
                                    transaction.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy à HH:mm').format(transaction.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${transaction.total.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (transaction.isRoomService == true)
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.room_service, size: 12, color: Colors.purple),
                              SizedBox(width: 4),
                              Text(
                                'Room',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTransactionInfo(
                      Icons.table_restaurant,
                      'Table',
                      transaction.tableNumber,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildTransactionInfo(
                      transaction.customerType == 'hotel_guest' ? Icons.hotel : Icons.person,
                      transaction.customerType == 'hotel_guest' ? 'Client Hôtel' : 'Client Externe',
                      transaction.guestName ?? 'N/A',
                      transaction.customerType == 'hotel_guest' ? Colors.blue : Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTransactionInfo(
                      Icons.shopping_bag,
                      'Articles',
                      '${transaction.items.length}',
                      Colors.purple,
                    ),
                  ),
                  Expanded(
                    child: _buildTransactionInfo(
                      Icons.payment,
                      'Paiement',
                      transaction.paymentMethod.isNotEmpty ? transaction.paymentMethod : 'N/A',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              if (transaction.roomNumber != null) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hotel, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Chambre ${transaction.roomNumber}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildTransactionInfo(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showTransactionDetails(RestaurantOrder transaction) async {
    // Charger les infos du serveur
    final staffInfo = await _getStaffInfo(transaction.waiterId);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              // En-tête
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyan, Colors.cyan.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Détails de la transaction',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'N° ${transaction.id.substring(0, 8).toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
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
                      // Informations générales
                      _buildDetailSection(
                        'Informations générales',
                        Icons.info_outline,
                        Colors.cyan,
                        [
                          _buildDetailRow('Date et heure', DateFormat('dd/MM/yyyy à HH:mm').format(transaction.createdAt)),
                          _buildDetailRow('Table', transaction.tableNumber),
                          _buildDetailRow('Statut', transaction.status.toUpperCase()),
                          _buildDetailRow('Type de client', transaction.customerType == 'hotel_guest' ? 'Client Hôtel' : 'Client Externe'),
                          if (transaction.isRoomService == true)
                            _buildDetailRow('Service', 'Service en chambre', isHighlighted: true),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Informations client
                      _buildDetailSection(
                        'Client',
                        Icons.person,
                        Colors.blue,
                        [
                          if (transaction.guestName != null)
                            _buildDetailRow('Nom', transaction.guestName!),
                          if (transaction.guestPhone != null)
                            _buildDetailRow('Téléphone', transaction.guestPhone!),
                          if (transaction.roomNumber != null)
                            _buildDetailRow('Chambre', transaction.roomNumber!),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Informations serveur
                      if (staffInfo != null) ...[
                        _buildDetailSection(
                          'Serveur',
                          Icons.person_pin,
                          Colors.purple,
                          [
                            _buildDetailRow('Nom complet', '${staffInfo['prenom']} ${staffInfo['nom']}'),
                            _buildDetailRow('Poste', staffInfo['poste'] ?? 'N/A'),
                            _buildDetailRow('Département', staffInfo['departement'] ?? 'N/A'),
                            if (staffInfo['email']?.isNotEmpty == true)
                              _buildDetailRow('Email', staffInfo['email']),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],

                      // Articles commandés
                      _buildDetailSection(
                        'Articles (${transaction.items.length})',
                        Icons.restaurant_menu,
                        Colors.orange,
                        transaction.items.map((item) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${item.quantity}x',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      if (item.specialInstructions != null)
                                        Text(
                                          item.specialInstructions!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${item.totalPrice.toStringAsFixed(0)} F',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 20),

                      // Récapitulatif financier
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Sous-total', '${transaction.subtotal.toStringAsFixed(0)} FCFA'),
                            _buildDetailRow('Taxe (${(transaction.tax / transaction.subtotal * 100).toStringAsFixed(0)}%)', '${transaction.tax.toStringAsFixed(0)} FCFA'),
                            _buildDetailRow('Service (${(transaction.serviceCharge / transaction.subtotal * 100).toStringAsFixed(0)}%)', '${transaction.serviceCharge.toStringAsFixed(0)} FCFA'),
                            Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TOTAL',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${transaction.total.toStringAsFixed(0)} FCFA',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Méthode de paiement
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.payment, color: Colors.blue),
                            SizedBox(width: 12),
                            Text(
                              'Paiement: ${transaction.paymentMethod}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (transaction.specialRequests != null && transaction.specialRequests!.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.note, color: Colors.amber.shade700, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Demandes spéciales',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      transaction.specialRequests!,
                                      style: TextStyle(color: Colors.amber.shade900),
                                    ),
                                  ],
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

              // ✅ NOUVEAU : Bouton d'impression du reçu
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Fermer le dialogue
                      _printReceipt(transaction); // Imprimer le reçu
                    },
                    icon: Icon(Icons.print, color: Colors.white),
                    label: Text(
                      'Imprimer le reçu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isHighlighted ? Colors.purple : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtres avancés',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Méthode de paiement
              Text('Méthode de paiement', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  'Tout',
                  'Espèces',
                  'Carte bancaire',
                  'Facturation chambre',
                  'Mobile Money',
                ].map((method) {
                  final value = method == 'Tout' ? 'all' : method;
                  return FilterChip(
                    label: Text(method),
                    selected: _selectedPaymentMethod == value,
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedPaymentMethod = value;
                      });
                    },
                  );
                }).toList(),
              ),

              SizedBox(height: 20),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatus = 'all';
                          _selectedCustomerType = 'all';
                          _selectedPaymentMethod = 'all';
                          _startDate = null;
                          _endDate = null;
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Réinitialiser'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Appliquer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}