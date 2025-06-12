import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/getConnectedUserAdminId.dart';
import 'dart:async';

import '../../config/restaurant_models.dart';

class ActiveOrders extends StatefulWidget {
  @override
  _ActiveOrdersState createState() => _ActiveOrdersState();
}

class _ActiveOrdersState extends State<ActiveOrders>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Timer _refreshTimer;

  String? _userId;
  List<RestaurantOrder> _activeOrders = [];
  List<RestaurantOrder> _completedOrders = [];
  bool _isLoading = true;

  // Filtres
  String _selectedFilter = 'Toutes';
  final List<String> _filters = ['Toutes', 'En cours', 'Prêtes', 'Hotel', 'Externes'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();

    // Auto-refresh toutes les 30 secondes
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      _userId = await getConnectedUserAdminId();
      await _loadOrders();
    } catch (e) {
      print('❌ Erreur initialisation commandes: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOrders() async {
    if (_userId == null) return;

    try {
      final orders = await RestaurantService.getActiveOrders(_userId!);

      setState(() {
        _activeOrders = orders.where((order) =>
        order.status == 'en_cours' || order.status == 'terminée'
        ).toList();

        _completedOrders = orders.where((order) =>
        order.status == 'payée'
        ).toList();

        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement commandes: $e');
      setState(() => _isLoading = false);
    }
  }

  List<RestaurantOrder> get _filteredActiveOrders {
    switch (_selectedFilter) {
      case 'En cours':
        return _activeOrders.where((order) => order.status == 'en_cours').toList();
      case 'Prêtes':
        return _activeOrders.where((order) => order.status == 'terminée').toList();
      case 'Hotel':
        return _activeOrders.where((order) => order.customerType == 'hotel_guest').toList();
      case 'Externes':
        return _activeOrders.where((order) => order.customerType == 'external').toList();
      default:
        return _activeOrders;
    }
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        title: Text('Commandes Actives'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: Icon(Icons.restaurant),
              text: 'En cours (${_activeOrders.length})',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Terminées (${_completedOrders.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildActiveOrdersTab(),
          _buildCompletedOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersTab() {
    return Column(
      children: [
        _buildFiltersSection(),
        _buildStatsSection(),
        Expanded(child: _buildActiveOrdersList()),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepOrange : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection() {
    final filteredOrders = _filteredActiveOrders;
    final inProgressCount = filteredOrders.where((o) => o.status == 'en_cours').length;
    final readyCount = filteredOrders.where((o) => o.status == 'terminée').length;
    final hotelCount = filteredOrders.where((o) => o.customerType == 'hotel_guest').length;
    final externalCount = filteredOrders.where((o) => o.customerType == 'external').length;

    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: _buildStatChip('En cours', inProgressCount, Colors.orange)),
          SizedBox(width: 8),
          Expanded(child: _buildStatChip('Prêtes', readyCount, Colors.green)),
          SizedBox(width: 8),
          Expanded(child: _buildStatChip('Hôtel', hotelCount, Colors.blue)),
          SizedBox(width: 8),
          Expanded(child: _buildStatChip('Externes', externalCount, Colors.purple)),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersList() {
    final filteredOrders = _filteredActiveOrders;

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune commande active',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Les nouvelles commandes apparaîtront ici',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return _buildOrderCard(order, true);
        },
      ),
    );
  }

  Widget _buildCompletedOrdersTab() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: _completedOrders.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune commande terminée aujourd\'hui',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _completedOrders.length,
        itemBuilder: (context, index) {
          final order = _completedOrders[index];
          return _buildOrderCard(order, false);
        },
      ),
    );
  }

  Widget _buildOrderCard(RestaurantOrder order, bool isActive) {
    final statusData = _getOrderStatusData(order.status);
    final customerTypeData = _getCustomerTypeData(order.customerType);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOrderDetailsDialog(order),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusData['color'].withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.table_restaurant, color: Colors.deepOrange),
                        SizedBox(width: 8),
                        Text(
                          'Table ${order.tableNumber}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusData['color'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusData['text'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Client
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: customerTypeData['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          customerTypeData['icon'],
                          size: 14,
                          color: customerTypeData['color'],
                        ),
                        SizedBox(width: 4),
                        Text(
                          customerTypeData['text'],
                          style: TextStyle(
                            color: customerTypeData['color'],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      order.guestName ?? 'Client anonyme',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (order.roomNumber != null)
                    Text(
                      'Ch. ${order.roomNumber}',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),

              SizedBox(height: 12),

              // Résumé commande
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
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
                    SizedBox(height: 8),
                    // Aperçu des articles
                    Text(
                      order.items.take(3).map((item) =>
                      '${item.quantity}x ${item.name}'
                      ).join(', ') +
                          (order.items.length > 3 ? '...' : ''),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // Actions et timing
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getTimeAgo(order.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isActive) ...[
                    if (order.status == 'en_cours') ...[
                      ElevatedButton(
                        onPressed: () => _markOrderReady(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size(0, 0),
                        ),
                        child: Text('Prête', style: TextStyle(fontSize: 12)),
                      ),
                      SizedBox(width: 8),
                    ],
                    if (order.status == 'terminée') ...[
                      ElevatedButton(
                        onPressed: () => _showPaymentDialog(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size(0, 0),
                        ),
                        child: Text('Encaisser', style: TextStyle(fontSize: 12)),
                      ),
                      SizedBox(width: 8),
                    ],
                  ],
                  IconButton(
                    onPressed: () => _showOrderDetailsDialog(order),
                    icon: Icon(Icons.more_vert),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getOrderStatusData(String status) {
    switch (status) {
      case 'en_cours':
        return {'color': Colors.orange, 'text': 'En cours'};
      case 'terminée':
        return {'color': Colors.green, 'text': 'Prête'};
      case 'payée':
        return {'color': Colors.blue, 'text': 'Payée'};
      default:
        return {'color': Colors.grey, 'text': 'Inconnu'};
    }
  }

  Map<String, dynamic> _getCustomerTypeData(String customerType) {
    switch (customerType) {
      case 'hotel_guest':
        return {
          'color': Colors.blue,
          'text': 'Client Hôtel',
          'icon': Icons.hotel,
        };
      case 'external':
        return {
          'color': Colors.orange,
          'text': 'Client Externe',
          'icon': Icons.person,
        };
      default:
        return {
          'color': Colors.grey,
          'text': 'Inconnu',
          'icon': Icons.help,
        };
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }

  Future<void> _markOrderReady(RestaurantOrder order) async {
    try {
      await RestaurantService.updateOrderStatus(order.id, 'terminée');
      _showSuccessMessage('Commande marquée comme prête');
      _loadOrders();
    } catch (e) {
      _showErrorMessage('Erreur lors de la mise à jour');
    }
  }

  void _showPaymentDialog(RestaurantOrder order) {
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        order: order,
        onPaymentCompleted: () {
          _loadOrders();
        },
      ),
    );
  }

  void _showOrderDetailsDialog(RestaurantOrder order) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailsDialog(
        order: order,
        onOrderUpdated: _loadOrders,
      ),
    );
  }
}

// Dialog de détails de commande
class OrderDetailsDialog extends StatelessWidget {
  final RestaurantOrder order;
  final VoidCallback onOrderUpdated;

  const OrderDetailsDialog({
    Key? key,
    required this.order,
    required this.onOrderUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // En-tête
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Commande Table ${order.tableNumber}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations client
                    _buildInfoSection(
                      'Client',
                      [
                        if (order.guestName != null)
                          _buildInfoRow('Nom', order.guestName!),
                        if (order.roomNumber != null)
                          _buildInfoRow('Chambre', order.roomNumber!),
                        if (order.guestPhone != null && order.guestPhone!.isNotEmpty)
                          _buildInfoRow('Téléphone', order.guestPhone!),
                        _buildInfoRow('Type',
                            order.customerType == 'hotel_guest' ? 'Client Hôtel' : 'Client Externe'),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Articles commandés
                    _buildInfoSection(
                      'Articles commandés',
                      order.items.map((item) =>
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  '${item.quantity}x',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 8),
                                Expanded(child: Text(item.name)),
                                Text(
                                  '${item.totalPrice.toStringAsFixed(0)} F',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                      ).toList(),
                    ),

                    SizedBox(height: 20),

                    // Totaux
                    _buildInfoSection(
                      'Facturation',
                      [
                        _buildInfoRow('Sous-total', '${order.subtotal.toStringAsFixed(0)} FCFA'),
                        _buildInfoRow('TVA', '${order.tax.toStringAsFixed(0)} FCFA'),
                        _buildInfoRow('Service', '${order.serviceCharge.toStringAsFixed(0)} FCFA'),
                        Divider(),
                        _buildInfoRow('TOTAL', '${order.total.toStringAsFixed(0)} FCFA', isTotal: true),
                      ],
                    ),

                    if (order.specialRequests != null && order.specialRequests!.isNotEmpty) ...[
                      SizedBox(height: 20),
                      _buildInfoSection(
                        'Demandes spéciales',
                        [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.yellow.shade200),
                            ),
                            child: Text(order.specialRequests!),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            if (order.status != 'payée') ...[
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    if (order.status == 'en_cours') ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await RestaurantService.updateOrderStatus(order.id, 'terminée');
                              Navigator.pop(context);
                              onOrderUpdated();
                            } catch (e) {
                              // Gérer l'erreur
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Marquer comme prête'),
                        ),
                      ),
                    ] else if (order.status == 'terminée') ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Ouvrir dialog de paiement
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Encaisser'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog de paiement
class PaymentDialog extends StatefulWidget {
  final RestaurantOrder order;
  final VoidCallback onPaymentCompleted;

  const PaymentDialog({
    Key? key,
    required this.order,
    required this.onPaymentCompleted,
  }) : super(key: key);

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _selectedPaymentMethod = 'Espèces';
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'key': 'Espèces', 'name': 'Espèces', 'icon': Icons.money},
    {'key': 'Carte bancaire', 'name': 'Carte bancaire', 'icon': Icons.credit_card},
    {'key': 'Mobile Money', 'name': 'Mobile Money', 'icon': Icons.phone_android},
    {'key': 'Chèque', 'name': 'Chèque', 'icon': Icons.receipt},
  ];

  @override
  void initState() {
    super.initState();
    // Si client d'hôtel, proposer facturation chambre par défaut
    if (widget.order.customerType == 'hotel_guest') {
      _selectedPaymentMethod = 'Facturation chambre';
      _paymentMethods.insert(0, {
        'key': 'Facturation chambre',
        'name': 'Facturation chambre',
        'icon': Icons.hotel
      });
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      await RestaurantService.updateOrderPayment(widget.order.id, _selectedPaymentMethod);

      // Libérer la table
      await RestaurantService.updateTableStatus(widget.order.tableId, 'libre');

      Navigator.pop(context);
      widget.onPaymentCompleted();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du paiement'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Encaisser la commande',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Contenu
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Résumé
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Table ${widget.order.tableNumber}'),
                            Text(widget.order.guestName ?? 'Client anonyme'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total à encaisser:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${widget.order.total.toStringAsFixed(0)} FCFA',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Méthodes de paiement
                  Text(
                    'Méthode de paiement:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),

                  ..._paymentMethods.map((method) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: RadioListTile<String>(
                        value: method['key'],
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() => _selectedPaymentMethod = value!);
                        },
                        title: Row(
                          children: [
                            Icon(method['icon'], size: 20),
                            SizedBox(width: 8),
                            Text(method['name']),
                          ],
                        ),
                        activeColor: Colors.blue,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Boutons
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : () => Navigator.pop(context),
                      child: Text('Annuler'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isProcessing
                          ? SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : Text('Encaisser'),
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
}