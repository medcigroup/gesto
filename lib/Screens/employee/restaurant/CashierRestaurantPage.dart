import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../../../config/HotelSettingsService.dart';
import '../../../config/getConnectedUserAdminId.dart';
import '../../../config/restaurant_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../restaurant/ReceiptService.dart';

/// Page principale de la caisse restaurant avec 3 onglets
class CashierRestaurantPage extends StatefulWidget {
  final int initialTab;

  const CashierRestaurantPage({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  _CashierRestaurantPageState createState() => _CashierRestaurantPageState();
}

class _CashierRestaurantPageState extends State<CashierRestaurantPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _userId;
  String? _currentUserId;
  bool _isLoading = true;

  String _restaurantName = 'Restaurant';
  String _restaurantAddress = '';
  String _restaurantPhone = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    ); // 3 onglets
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      _userId = await getConnectedUserAdminId();
      _currentUserId = FirebaseAuth.instance.currentUser?.uid;
      await _loadRestaurantSettings();
    } catch (e) {
      print('❌ Erreur initialisation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRestaurantSettings() async {
    try {
      final settings = await HotelSettingsService().getHotelSettings();
      setState(() {
        _restaurantName = settings['restaurantName'] ?? settings['hotelName'] ?? 'Restaurant';
        _restaurantAddress = settings['restaurantAddress'] ?? settings['address'] ?? '';
        _restaurantPhone = settings['restaurantPhone'] ?? settings['phoneNumber'] ?? '';
      });
    } catch (e) {
      print('⚠️ Erreur chargement paramètres: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Text('Caisse Restaurant'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(icon: Icon(Icons.add_shopping_cart), text: 'Nouvelle Commande'),
            Tab(icon: Icon(Icons.point_of_sale), text: 'Encaissements'),
            Tab(icon: Icon(Icons.assessment), text: 'Rapports'), // Nouvel onglet
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NewOrderTab(
            userId: _userId!,
            currentUserId: _currentUserId,
            restaurantName: _restaurantName,
            restaurantAddress: _restaurantAddress,
            restaurantPhone: _restaurantPhone,
          ),
          CashierTab(
            userId: _userId!,
            currentUserId: _currentUserId,
            restaurantName: _restaurantName,
            restaurantAddress: _restaurantAddress,
            restaurantPhone: _restaurantPhone,
          ),
          ReportsTab(
            userId: _userId!,
            restaurantName: _restaurantName,
            restaurantAddress: _restaurantAddress,
            restaurantPhone: _restaurantPhone,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ONGLET 1: NOUVELLE COMMANDE (Code inchangé)
// ============================================================================

class NewOrderTab extends StatefulWidget {
  final String userId;
  final String? currentUserId;
  final String restaurantName;
  final String restaurantAddress;
  final String restaurantPhone;

  const NewOrderTab({
    Key? key,
    required this.userId,
    required this.currentUserId,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantPhone,
  }) : super(key: key);

  @override
  _NewOrderTabState createState() => _NewOrderTabState();
}

class _NewOrderTabState extends State<NewOrderTab> {
  String _orderType = 'dine_in';
  String _customerType = 'external';

  RestaurantTable? _selectedTable;
  Map<String, dynamic>? _selectedHotelGuest;
  List<RestaurantTable> _availableTables = [];
  List<MenuItem> _menuItems = [];
  List<OrderItem> _cart = [];

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _specialRequestsController = TextEditingController();

  double _taxRate = 0.18;
  double _serviceChargeRate = 0.00;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadTables(), _loadMenuItems()]);
  }

  Future<void> _loadTables() async {
    try {
      _availableTables = await RestaurantService.getTables(widget.userId);
      setState(() {});
    } catch (e) {
      print('❌ Erreur chargement tables: $e');
    }
  }

  Future<void> _loadMenuItems() async {
    try {
      _menuItems = await RestaurantService.getMenuItems(widget.userId);
      setState(() {});
    } catch (e) {
      print('❌ Erreur chargement menu: $e');
    }
  }

  double get _subtotal => _cart.fold(0, (sum, item) => sum + item.totalPrice);
  double get _tax => _subtotal * _taxRate;
  double get _serviceCharge => _subtotal * _serviceChargeRate;
  double get _total => _subtotal + _tax + _serviceCharge;

  void _addToCart(MenuItem menuItem) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.menuItemId == menuItem.id);
      if (existingIndex >= 0) {
        final existing = _cart[existingIndex];
        _cart[existingIndex] = OrderItem(
          menuItemId: existing.menuItemId,
          name: existing.name,
          price: existing.price,
          quantity: existing.quantity + 1,
          specialInstructions: existing.specialInstructions,
          status: 'commandé',
          category: existing.category,
        );
      } else {
        _cart.add(OrderItem(
          menuItemId: menuItem.id,
          name: menuItem.name,
          price: menuItem.price,
          quantity: 1,
          status: 'commandé',
          category: menuItem.category,
        ));
      }
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      setState(() => _cart.removeAt(index));
      return;
    }
    setState(() {
      final item = _cart[index];
      _cart[index] = OrderItem(
        menuItemId: item.menuItemId,
        name: item.name,
        price: item.price,
        quantity: newQuantity,
        specialInstructions: item.specialInstructions,
        status: item.status,
        category: item.category,
      );
    });
  }

  Future<void> _createOrder() async {
    if (_cart.isEmpty) {
      _showErrorMessage('Le panier est vide');
      return;
    }
    if (_orderType == 'dine_in' && _selectedTable == null) {
      _showErrorMessage('Veuillez sélectionner une table');
      return;
    }
    if (_customerType == 'hotel_guest' && _selectedHotelGuest == null) {
      _showErrorMessage('Veuillez sélectionner un client d\'hôtel');
      return;
    }
    if (_orderType == 'room_service' && _selectedHotelGuest == null) {
      _showErrorMessage('Veuillez sélectionner un client pour le service en chambre');
      return;
    }

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
                Text('Création de la commande...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final order = RestaurantOrder(
        id: '',
        tableId: _selectedTable?.id ?? '',
        tableNumber: _orderType == 'takeaway'
            ? 'À EMPORTER'
            : (_selectedTable?.tableNumber ?? 'Service en chambre'),
        customerType: _customerType,
        hotelGuestId: _selectedHotelGuest != null ? _selectedHotelGuest!['id'] : null,
        guestName: _customerType == 'hotel_guest'
            ? (_selectedHotelGuest != null ? _selectedHotelGuest!['name'] : null)
            : _customerNameController.text,
        guestPhone: _customerType == 'hotel_guest'
            ? (_selectedHotelGuest != null ? _selectedHotelGuest!['phone'] : null)
            : _customerPhoneController.text,
        roomNumber: _selectedHotelGuest != null ? _selectedHotelGuest!['roomNumber'] : null,
        items: _cart,
        subtotal: _subtotal,
        tax: _tax,
        serviceCharge: _serviceCharge,
        total: _total,
        status: 'en_cours',
        paymentMethod: '',
        createdAt: DateTime.now(),
        completedAt: null,
        userId: widget.userId,
        waiterId: widget.currentUserId,
        specialRequests: _specialRequestsController.text.isEmpty ? null : _specialRequestsController.text,
        isRoomService: _orderType == 'room_service',
      );

      await RestaurantService.createOrder(order);
      Navigator.pop(context);
      _resetForm();
      _showSuccessMessage('✅ Commande créée avec succès');
    } catch (e) {
      Navigator.pop(context);
      print('❌ Erreur création commande: $e');
      _showErrorMessage('Erreur lors de la création de la commande');
    }
  }

  void _resetForm() {
    setState(() {
      _cart.clear();
      _selectedTable = null;
      _selectedHotelGuest = null;
      _customerNameController.clear();
      _customerPhoneController.clear();
      _specialRequestsController.clear();
      _orderType = 'dine_in';
      _customerType = 'external';
    });
  }

  void _showHotelGuestSearch() {
    showDialog(
      context: context,
      builder: (context) => _HotelGuestSearchDialog(
        userId: widget.userId,
        onGuestSelected: (guest) {
          setState(() => _selectedHotelGuest = guest);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildOrderTypeSelector(),
              _buildCustomerInfo(),
              Expanded(child: _buildMenuGrid()),
            ],
          ),
        ),
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(-2, 0),
              ),
            ],
          ),
          child: _buildCart(),
        ),
      ],
    );
  }

  Widget _buildOrderTypeSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type de commande', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTypeButton('Sur place', Icons.restaurant, 'dine_in', Colors.blue)),
              SizedBox(width: 8),
              Expanded(child: _buildTypeButton('À emporter', Icons.shopping_bag, 'takeaway', Colors.orange)),
              SizedBox(width: 8),
              Expanded(child: _buildTypeButton('En chambre', Icons.room_service, 'room_service', Colors.purple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, IconData icon, String type, Color color) {
    final isSelected = _orderType == type;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _orderType = type;
          if (type == 'room_service') _customerType = 'hotel_guest';
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      margin: EdgeInsets.only(top: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Informations client', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Spacer(),
              if (_orderType != 'room_service')
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'external', label: Text('Externe'), icon: Icon(Icons.person, size: 16)),
                    ButtonSegment(value: 'hotel_guest', label: Text('Hôtel'), icon: Icon(Icons.hotel, size: 16)),
                  ],
                  selected: {_customerType},
                  onSelectionChanged: (Set<String> selected) {
                    setState(() {
                      _customerType = selected.first;
                      _selectedHotelGuest = null;
                    });
                  },
                ),
            ],
          ),
          SizedBox(height: 12),
          if (_customerType == 'hotel_guest') ...[
            ElevatedButton.icon(
              onPressed: _showHotelGuestSearch,
              icon: Icon(Icons.search),
              label: Text(_selectedHotelGuest == null
                  ? 'Rechercher un client d\'hôtel'
                  : '${_selectedHotelGuest!['name']} - Ch. ${_selectedHotelGuest!['roomNumber']}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customerNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du client',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _customerPhoneController,
                    decoration: InputDecoration(
                      labelText: 'Téléphone',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
          ],
          if (_orderType == 'dine_in') ...[
            SizedBox(height: 12),
            DropdownButtonFormField<RestaurantTable>(
              value: _selectedTable,
              decoration: InputDecoration(
                labelText: 'Sélectionner une table',
                prefixIcon: Icon(Icons.table_restaurant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: _availableTables
                  .where((table) => table.status == 'libre')
                  .map((table) => DropdownMenuItem(
                value: table,
                child: Text('Table ${table.tableNumber} (${table.capacity} pers.)'),
              ))
                  .toList(),
              onChanged: (table) => setState(() => _selectedTable = table),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    if (_menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun article au menu', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final categories = _menuItems.map((item) => item.category).toSet().toList();

    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.teal,
              tabs: categories.map((cat) => Tab(text: cat)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: categories.map((category) {
                final items = _menuItems.where((item) =>
                item.category == category && item.isAvailable
                ).toList();

                return GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _buildMenuItem(items[index]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _addToCart(item),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imageUrl != null)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(item.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(Icons.restaurant, size: 40, color: Colors.teal),
                    ),
                  ),
                ),
              SizedBox(height: 8),
              Text(
                item.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${item.price.toStringAsFixed(0)} FCFA',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCart() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Panier (${_cart.length})',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              if (_cart.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () => setState(() => _cart.clear()),
                ),
            ],
          ),
        ),
        Expanded(
          child: _cart.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Panier vide', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
              : ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: _cart.length,
            itemBuilder: (context, index) {
              final item = _cart[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${item.price.toStringAsFixed(0)} FCFA',
                                style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: () => _updateQuantity(index, item.quantity - 1),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${item.quantity}',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () => _updateQuantity(index, item.quantity + 1),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${item.totalPrice.toStringAsFixed(0)} F',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.all(12),
          child: TextField(
            controller: _specialRequestsController,
            decoration: InputDecoration(
              labelText: 'Notes spéciales',
              hintText: 'Demandes particulières...',
              prefixIcon: Icon(Icons.note_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            maxLines: 2,
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              _buildTotalRow('Sous-total', _subtotal),
              _buildTotalRow('Taxe (${(_taxRate * 100).toStringAsFixed(0)}%)', _tax),
              _buildTotalRow('Service (${(_serviceChargeRate * 100).toStringAsFixed(0)}%)', _serviceCharge),
              Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    '${_total.toStringAsFixed(0)} FCFA',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _cart.isEmpty ? null : _createOrder,
            icon: Icon(Icons.add_shopping_cart, color: Colors.white),
            label: Text(
              'CRÉER LA COMMANDE',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: EdgeInsets.symmetric(vertical: 16),
              minimumSize: Size(double.infinity, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text('${amount.toStringAsFixed(0)} FCFA', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ============================================================================
// ONGLET 2: ENCAISSEMENTS (Code inchangé)
// ============================================================================

class CashierTab extends StatefulWidget {
  final String userId;
  final String? currentUserId;
  final String restaurantName;
  final String restaurantAddress;
  final String restaurantPhone;

  const CashierTab({
    Key? key,
    required this.userId,
    required this.currentUserId,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantPhone,
  }) : super(key: key);

  @override
  _CashierTabState createState() => _CashierTabState();
}

class _CashierTabState extends State<CashierTab> {
  String _selectedFilter = 'À encaisser';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Redessiner lors de la recherche
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('restaurant_orders')
        .where('userId', isEqualTo: widget.userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  List<RestaurantOrder> _applyFilters(List<RestaurantOrder> allOrders) {
    return allOrders.where((order) {
      final searchQuery = _searchController.text.toLowerCase();
      final matchesSearch = searchQuery.isEmpty ||
          order.tableNumber.toLowerCase().contains(searchQuery) ||
          (order.guestName?.toLowerCase().contains(searchQuery) ?? false) ||
          (order.roomNumber?.toLowerCase().contains(searchQuery) ?? false) ||
          order.id.toLowerCase().contains(searchQuery);

      final matchesFilter = _selectedFilter == 'Toutes' ||
          (_selectedFilter == 'En cours' && order.status == 'en_cours') ||
          (_selectedFilter == 'À encaisser' && order.status == 'terminée') ||
          (_selectedFilter == 'Payées' && order.status == 'payée');

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Map<String, dynamic> _calculateStats(List<RestaurantOrder> allOrders) {
    double totalRevenue = 0;
    int paidCount = 0;
    int pendingCount = 0;

    for (var order in allOrders) {
      if (order.status == 'payée') {
        totalRevenue += order.total;
        paidCount++;
      } else if (order.status == 'terminée') {
        pendingCount++;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'paidCount': paidCount,
      'pendingCount': pendingCount,
    };
  }

  Future<void> _processPayment(RestaurantOrder order, String paymentMethod) async {
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
                Text('Traitement du paiement...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await RestaurantService.updateOrderPayment(order.id, paymentMethod);

      if (order.isRoomService != true && order.tableId.isNotEmpty) {
        await RestaurantService.updateTableStatus(order.tableId, 'libre');
      }

      final updatedOrder = RestaurantOrder(
        id: order.id,
        tableId: order.tableId,
        tableNumber: order.tableNumber,
        customerType: order.customerType,
        hotelGuestId: order.hotelGuestId,
        guestName: order.guestName,
        guestPhone: order.guestPhone,
        roomNumber: order.roomNumber,
        items: order.items,
        subtotal: order.subtotal,
        tax: order.tax,
        serviceCharge: order.serviceCharge,
        total: order.total,
        status: 'payée',
        paymentMethod: paymentMethod,
        createdAt: order.createdAt,
        completedAt: DateTime.now(),
        userId: order.userId,
        waiterId: order.waiterId,
        specialRequests: order.specialRequests,
        isRoomService: order.isRoomService,
      );

      await ReceiptService.generateReceiptWithStaff(
        order: updatedOrder,
        restaurantName: widget.restaurantName,
        restaurantAddress: widget.restaurantAddress,
        restaurantPhone: widget.restaurantPhone,
        waiterId: order.waiterId,
        autoPrint: true,
      );

      Navigator.pop(context);
      // Plus besoin de _loadTodayOrders(), le StreamBuilder se met à jour automatiquement

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('✅ Paiement enregistré et reçu imprimé'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      print('❌ Erreur paiement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du paiement'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPaymentDialog(RestaurantOrder order) {
    showDialog(
      context: context,
      builder: (context) => _PaymentSelectionDialog(
        order: order,
        onPaymentSelected: (method) {
          Navigator.pop(context);
          _processPayment(order, method);
        },
      ),
    );
  }

  Future<void> _reprintReceipt(RestaurantOrder order) async {
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
                Text('Impression du reçu...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await ReceiptService.generateReceiptWithStaff(
        order: order,
        restaurantName: widget.restaurantName,
        restaurantAddress: widget.restaurantAddress,
        restaurantPhone: widget.restaurantPhone,
        waiterId: order.waiterId,
        autoPrint: true,
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('✅ Reçu réimprimé avec succès'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      print('❌ Erreur réimpression: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la réimpression'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}', style: TextStyle(color: Colors.red)),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final allOrders = snapshot.data!.docs
            .map((doc) => RestaurantOrder.fromFirestore(doc))
            .toList();

        final filteredOrders = _applyFilters(allOrders);
        final stats = _calculateStats(allOrders);

        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par N° commande, table, client, chambre...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Toutes'),
                        SizedBox(width: 8),
                        _buildFilterChip('En cours'),
                        SizedBox(width: 8),
                        _buildFilterChip('À encaisser'),
                        SizedBox(width: 8),
                        _buildFilterChip('Payées'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.teal.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('${filteredOrders.length}', 'Commandes', Icons.receipt_long),
                  Container(width: 1, height: 40, color: Colors.white.withOpacity(0.5)),
                  _buildStatItem('${stats['pendingCount']}', 'À encaisser', Icons.pending_actions),
                  Container(width: 1, height: 40, color: Colors.white.withOpacity(0.5)),
                  _buildStatItem('${stats['totalRevenue'].toStringAsFixed(0)} F', 'Encaissé', Icons.attach_money),
                ],
              ),
            ),
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Aucune commande', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  return _buildOrderCard(filteredOrders[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    Color color = Colors.grey;

    if (label == 'En cours') color = Colors.orange;
    if (label == 'À encaisser') color = Colors.blue;
    if (label == 'Payées') color = Colors.green;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
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

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
      ],
    );
  }

  Widget _buildOrderCard(RestaurantOrder order) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (order.status) {
      case 'en_cours':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'En cours';
        break;
      case 'terminée':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'Prête - À encaisser';
        break;
      case 'payée':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Payée';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = order.status;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: order.status == 'terminée' ? () => _showPaymentDialog(order) : null,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.table_restaurant, color: statusColor),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order.tableNumber == 'À EMPORTER'
                                  ? 'À EMPORTER'
                                  : 'Table ${order.tableNumber}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${order.id.substring(0, 8).toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          DateFormat('HH:mm').format(order.createdAt),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(order.guestName ?? 'Client'),
                  Spacer(),
                  Icon(Icons.restaurant_menu, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('${order.items.length} article(s)'),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    '${order.total.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if (order.status == 'terminée') ...[
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(order),
                  icon: Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    'ENCAISSER',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
              if (order.status == 'payée') ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Payé - ${order.paymentMethod}',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _reprintReceipt(order),
                      icon: Icon(Icons.print, size: 18, color: Colors.white),
                      label: Text(
                        'Réimprimer',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ONGLET 3: RAPPORTS JOURNALIERS (NOUVEAU)
// ============================================================================

class ReportsTab extends StatefulWidget {
  final String userId;
  final String restaurantName;
  final String restaurantAddress;
  final String restaurantPhone;

  const ReportsTab({
    Key? key,
    required this.userId,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantPhone,
  }) : super(key: key);

  @override
  _ReportsTabState createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  List<RestaurantOrder> _paidOrders = [];
  Map<String, WaiterStats> _waiterStats = {};
  Map<String, CategoryStats> _categoryStats = {};

  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _averageTicket = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .where('userId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'payée')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      _paidOrders = snapshot.docs.map((doc) => RestaurantOrder.fromFirestore(doc)).toList();

      _calculateStats();
    } catch (e) {
      print('❌ Erreur chargement rapports: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    _totalRevenue = 0;
    _totalOrders = _paidOrders.length;
    _waiterStats.clear();
    _categoryStats.clear();

    for (var order in _paidOrders) {
      _totalRevenue += order.total;

      // Stats par serveur
      final waiterId = order.waiterId ?? 'unknown';
      if (!_waiterStats.containsKey(waiterId)) {
        _waiterStats[waiterId] = WaiterStats(waiterId: waiterId);
      }
      _waiterStats[waiterId]!.addOrder(order);

      // Stats par catégorie
      for (var item in order.items) {
        if (!_categoryStats.containsKey(item.category)) {
          _categoryStats[item.category] = CategoryStats(category: item.category);
        }
        _categoryStats[item.category]!.addItem(item);
      }
    }

    _averageTicket = _totalOrders > 0 ? _totalRevenue / _totalOrders : 0;
  }

  Future<void> _printGeneralReport() async {
    try {
      await DailyReportService.generateGeneralReport(
        date: _selectedDate,
        orders: _paidOrders,
        totalRevenue: _totalRevenue,
        totalOrders: _totalOrders,
        averageTicket: _averageTicket,
        restaurantName: widget.restaurantName,
        restaurantAddress: widget.restaurantAddress,
        restaurantPhone: widget.restaurantPhone,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Rapport général imprimé'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur impression'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _printWaiterReport(String waiterId) async {
    final stats = _waiterStats[waiterId];
    if (stats == null) return;

    try {
      await DailyReportService.generateWaiterReport(
        date: _selectedDate,
        waiterId: waiterId,
        stats: stats,
        restaurantName: widget.restaurantName,
        restaurantAddress: widget.restaurantAddress,
        restaurantPhone: widget.restaurantPhone,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Rapport serveur imprimé'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur impression'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _printCategoryReport(String category) async {
    final stats = _categoryStats[category];
    if (stats == null) return;

    try {
      await DailyReportService.generateCategoryReport(
        date: _selectedDate,
        category: category,
        stats: stats,
        restaurantName: widget.restaurantName,
        restaurantAddress: widget.restaurantAddress,
        restaurantPhone: widget.restaurantPhone,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Rapport catégorie imprimé'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur impression'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête avec sélecteur de date
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.teal),
              SizedBox(width: 12),
              Text(
                'Rapports du ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              ElevatedButton.icon(
                onPressed: _selectDate,
                icon: Icon(Icons.edit_calendar),
                label: Text('Changer la date'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade50,
                  foregroundColor: Colors.teal,
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _printGeneralReport,
                icon: Icon(Icons.print, color: Colors.white),
                label: Text('Rapport Général', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),

        // Statistiques globales
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.teal.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGlobalStat('Commandes', '$_totalOrders', Icons.receipt_long),
              _buildDivider(),
              _buildGlobalStat('Revenus', '${_totalRevenue.toStringAsFixed(0)} F', Icons.attach_money),
              _buildDivider(),
              _buildGlobalStat('Ticket Moyen', '${_averageTicket.toStringAsFixed(0)} F', Icons.trending_up),
            ],
          ),
        ),

        // Contenu principal
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Rapports par serveur
                _buildSection(
                  title: 'Rapports par Serveur',
                  icon: Icons.person,
                  color: Colors.blue,
                  child: _buildWaiterReports(),
                ),

                SizedBox(height: 20),

                // Rapports par catégorie
                _buildSection(
                  title: 'Rapports par Catégorie',
                  icon: Icons.category,
                  color: Colors.orange,
                  child: _buildCategoryReports(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 60,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildWaiterReports() {
    if (_waiterStats.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'Aucune donnée',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _waiterStats.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final waiterId = _waiterStats.keys.elementAt(index);
        final stats = _waiterStats[waiterId]!;

        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(Icons.person, color: Colors.blue),
          ),
          title: FutureBuilder<String>(
            future: _getWaiterName(waiterId),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? 'Serveur $waiterId',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              );
            },
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                _buildStatChip(
                  '${stats.orderCount} cmd',
                  Icons.receipt,
                  Colors.blue,
                ),
                SizedBox(width: 8),
                _buildStatChip(
                  '${stats.totalRevenue.toStringAsFixed(0)} F',
                  Icons.attach_money,
                  Colors.green,
                ),
              ],
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.print, color: Colors.blue),
            onPressed: () => _printWaiterReport(waiterId),
            tooltip: 'Imprimer le rapport',
          ),
        );
      },
    );
  }

  Widget _buildCategoryReports() {
    if (_categoryStats.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'Aucune donnée',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _categoryStats.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final category = _categoryStats.keys.elementAt(index);
        final stats = _categoryStats[category]!;

        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: CircleAvatar(
            backgroundColor: Colors.orange.shade100,
            child: Icon(Icons.restaurant_menu, color: Colors.orange),
          ),
          title: Text(
            category,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                _buildStatChip(
                  '${stats.totalQuantity} vendus',
                  Icons.shopping_cart,
                  Colors.orange,
                ),
                SizedBox(width: 8),
                _buildStatChip(
                  '${stats.totalRevenue.toStringAsFixed(0)} F',
                  Icons.attach_money,
                  Colors.green,
                ),
              ],
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.print, color: Colors.orange),
            onPressed: () => _printCategoryReport(category),
            tooltip: 'Imprimer le rapport',
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getWaiterName(String waiterId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('staff')
          .doc(waiterId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final nom = data?['nom'] ?? '';
        final prenom = data?['prenom'] ?? '';

        // Retourner "Prénom Nom" en éliminant les espaces superflus
        final fullName = '$prenom $nom'.trim();
        return fullName.isNotEmpty ? fullName : 'Serveur';
      }
    } catch (e) {
      print('Erreur récupération nom serveur: $e');
    }
    return 'Serveur';
  }
}

// ============================================================================
// CLASSES DE STATISTIQUES
// ============================================================================

class WaiterStats {
  final String waiterId;
  int orderCount = 0;
  double totalRevenue = 0;
  List<RestaurantOrder> orders = [];

  WaiterStats({required this.waiterId});

  void addOrder(RestaurantOrder order) {
    orderCount++;
    totalRevenue += order.total;
    orders.add(order);
  }
}

class CategoryStats {
  final String category;
  int totalQuantity = 0;
  double totalRevenue = 0;
  Map<String, int> itemQuantities = {};

  CategoryStats({required this.category});

  void addItem(OrderItem item) {
    totalQuantity += item.quantity;
    totalRevenue += item.totalPrice;

    itemQuantities[item.name] = (itemQuantities[item.name] ?? 0) + item.quantity;
  }
}

// ============================================================================
// SERVICE DE GÉNÉRATION DE RAPPORTS PDF
// ============================================================================


// ============================================================================
// SERVICE DE GÉNÉRATION DE RAPPORTS PDF
// ============================================================================

class DailyReportService {
  // Initialiser les locales une seule fois
  static bool _localeInitialized = false;

  static Future<void> _ensureLocaleInitialized() async {
    if (!_localeInitialized) {
      await initializeDateFormatting('fr_FR', null);
      _localeInitialized = true;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Récupérer les noms des serveurs
  static Future<Map<String, String>> _getWaitersNames(List<RestaurantOrder> orders) async {
    final Map<String, String> waitersNames = {};
    final Set<String> waiterIds = orders
        .where((order) => order.waiterId != null && order.waiterId!.isNotEmpty)
        .map((order) => order.waiterId!)
        .toSet();

    for (String waiterId in waiterIds) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('staff')
            .doc(waiterId)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final nom = data?['nom'] ?? '';
          final prenom = data?['prenom'] ?? '';
          waitersNames[waiterId] = '$prenom $nom'.trim();
        } else {
          waitersNames[waiterId] = 'Serveur inconnu';
        }
      } catch (e) {
        print('Erreur récupération nom serveur $waiterId: $e');
        waitersNames[waiterId] = 'Serveur inconnu';
      }
    }

    return waitersNames;
  }

  static Future<void> generateGeneralReport({
    required DateTime date,
    required List<RestaurantOrder> orders,
    required double totalRevenue,
    required int totalOrders,
    required double averageTicket,
    required String restaurantName,
    required String restaurantAddress,
    required String restaurantPhone,
  }) async {
    await _ensureLocaleInitialized();

    // ✅ Récupérer les noms des serveurs
    final waitersNames = await _getWaitersNames(orders);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      restaurantName,
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(restaurantAddress, style: pw.TextStyle(fontSize: 10)),
                    pw.Text(restaurantPhone, style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Titre
              pw.Center(
                child: pw.Text(
                  'RAPPORT JOURNALIER',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  DateFormat('dd MMMM yyyy', 'fr_FR').format(date),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),

              pw.SizedBox(height: 20),

              // Statistiques globales
              pw.Container(
                padding: pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RÉSUMÉ', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    _buildReportLine('Nombre de commandes:', '$totalOrders'),
                    _buildReportLine('Chiffre d\'affaires:', '${totalRevenue.toStringAsFixed(0)} FCFA'),
                    _buildReportLine('Ticket moyen:', '${averageTicket.toStringAsFixed(0)} FCFA'),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Répartition par mode de paiement
              pw.Text(
                'RÉPARTITION PAR MODE DE PAIEMENT',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildPaymentMethodTable(orders),

              pw.SizedBox(height: 20),

              // Détail des commandes
              pw.Text(
                'DÉTAIL DES COMMANDES',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildOrdersTable(orders, waitersNames), // ✅ Passer les noms

              pw.Spacer(),

              // Pied de page
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> generateWaiterReport({
    required DateTime date,
    required String waiterId,
    required WaiterStats stats,
    required String restaurantName,
    required String restaurantAddress,
    required String restaurantPhone,
  }) async {
    await _ensureLocaleInitialized();

    // ✅ Récupérer les noms des serveurs (même si c'est un seul serveur)
    final waitersNames = await _getWaitersNames(stats.orders);

    final pdf = pw.Document();

    // Récupérer le nom du serveur
    String waiterName = 'Serveur';
    try {
      final doc = await FirebaseFirestore.instance.collection('staff').doc(waiterId).get();
      if (doc.exists) {
        final data = doc.data();
        final nom = data?['nom'] ?? '';
        final prenom = data?['prenom'] ?? '';
        waiterName = '$prenom $nom'.trim();
      }
    } catch (e) {
      print('Erreur récupération nom: $e');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      restaurantName,
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(restaurantAddress, style: pw.TextStyle(fontSize: 10)),
                    pw.Text(restaurantPhone, style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Titre
              pw.Center(
                child: pw.Text(
                  'RAPPORT SERVEUR',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  waiterName,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  DateFormat('dd MMMM yyyy', 'fr_FR').format(date),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),

              pw.SizedBox(height: 20),

              // Statistiques
              pw.Container(
                padding: pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PERFORMANCE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    _buildReportLine('Commandes traitées:', '${stats.orderCount}'),
                    _buildReportLine('Chiffre d\'affaires:', '${stats.totalRevenue.toStringAsFixed(0)} FCFA'),
                    _buildReportLine('Ticket moyen:', '${(stats.totalRevenue / stats.orderCount).toStringAsFixed(0)} FCFA'),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Liste des commandes
              pw.Text(
                'COMMANDES',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildOrdersTable(stats.orders, waitersNames), // ✅ Passer les noms

              pw.Spacer(),

              // Pied de page
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> generateCategoryReport({
    required DateTime date,
    required String category,
    required CategoryStats stats,
    required String restaurantName,
    required String restaurantAddress,
    required String restaurantPhone,
  }) async {
    await _ensureLocaleInitialized();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      restaurantName,
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(restaurantAddress, style: pw.TextStyle(fontSize: 10)),
                    pw.Text(restaurantPhone, style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Titre
              pw.Center(
                child: pw.Text(
                  'RAPPORT PAR CATÉGORIE',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  category,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  DateFormat('dd MMMM yyyy', 'fr_FR').format(date),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),

              pw.SizedBox(height: 20),

              // Statistiques
              pw.Container(
                padding: pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('VENTES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    _buildReportLine('Quantité vendue:', '${stats.totalQuantity}'),
                    _buildReportLine('Chiffre d\'affaires:', '${stats.totalRevenue.toStringAsFixed(0)} FCFA'),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Détail par plat
              pw.Text(
                'DÉTAIL PAR PLAT',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildItemsTable(stats.itemQuantities),

              pw.Spacer(),

              // Pied de page
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _buildReportLine(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 11)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentMethodTable(List<RestaurantOrder> orders) {
    final Map<String, double> paymentMethods = {};

    for (var order in orders) {
      final method = order.paymentMethod.isEmpty ? 'Non spécifié' : order.paymentMethod;
      paymentMethods[method] = (paymentMethods[method] ?? 0) + order.total;
    }

    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Mode de paiement', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Montant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
        ...paymentMethods.entries.map((entry) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: pw.Text(entry.key, style: pw.TextStyle(fontSize: 9)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: pw.Text('${entry.value.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: 9)),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // ✅ MÉTHODE MODIFIÉE: Ajouter la colonne Serveur
  static pw.Widget _buildOrdersTable(List<RestaurantOrder> orders, Map<String, String> waitersNames) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: pw.FlexColumnWidth(1.5),  // ID
        1: pw.FlexColumnWidth(1),    // Heure
        2: pw.FlexColumnWidth(1.5),  // Table
        3: pw.FlexColumnWidth(2),    // Serveur ✅
        4: pw.FlexColumnWidth(0.8),  // Articles
        5: pw.FlexColumnWidth(1.5),  // Montant
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Heure', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Table', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Serveur', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Art.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Montant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
          ],
        ),
        ...orders.map((order) {
          final waiterName = order.waiterId != null
              ? (waitersNames[order.waiterId!] ?? 'Inconnu')
              : 'Non assigné';

          return pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: pw.Text(
                  order.id.length >= 8 ? order.id.substring(0, 8) : order.id,
                  style: pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: pw.Text(DateFormat('HH:mm').format(order.createdAt), style: pw.TextStyle(fontSize: 8)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: pw.Text(order.tableNumber, style: pw.TextStyle(fontSize: 8)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: pw.Text(waiterName, style: pw.TextStyle(fontSize: 7)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: pw.Text('${order.items.length}', style: pw.TextStyle(fontSize: 8)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: pw.Text('${order.total.toStringAsFixed(0)} F', style: pw.TextStyle(fontSize: 8)),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildItemsTable(Map<String, int> itemQuantities) {
    final sortedItems = itemQuantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Plat', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Quantité', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
        ...sortedItems.map((entry) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: pw.Text(entry.key, style: pw.TextStyle(fontSize: 9)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: pw.Text('${entry.value}', style: pw.TextStyle(fontSize: 9)),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}

// ============================================================================
// DIALOGUES (Code inchangé)
// ============================================================================

class _PaymentSelectionDialog extends StatelessWidget {
  final RestaurantOrder order;
  final Function(String) onPaymentSelected;

  const _PaymentSelectionDialog({
    required this.order,
    required this.onPaymentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final methods = [
      {'name': 'Espèces', 'icon': Icons.money, 'color': Colors.green},
      {'name': 'Carte bancaire', 'icon': Icons.credit_card, 'color': Colors.blue},
      {'name': 'Mobile Money', 'icon': Icons.phone_android, 'color': Colors.orange},
      {'name': 'Facturation chambre', 'icon': Icons.hotel, 'color': Colors.purple},
      {'name': 'Chèque', 'icon': Icons.receipt, 'color': Colors.brown},
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.teal, size: 28),
                SizedBox(width: 12),
                Text('Mode de paiement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Table ${order.tableNumber}'),
                      Text(order.guestName ?? 'Client'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total à encaisser:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        '${order.total.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            ...methods.map((method) {
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () => onPaymentSelected(method['name'] as String),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (method['color'] as Color).withOpacity(0.1),
                    foregroundColor: method['color'] as Color,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    minimumSize: Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: method['color'] as Color, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(method['icon'] as IconData, size: 28),
                      SizedBox(width: 16),
                      Text(
                        method['name'] as String,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _HotelGuestSearchDialog extends StatefulWidget {
  final String userId;
  final Function(Map<String, dynamic>) onGuestSelected;

  const _HotelGuestSearchDialog({
    required this.userId,
    required this.onGuestSelected,
  });

  @override
  __HotelGuestSearchDialogState createState() => __HotelGuestSearchDialogState();
}

class __HotelGuestSearchDialogState extends State<_HotelGuestSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;
    setState(() => _isSearching = true);

    try {
      _searchResults = await RestaurantService.searchHotelGuests(
        widget.userId,
        _searchController.text,
      );
    } catch (e) {
      print('❌ Erreur recherche: $e');
    }

    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.search, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Text('Rechercher un client d\'hôtel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nom ou numéro de chambre...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _search,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _search(),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _isSearching
                  ? Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                  ? Center(child: Text('Aucun résultat', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final guest = _searchResults[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.person, color: Colors.blue),
                      ),
                      title: Text(guest['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Chambre ${guest['roomNumber']}'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => widget.onGuestSelected(guest),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}