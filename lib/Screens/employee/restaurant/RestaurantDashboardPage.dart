import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ Ajouter cet import
import '../../../config/getConnectedUserAdminId.dart';
import '../../../config/restaurant_models.dart';
import 'CashierRestaurantPage.dart';

class RestaurantDashboardPage extends StatefulWidget {
  const RestaurantDashboardPage({Key? key}) : super(key: key);

  @override
  _RestaurantDashboardPageState createState() => _RestaurantDashboardPageState();
}

class _RestaurantDashboardPageState extends State<RestaurantDashboardPage> {
  String? _userId;
  bool _isLoading = true;
  bool _localeInitialized = false; // ✅ Ajouter cette variable

  // Statistiques du jour
  int _todayOrders = 0;
  double _todayRevenue = 0;
  int _pendingOrders = 0;
  int _completedOrders = 0;
  double _averageTicket = 0;

  // Statistiques par mode de paiement
  Map<String, double> _paymentMethods = {};

  // Statistiques par catégorie
  Map<String, CategorySales> _categorySales = {};

  // Top serveurs
  List<WaiterPerformance> _topWaiters = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      // ✅ Initialiser les locales en premier
      if (!_localeInitialized) {
        await initializeDateFormatting('fr_FR', null);
        _localeInitialized = true;
      }

