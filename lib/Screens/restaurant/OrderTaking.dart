import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/getConnectedUserAdminId.dart';
import '../../config/restaurant_models.dart';

class OrderTaking extends StatefulWidget {
  final RestaurantTable? preSelectedTable;

  const OrderTaking({Key? key, this.preSelectedTable}) : super(key: key);

  @override
  _OrderTakingState createState() => _OrderTakingState();
}

class _OrderTakingState extends State<OrderTaking>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  String? _userId;
  bool _isLoading = true;

  // Tables et menu
  List<RestaurantTable> _tables = [];
  List<MenuItem> _menuItems = [];
  RestaurantTable? _selectedTable;

  // Client
  String _customerType = 'external'; // hotel_guest ou external
  Map<String, dynamic>? _selectedHotelGuest;
  final _externalNameController = TextEditingController();
  final _externalPhoneController = TextEditingController();
  bool _isRoomService = false; // Nouveau : service en chambre

  // Commande
  List<OrderItem> _orderItems = [];
  String _specialRequests = '';

  // Configuration
  final double _taxRate = 0.18; // 18% TVA
  final double _serviceChargeRate = 0.00; // 0% service

  // Catégories pour filtrage
  String _selectedMenuCategory = 'Tous';
  final List<Map<String, dynamic>> _menuCategories = [
    {'name': 'Tous', 'icon': Icons.restaurant, 'color': Colors.deepOrange},
    {'name': 'Entrées', 'icon': Icons.emoji_food_beverage, 'color': Colors.green},
    {'name': 'Plats principaux', 'icon': Icons.dinner_dining, 'color': Colors.red},
    {'name': 'Desserts', 'icon': Icons.cake, 'color': Colors.pink},
    {'name': 'Boissons', 'icon': Icons.local_drink, 'color': Colors.blue},
    {'name': 'Vins', 'icon': Icons.wine_bar, 'color': Colors.purple},
    {'name': 'Cocktails', 'icon': Icons.local_bar, 'color': Colors.orange},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _selectedTable = widget.preSelectedTable;
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _externalNameController.dispose();
    _externalPhoneController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      _userId = await getConnectedUserAdminId();
      await Future.wait([
        _loadTables(),
        _loadMenuItems(),
      ]);
      _animationController.forward();
    } catch (e) {
      print('❌ Erreur initialisation commande: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTables() async {
    if (_userId == null) return;

    try {
      final tables = await RestaurantService.getTables(_userId!);
      setState(() {
        _tables = tables.where((table) => table.status == 'libre').toList();
      });
    } catch (e) {
      print('❌ Erreur chargement tables: $e');
    }
  }

  Future<void> _loadMenuItems() async {
    if (_userId == null) return;

    try {
      final items = await RestaurantService.getMenuItems(_userId!);
      setState(() {
        _menuItems = items.where((item) => item.isAvailable).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement menu: $e');
      setState(() => _isLoading = false);
    }
  }

  List<MenuItem> get _filteredMenuItems {
    if (_selectedMenuCategory == 'Tous') {
      return _menuItems;
    }
    return _menuItems.where((item) => item.category == _selectedMenuCategory).toList();
  }

  double get _subtotal {
    return _orderItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get _tax {
    return _subtotal * _taxRate;
  }

  double get _serviceCharge {
    return _subtotal * _serviceChargeRate;
  }

  double get _total {
    return _subtotal + _tax + _serviceCharge;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepOrange.shade600, Colors.deepOrange.shade400],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        title: Text(
          'Nouvelle Commande',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: [
                Tab(
                  icon: Icon(Icons.table_restaurant_rounded, size: 20),
                  text: 'Table & Client',
                ),
                Tab(
                  icon: Icon(Icons.restaurant_menu_rounded, size: 20),
                  text: 'Menu',
                ),
                Tab(
                  icon: Icon(Icons.receipt_long_rounded, size: 20),
                  text: 'Commande',
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Chargement...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      )
          : AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _animationController,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTableClientTab(),
                _buildMenuTab(),
                _buildOrderTab(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTableClientTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélection de table
          _buildModernSectionCard(
            title: 'Sélection de la table',
            icon: Icons.table_restaurant_rounded,
            iconColor: Colors.green,
            child: Column(
              children: [
                if (_selectedTable != null) ...[
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green.shade100, Colors.green.shade50],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.table_restaurant_rounded, color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Table ${_selectedTable!.tableNumber}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.people_outline, size: 16, color: Colors.green.shade600),
                                  SizedBox(width: 4),
                                  Text(
                                    '${_selectedTable!.capacity} places',
                                    style: TextStyle(color: Colors.green.shade600),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(Icons.location_on_outlined, size: 16, color: Colors.green.shade600),
                                  SizedBox(width: 4),
                                  Text(
                                    _selectedTable!.location,
                                    style: TextStyle(color: Colors.green.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showTableSelectionDialog(),
                          icon: Icon(Icons.edit_rounded, size: 16),
                          label: Text('Changer'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.deepOrange.shade600, Colors.deepOrange.shade400],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _showTableSelectionDialog,
                      icon: Icon(Icons.table_restaurant_rounded, color: Colors.white),
                      label: Text(
                        'Sélectionner une table',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 24),

          // Type de client
          _buildModernSectionCard(
            title: 'Type de client',
            icon: Icons.person_rounded,
            iconColor: Colors.blue,
            child: Row(
              children: [
                Expanded(
                  child: _buildCustomerTypeCard(
                    title: 'Client Hôtel',
                    subtitle: 'Résident de l\'hôtel',
                    icon: Icons.hotel_rounded,
                    isSelected: _customerType == 'hotel_guest',
                    color: Colors.blue,
                    onTap: () => setState(() {
                      _customerType = 'hotel_guest';
                      _isRoomService = false; // Reset room service
                    }),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildCustomerTypeCard(
                    title: 'Client Externe',
                    subtitle: 'Visiteur extérieur',
                    icon: Icons.person_rounded,
                    isSelected: _customerType == 'external',
                    color: Colors.orange,
                    onTap: () => setState(() {
                      _customerType = 'external';
                      _isRoomService = false; // Reset room service
                    }),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Service en chambre pour clients hôtel
          if (_customerType == 'hotel_guest') ...[
            _buildModernSectionCard(
              title: 'Options de service',
              icon: Icons.room_service_rounded,
              iconColor: Colors.purple,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.room_service_rounded, color: Colors.purple, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service en chambre',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple.shade800,
                            ),
                          ),
                          Text(
                            'Livraison directement en chambre',
                            style: TextStyle(
                              color: Colors.purple.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isRoomService,
                      onChanged: (value) {
                        setState(() => _isRoomService = value);
                      },
                      activeColor: Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
          ],

          // Informations client
          if (_customerType == 'hotel_guest') ...[
            _buildModernSectionCard(
              title: 'Client hôtel',
              icon: Icons.search_rounded,
              iconColor: Colors.blue,
              child: Column(
                children: [
                  if (_selectedHotelGuest != null) ...[
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue.shade100, Colors.blue.shade50],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedHotelGuest!['name'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.hotel, size: 16, color: Colors.blue.shade600),
                                    SizedBox(width: 4),
                                    Text(
                                      'Chambre ${_selectedHotelGuest!['roomNumber']}',
                                      style: TextStyle(color: Colors.blue.shade600),
                                    ),
                                  ],
                                ),
                                if (_selectedHotelGuest!['phone'].isNotEmpty) ...[
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 16, color: Colors.blue.shade600),
                                      SizedBox(width: 4),
                                      Text(
                                        _selectedHotelGuest!['phone'],
                                        style: TextStyle(color: Colors.blue.shade600),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showHotelGuestSearchDialog(),
                            icon: Icon(Icons.edit_rounded, size: 16),
                            label: Text('Changer'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue.shade600, Colors.blue.shade400],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _showHotelGuestSearchDialog,
                        icon: Icon(Icons.search_rounded, color: Colors.white),
                        label: Text(
                          'Rechercher un client hôtel',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            _buildModernSectionCard(
              title: 'Informations client externe',
              icon: Icons.person_add_rounded,
              iconColor: Colors.orange,
              child: Column(
                children: [
                  _buildModernTextField(
                    controller: _externalNameController,
                    label: 'Nom du client (optionnel)',
                    icon: Icons.person_rounded,
                    isRequired: false,
                  ),
                  SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _externalPhoneController,
                    label: 'Téléphone (optionnel)',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    isRequired: false,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    return Column(
      children: [
        // Filtres par catégorie modernisés
        Container(
          height: 100, // Augmenté de 80 à 100
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Augmenté de 12 à 16
            itemCount: _menuCategories.length,
            itemBuilder: (context, index) {
              final category = _menuCategories[index];
              final isSelected = _selectedMenuCategory == category['name'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMenuCategory = category['name'];
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 12),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Augmenté le padding
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [category['color'], category['color'].withOpacity(0.8)],
                    )
                        : null,
                    color: isSelected ? null : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: category['color'].withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center, // Centré verticalement
                    children: [
                      Icon(
                        category['icon'],
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        size: 24, // Augmenté de 20 à 24
                      ),
                      SizedBox(height: 6), // Augmenté de 4 à 6
                      Text(
                        category['name'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12, // Augmenté de 11 à 12
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Liste du menu modernisée
        Expanded(
          child: _filteredMenuItems.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_rounded, size: 64, color: Colors.grey.shade400),
                SizedBox(height: 16),
                Text(
                  'Aucun article dans cette catégorie',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _filteredMenuItems.length,
            itemBuilder: (context, index) {
              final item = _filteredMenuItems[index];
              return _buildModernMenuItemCard(item, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Articles commandés
          _buildModernSectionCard(
            title: 'Articles commandés (${_orderItems.length})',
            icon: Icons.shopping_cart_rounded,
            iconColor: Colors.green,
            child: _orderItems.isEmpty
                ? Container(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey.shade400),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucun article ajouté',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ajoutez des articles depuis l\'onglet Menu',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
                : Column(
              children: _orderItems.map((orderItem) {
                return _buildModernOrderItemCard(orderItem);
              }).toList(),
            ),
          ),

          if (_orderItems.isNotEmpty) ...[
            SizedBox(height: 24),

            // Calculs modernisés
            _buildModernSectionCard(
              title: 'Récapitulatif',
              icon: Icons.receipt_long_rounded,
              iconColor: Colors.blue,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade100, Colors.blue.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildTotalRow('Sous-total', _subtotal, false),
                    _buildTotalRow('TVA (${(_taxRate * 100).toInt()}%)', _tax, false),
                    if (_serviceCharge > 0)
                      _buildTotalRow('Service (${(_serviceChargeRate * 100).toInt()}%)', _serviceCharge, false),
                    Divider(thickness: 2, color: Colors.blue.shade200),
                    _buildTotalRow('TOTAL', _total, true),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Demandes spéciales modernisées
            _buildModernSectionCard(
              title: 'Demandes spéciales',
              icon: Icons.note_rounded,
              iconColor: Colors.purple,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Allergies, préférences, instructions spéciales...',
                    hintStyle: TextStyle(color: Colors.purple.shade400),
                    prefixIcon: Icon(Icons.note_rounded, color: Colors.purple),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                  onChanged: (value) => _specialRequests = value,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          )
              : null,
          color: isSelected ? null : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? color.withOpacity(0.8) : Colors.grey.shade500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isRequired = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: Colors.deepOrange, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildModernMenuItemCard(MenuItem item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Image ou icône modernisée
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.deepOrange.withOpacity(0.1), Colors.deepOrange.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.restaurant_rounded, color: Colors.deepOrange, size: 28);
                  },
                ),
              )
                  : Icon(Icons.restaurant_rounded, color: Colors.deepOrange, size: 28),
            ),

            SizedBox(width: 16),

            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      '${item.price.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 12),

            // Bouton ajouter modernisé
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.deepOrange.shade600, Colors.deepOrange.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _addItemToOrder(item),
                icon: Icon(Icons.add_rounded, size: 16),
                label: Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size(0, 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernOrderItemCard(OrderItem orderItem) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.restaurant_rounded, color: Colors.white, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderItem.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  '${orderItem.price.toStringAsFixed(0)} FCFA × ${orderItem.quantity}',
                  style: TextStyle(color: Colors.green.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _updateItemQuantity(orderItem, orderItem.quantity - 1),
                  icon: Icon(Icons.remove_rounded, color: Colors.red),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 12),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  orderItem.quantity.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _updateItemQuantity(orderItem, orderItem.quantity + 1),
                  icon: Icon(Icons.add_rounded, color: Colors.green.shade700),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${orderItem.totalPrice.toStringAsFixed(0)} F',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, bool isTotal) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.blue.shade800 : Colors.blue.shade700,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.blue.shade800 : Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_orderItems.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade100, Colors.green.shade50],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ${_total.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        '${_orderItems.length} article${_orderItems.length > 1 ? 's' : ''}',
                        style: TextStyle(color: Colors.green.shade600),
                      ),
                    ],
                  ),
                  Icon(Icons.receipt_long_rounded, color: Colors.green, size: 28),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          Row(
            children: [
              if (_tabController.index > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _tabController.animateTo(_tabController.index - 1);
                    },
                    icon: Icon(Icons.arrow_back_rounded),
                    label: Text('Précédent'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                SizedBox(width: 16),
              ],

              Expanded(
                flex: _tabController.index == 0 ? 1 : 1,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _canProceed()
                        ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.deepOrange.shade600, Colors.deepOrange.shade400],
                    )
                        : null,
                    color: _canProceed() ? null : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _canProceed()
                        ? [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ]
                        : null,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _canProceed() ? _handleNextStep : null,
                    icon: Icon(_getNextButtonIcon(), size: 20),
                    label: Text(
                      _getNextButtonText(),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: _canProceed() ? Colors.white : Colors.grey.shade600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_tabController.index) {
      case 0: // Table & Client
        if (_selectedTable == null && !_isRoomService) return false;
        if (_customerType == 'hotel_guest' && _selectedHotelGuest == null) return false;
        // Nom et téléphone ne sont plus obligatoires
        return true;
      case 1: // Menu
        return true;
      case 2: // Commande
        return _orderItems.isNotEmpty;
      default:
        return false;
    }
  }

  String _getNextButtonText() {
    switch (_tabController.index) {
      case 0:
        return 'Continuer';
      case 1:
        return 'Voir la commande';
      case 2:
        return 'Valider la commande';
      default:
        return 'Continuer';
    }
  }

  IconData _getNextButtonIcon() {
    switch (_tabController.index) {
      case 0:
        return Icons.arrow_forward_rounded;
      case 1:
        return Icons.receipt_long_rounded;
      case 2:
        return Icons.check_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  void _handleNextStep() {
    if (_tabController.index < 2) {
      _tabController.animateTo(_tabController.index + 1);
    } else {
      _validateOrder();
    }
  }

  void _addItemToOrder(MenuItem item) {
    setState(() {
      final existingIndex = _orderItems.indexWhere(
            (orderItem) => orderItem.menuItemId == item.id,
      );

      if (existingIndex >= 0) {
        _orderItems[existingIndex] = OrderItem(
          menuItemId: item.id,
          name: item.name,
          price: item.price,
          quantity: _orderItems[existingIndex].quantity + 1,
          status: 'commandé',
        );
      } else {
        _orderItems.add(OrderItem(
          menuItemId: item.id,
          name: item.name,
          price: item.price,
          quantity: 1,
          status: 'commandé',
        ));
      }
    });

    _showSuccessMessage('Article ajouté à la commande');
  }

  void _updateItemQuantity(OrderItem orderItem, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _orderItems.removeWhere((item) => item.menuItemId == orderItem.menuItemId);
      } else {
        final index = _orderItems.indexWhere(
              (item) => item.menuItemId == orderItem.menuItemId,
        );
        if (index >= 0) {
          _orderItems[index] = OrderItem(
            menuItemId: orderItem.menuItemId,
            name: orderItem.name,
            price: orderItem.price,
            quantity: newQuantity,
            specialInstructions: orderItem.specialInstructions,
            status: orderItem.status,
          );
        }
      }
    });
  }

  void _showTableSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Column(
            children: [
              // En-tête modernisé
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade600, Colors.green.shade400],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.table_restaurant_rounded, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sélectionner une table',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_tables.length} tables disponibles',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des tables
              Expanded(
                child: _tables.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.table_restaurant_rounded, size: 64, color: Colors.grey.shade400),
                      SizedBox(height: 16),
                      Text(
                        'Aucune table disponible',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(20),
                  itemCount: _tables.length,
                  itemBuilder: (context, index) {
                    final table = _tables[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.table_restaurant_rounded, color: Colors.white),
                        ),
                        title: Text(
                          'Table ${table.tableNumber}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(Icons.people_outline, size: 16, color: Colors.green.shade600),
                            SizedBox(width: 4),
                            Text('${table.capacity} places'),
                            SizedBox(width: 12),
                            Icon(Icons.location_on_outlined, size: 16, color: Colors.green.shade600),
                            SizedBox(width: 4),
                            Text(table.location),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.green),
                        onTap: () {
                          setState(() => _selectedTable = table);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHotelGuestSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => HotelGuestSearchDialog(
        userId: _userId!,
        onGuestSelected: (guest) {
          setState(() => _selectedHotelGuest = guest);
        },
      ),
    );
  }

  Future<void> _validateOrder() async {
    if (_orderItems.isEmpty) {
      _showErrorMessage('Aucun article dans la commande');
      return;
    }

    // Pour le service en chambre, pas besoin de table
    if (!_isRoomService && _selectedTable == null) {
      _showErrorMessage('Veuillez sélectionner une table');
      return;
    }

    try {
      final order = RestaurantOrder(
        id: '',
        tableId: _isRoomService ? '' : (_selectedTable?.id ?? ''),
        tableNumber: _isRoomService ? 'Service en chambre' : (_selectedTable?.tableNumber ?? ''),
        customerType: _customerType,
        hotelGuestId: _selectedHotelGuest?['id'],
        guestName: _customerType == 'hotel_guest'
            ? _selectedHotelGuest!['name']
            : (_externalNameController.text.isEmpty ? 'Client anonyme' : _externalNameController.text),
        guestPhone: _customerType == 'hotel_guest'
            ? _selectedHotelGuest!['phone']
            : _externalPhoneController.text,
        roomNumber: _selectedHotelGuest?['roomNumber'],
        items: _orderItems,
        subtotal: _subtotal,
        tax: _tax,
        serviceCharge: _serviceCharge,
        total: _total,
        status: 'en_cours',
        paymentMethod: '',
        createdAt: DateTime.now(),
        userId: _userId!,
        specialRequests: _specialRequests.isEmpty ? null : _specialRequests,
        isRoomService: _isRoomService, // Nouveau champ
      );

      await RestaurantService.createOrder(order);
      _showSuccessMessage('Commande créée avec succès');
      Navigator.pop(context);
    } catch (e) {
      _showErrorMessage('Erreur lors de la création de la commande');
    }
  }
}

// Dialog de recherche de clients d'hôtel modernisé
class HotelGuestSearchDialog extends StatefulWidget {
  final String userId;
  final Function(Map<String, dynamic>) onGuestSelected;

  const HotelGuestSearchDialog({
    Key? key,
    required this.userId,
    required this.onGuestSelected,
  }) : super(key: key);

  @override
  _HotelGuestSearchDialogState createState() => _HotelGuestSearchDialogState();
}

class _HotelGuestSearchDialogState extends State<HotelGuestSearchDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchGuests(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await RestaurantService.searchHotelGuests(widget.userId, query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          children: [
            // En-tête modernisé
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.search_rounded, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rechercher un client d\'hôtel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Nom du client ou numéro de chambre',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            // Barre de recherche modernisée
            Padding(
              padding: EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tapez le nom du client ou numéro de chambre...',
                    hintStyle: TextStyle(color: Colors.blue.shade400),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.blue),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  onChanged: _searchGuests,
                ),
              ),
            ),

            // Résultats modernisés
            Expanded(
              child: _isSearching
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Recherche en cours...',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
                  : _searchResults.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.search_rounded, size: 48, color: Colors.grey.shade400),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _searchController.text.isEmpty
                          ? 'Tapez pour rechercher un client'
                          : 'Aucun client trouvé',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Essayez avec un autre nom ou numéro',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final guest = _searchResults[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        guest['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.hotel, size: 16, color: Colors.blue.shade600),
                              SizedBox(width: 4),
                              Text(
                                'Chambre ${guest['roomNumber']}',
                                style: TextStyle(color: Colors.blue.shade600),
                              ),
                            ],
                          ),
                          if (guest['phone'].isNotEmpty) ...[
                            SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 16, color: Colors.blue.shade600),
                                SizedBox(width: 4),
                                Text(
                                  guest['phone'],
                                  style: TextStyle(color: Colors.blue.shade600),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.blue),
                      onTap: () {
                        widget.onGuestSelected(guest);
                        Navigator.pop(context);
                      },
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