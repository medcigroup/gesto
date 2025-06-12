import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/getConnectedUserAdminId.dart';
import 'Screens/restaurant/ActiveOrders.dart';
import 'Screens/restaurant/MenuManagement.dart';
import 'Screens/restaurant/OrderTaking.dart';
import 'Screens/restaurant/TablesManagement.dart';
import 'config/restaurant_models.dart';

// Imports des pages restaurant

// import 'table_reservations.dart';  // À créer en Phase 3
// import 'restaurant_reports.dart';  // À créer en Phase 3

class RestaurantDashboard extends StatefulWidget {
  @override
  _RestaurantDashboardState createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _userId;
  bool _isLoading = true;

  // Données du dashboard
  List<RestaurantTable> _tables = [];
  List<RestaurantOrder> _activeOrders = [];
  Map<String, dynamic> _todayStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      _userId = await getConnectedUserAdminId();
      await _loadDashboardData();
    } catch (e) {
      print('❌ Erreur initialisation restaurant: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboardData() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Charger les données en parallèle
      final results = await Future.wait([
        RestaurantService.getTables(_userId!),
        RestaurantService.getActiveOrders(_userId!),
        RestaurantService.getRestaurantStats(
          _userId!,
          DateTime.now().subtract(Duration(hours: 24)),
          DateTime.now(),
        ),
      ]);

      setState(() {
        _tables = results[0] as List<RestaurantTable>;
        _activeOrders = results[1] as List<RestaurantOrder>;
        _todayStats = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        title: Text('Restaurant Dashboard'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'Accueil'),
            Tab(icon: Icon(Icons.table_restaurant), text: 'Tables'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Commandes'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),
          _buildTablesTab(),
          _buildOrdersTab(),
          _buildStatsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActions(context),
        backgroundColor: Colors.deepOrange,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHomeTab() {
    final freeTablesCount = _tables.where((t) => t.status == 'libre').length;
    final occupiedTablesCount = _tables.where((t) => t.status == 'occupée').length;
    final reservedTablesCount = _tables.where((t) => t.status == 'réservée').length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de bienvenue
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepOrange, Colors.orange.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant, size: 40, color: Colors.white),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Restaurant Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Gérez votre restaurant en temps réel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Statistiques rapides
          Text(
            'Vue d\'ensemble',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tables Libres',
                  freeTablesCount.toString(),
                  Icons.event_available,
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Tables Occupées',
                  occupiedTablesCount.toString(),
                  Icons.event_busy,
                  Colors.red,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Réservations',
                  reservedTablesCount.toString(),
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Commandes Actives',
                  _activeOrders.length.toString(),
                  Icons.receipt,
                  Colors.blue,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Statistiques du jour
          Text(
            'Statistiques du jour',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Chiffre d\'affaires:', style: TextStyle(fontSize: 16)),
                    Text(
                      '${_todayStats['totalRevenue']?.toStringAsFixed(0) ?? '0'} FCFA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Commandes totales:', style: TextStyle(fontSize: 16)),
                    Text(
                      '${_todayStats['totalOrders'] ?? 0}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Clients hôtel:', style: TextStyle(fontSize: 16)),
                    Text(
                      '${_todayStats['hotelGuestOrders'] ?? 0}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Clients externes:', style: TextStyle(fontSize: 16)),
                    Text(
                      '${_todayStats['externalOrders'] ?? 0}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Actions rapides
          Text(
            'Actions rapides',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Nouvelle Commande',
                  Icons.add_shopping_cart,
                  Colors.blue,
                      () => _navigateToOrderTaking(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Gérer Menu',
                  Icons.restaurant_menu,
                  Colors.green,
                      () => _navigateToMenuManagement(),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Gérer Tables',
                  Icons.table_restaurant,
                  Colors.orange,
                      () => _navigateToTablesManagement(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Commandes Actives',
                  Icons.receipt_long,
                  Colors.purple,
                      () => _navigateToActiveOrders(),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Réservations',
                  Icons.event_note,
                  Colors.teal,
                      () => _navigateToReservations(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Rapports',
                  Icons.analytics,
                  Colors.indigo,
                      () => _navigateToReports(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTablesTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'État des Tables',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _navigateToTablesManagement,
                icon: Icon(Icons.settings),
                label: Text('Gérer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _tables.length,
              itemBuilder: (context, index) {
                final table = _tables[index];
                return _buildTableCard(table);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commandes Actives',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _navigateToActiveOrders,
                icon: Icon(Icons.fullscreen),
                label: Text('Voir tout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: _activeOrders.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune commande active',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _navigateToOrderTaking,
                    icon: Icon(Icons.add_shopping_cart),
                    label: Text('Nouvelle Commande'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _activeOrders.length,
              itemBuilder: (context, index) {
                final order = _activeOrders[index];
                return _buildOrderCard(order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistiques Détaillées',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _navigateToReports,
                icon: Icon(Icons.analytics),
                label: Text('Rapports'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Graphiques et statistiques détaillées à implémenter
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Graphiques détaillés',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Disponibles en Phase 3',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCard(RestaurantTable table) {
    Color statusColor;
    String statusText;

    switch (table.status) {
      case 'libre':
        statusColor = Colors.green;
        statusText = 'Libre';
        break;
      case 'occupée':
        statusColor = Colors.red;
        statusText = 'Occupée';
        break;
      case 'réservée':
        statusColor = Colors.orange;
        statusText = 'Réservée';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Maintenance';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (table.status == 'libre') {
            _navigateToOrderTaking(preSelectedTable: table);
          }
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Table ${table.tableNumber}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${table.capacity} places',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                table.location,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              if (table.status == 'libre') ...[
                SizedBox(height: 8),
                Text(
                  'Tap pour commander',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(RestaurantOrder order) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Table ${order.tableNumber}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.customerType == 'hotel_guest' ? Colors.blue : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.customerType == 'hotel_guest' ? 'Client Hôtel' : 'Client Externe',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (order.guestName != null)
              Text(
                order.guestName!,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            if (order.roomNumber != null)
              Text(
                'Chambre ${order.roomNumber}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} article${order.items.length > 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  '${order.total.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Actions Rapides',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.add_shopping_cart, color: Colors.blue),
              title: Text('Nouvelle Commande'),
              onTap: () {
                Navigator.pop(context);
                _navigateToOrderTaking();
              },
            ),
            ListTile(
              leading: Icon(Icons.restaurant_menu, color: Colors.green),
              title: Text('Gérer le Menu'),
              onTap: () {
                Navigator.pop(context);
                _navigateToMenuManagement();
              },
            ),
            ListTile(
              leading: Icon(Icons.table_restaurant, color: Colors.orange),
              title: Text('Gérer les Tables'),
              onTap: () {
                Navigator.pop(context);
                _navigateToTablesManagement();
              },
            ),
            ListTile(
              leading: Icon(Icons.receipt_long, color: Colors.purple),
              title: Text('Commandes Actives'),
              onTap: () {
                Navigator.pop(context);
                _navigateToActiveOrders();
              },
            ),
            ListTile(
              leading: Icon(Icons.event_note, color: Colors.teal),
              title: Text('Réservations'),
              onTap: () {
                Navigator.pop(context);
                _navigateToReservations();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========== MÉTHODES DE NAVIGATION IMPLÉMENTÉES ==========

  void _navigateToOrderTaking({RestaurantTable? preSelectedTable}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTaking(preSelectedTable: preSelectedTable),
      ),
    ).then((_) {
      // Recharger les données au retour
      _loadDashboardData();
    });
  }

  void _navigateToMenuManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuManagement(),
      ),
    ).then((_) {
      // Recharger les données au retour
      _loadDashboardData();
    });
  }

  void _navigateToTablesManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TablesManagement(),
      ),
    ).then((_) {
      // Recharger les données au retour
      _loadDashboardData();
    });
  }

  void _navigateToActiveOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveOrders(),
      ),
    ).then((_) {
      // Recharger les données au retour
      _loadDashboardData();
    });
  }

  void _navigateToReservations() {
    // Placeholder pour Phase 3
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Réservations de tables - Disponible en Phase 3'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _navigateToReports() {
    // Placeholder pour Phase 3
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Rapports détaillés - Disponible en Phase 3'),
          ],
        ),
        backgroundColor: Colors.indigo,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}