      _userId = await getConnectedUserAdminId();
      await _loadDashboardData();
    } catch (e) {
      print('❌ Erreur initialisation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboardData() async {
    if (_userId == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .where('userId', isEqualTo: _userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final orders = snapshot.docs.map((doc) => RestaurantOrder.fromFirestore(doc)).toList();

      _calculateStatistics(orders);
    } catch (e) {
      print('❌ Erreur chargement données: $e');
    }
  }

  void _calculateStatistics(List<RestaurantOrder> orders) {
    _todayOrders = orders.length;
    _todayRevenue = 0;
    _pendingOrders = 0;
    _completedOrders = 0;
    _paymentMethods.clear();
    _categorySales.clear();

    Map<String, WaiterPerformance> waiterStats = {};

    for (var order in orders) {
      // Revenus totaux (seulement les commandes payées)
      if (order.status == 'payée') {
        _todayRevenue += order.total;
        _completedOrders++;

        // Stats par mode de paiement
        final method = order.paymentMethod.isEmpty ? 'Non spécifié' : order.paymentMethod;
        _paymentMethods[method] = (_paymentMethods[method] ?? 0) + order.total;

        // Stats par serveur
        if (order.waiterId != null && order.waiterId!.isNotEmpty) {
          if (!waiterStats.containsKey(order.waiterId)) {
            waiterStats[order.waiterId!] = WaiterPerformance(
              waiterId: order.waiterId!,
              orderCount: 0,
              totalRevenue: 0,
            );
          }
          waiterStats[order.waiterId!]!.orderCount++;
          waiterStats[order.waiterId!]!.totalRevenue += order.total;
        }
      }

      // Commandes en attente
      if (order.status == 'en_cours' || order.status == 'terminée') {
        _pendingOrders++;
      }

      // Stats par catégorie
      for (var item in order.items) {
        if (!_categorySales.containsKey(item.category)) {
          _categorySales[item.category] = CategorySales(
            category: item.category,
            quantity: 0,
            revenue: 0,
          );
        }
        _categorySales[item.category]!.quantity += item.quantity;
        if (order.status == 'payée') {
          _categorySales[item.category]!.revenue += item.totalPrice;
        }
      }
    }

    // Calculer ticket moyen
    _averageTicket = _completedOrders > 0 ? _todayRevenue / _completedOrders : 0;

    // Top 5 serveurs
    _topWaiters = waiterStats.values.toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    if (_topWaiters.length > 5) {
      _topWaiters = _topWaiters.sublist(0, 5);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text('Dashboard Restaurant'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date du jour
              _buildDateHeader(),
              const SizedBox(height: 20),

              // Statistiques principales
              _buildMainStats(),
              const SizedBox(height: 20),

              // Graphiques et détails
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonne gauche
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildPaymentMethodsCard(),
                        const SizedBox(height: 16),
                        _buildCategorySalesCard(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Colonne droite
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildTopWaitersCard(),
                        const SizedBox(height: 16),
                        _buildQuickActionsCard(),
                      ],
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

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // ✅ Utiliser le formatage seulement si les locales sont initialisées
                _localeInitialized
                    ? DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(DateTime.now())
                    : DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rapport en temps réel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ... Le reste du code reste identique ...

  Widget _buildMainStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Commandes',
            '$_todayOrders',
            Icons.receipt_long,
            Colors.blue,
            subtitle: '$_pendingOrders en attente',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Revenus',
            '${_todayRevenue.toStringAsFixed(0)} F',
            Icons.attach_money,
            Colors.green,
            subtitle: '$_completedOrders payées',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Ticket Moyen',
            '${_averageTicket.toStringAsFixed(0)} F',
            Icons.trending_up,
            Colors.orange,
            subtitle: 'Par commande',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'En Attente',
            '$_pendingOrders',
            Icons.pending_actions,
            Colors.purple,
            subtitle: 'À traiter',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color color, {
        String? subtitle,
      }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Modes de Paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_paymentMethods.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Aucune donnée disponible'),
              ),
            )
          else
            ..._paymentMethods.entries.map((entry) {
              final percentage = _todayRevenue > 0
                  ? (entry.value / _todayRevenue * 100)
                  : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${entry.value.toStringAsFixed(0)} F (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategorySalesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Ventes par Catégorie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_categorySales.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Aucune donnée disponible'),
              ),
            )
          else
            ..._categorySales.values.map((category) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(Icons.restaurant_menu, color: Colors.orange),
                  ),
                  title: Text(
                    category.category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${category.quantity} articles vendus'),
                  trailing: Text(
                    '${category.revenue.toStringAsFixed(0)} F',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopWaitersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Top Serveurs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_topWaiters.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Aucune donnée disponible'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topWaiters.length,
              itemBuilder: (context, index) {
                final waiter = _topWaiters[index];
                return FutureBuilder<String>(
                  future: _getWaiterName(waiter.waiterId),
                  builder: (context, snapshot) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: index == 0
                              ? Colors.amber.shade100
                              : Colors.blue.shade100,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: index == 0 ? Colors.amber : Colors.blue,
                            ),
                          ),
                        ),
                        title: Text(
                          snapshot.data ?? 'Chargement...',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${waiter.orderCount} commandes'),
                        trailing: Text(
                          '${waiter.totalRevenue.toStringAsFixed(0)} F',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch, color: Colors.purple, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Actions Rapides',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildQuickActionButton(
            'Nouvelle Commande',
            Icons.add_shopping_cart,
            Colors.teal,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CashierRestaurantPage(initialTab: 0),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Encaissements',
            Icons.point_of_sale,
            Colors.blue,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CashierRestaurantPage(initialTab: 1),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Rapports',
            Icons.assessment,
            Colors.orange,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CashierRestaurantPage(initialTab: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        minimumSize: const Size(double.infinity, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(0.3), width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
        final fullName = '$prenom $nom'.trim();
        return fullName.isNotEmpty ? fullName : 'Serveur';
      }
    } catch (e) {
      print('Erreur récupération nom serveur: $e');
    }
    return 'Serveur';
  }
}

// Classes de données
class CategorySales {
  final String category;
  int quantity;
  double revenue;

  CategorySales({
    required this.category,
    required this.quantity,
    required this.revenue,
  });
}

class WaiterPerformance {
  final String waiterId;
  int orderCount;
  double totalRevenue;

  WaiterPerformance({
    required this.waiterId,
    required this.orderCount,
    required this.totalRevenue,
  });
}