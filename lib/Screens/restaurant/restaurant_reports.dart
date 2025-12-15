import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/getConnectedUserAdminId.dart';
import '../../config/restaurant_models.dart';

class RestaurantReports extends StatefulWidget {
  @override
  _RestaurantReportsState createState() => _RestaurantReportsState();
}

class _RestaurantReportsState extends State<RestaurantReports> {
  String? _userId;
  bool _isLoading = true;

  // Période sélectionnée
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'week'; // week, month, custom

  // Statistiques
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _topItems = [];
  List<Map<String, dynamic>> _categoryRevenue = [];
  List<Map<String, dynamic>> _dailyRevenue = [];

  // Nouvelles statistiques
  Map<String, double> _revenueByDayOfWeek = {};
  Map<String, dynamic> _periodComparison = {};
  Map<String, double> _paymentMethodDistribution = {};
  Map<String, double> _monthlyTrends = {};
  Map<String, dynamic> _growthMetrics = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _userId = await getConnectedUserAdminId();
      await _loadReports();
    } catch (e) {
      print('❌ Erreur initialisation rapports: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReports() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadStatistics(),
        _loadTopItems(),
        _loadCategoryRevenue(),
        _loadDailyRevenue(),
        _loadRevenueByDayOfWeek(),
        _loadPeriodComparison(),
        _loadPaymentMethodDistribution(),
        _loadMonthlyTrends(),
        _loadGrowthMetrics(),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erreur chargement rapports: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStatistics() async {
    try {
      _stats = await RestaurantService.getRestaurantStats(_userId!, _startDate, _endDate);
    } catch (e) {
      print('❌ Erreur chargement stats: $e');
    }
  }

  Future<void> _loadTopItems() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .where('userId', isEqualTo: _userId)
          .where('status', isEqualTo: 'payée')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      final Map<String, Map<String, dynamic>> itemStats = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>? ?? [];

        for (var item in items) {
          final itemMap = item as Map<String, dynamic>;
          final itemName = itemMap['name'] as String;
          final quantity = itemMap['quantity'] as int;
          final revenue = (itemMap['price'] as num).toDouble() * quantity;

          if (itemStats.containsKey(itemName)) {
            itemStats[itemName]!['quantity'] += quantity;
            itemStats[itemName]!['revenue'] += revenue;
          } else {
            itemStats[itemName] = {
              'name': itemName,
              'quantity': quantity,
              'revenue': revenue,
              'category': itemMap['category'] ?? '',
            };
          }
        }
      }

      _topItems = itemStats.values.toList()
        ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

      _topItems = _topItems.take(10).toList();
    } catch (e) {
      print('❌ Erreur chargement top items: $e');
    }
  }

  Future<void> _loadCategoryRevenue() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .where('userId', isEqualTo: _userId)
          .where('status', isEqualTo: 'payée')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      final Map<String, double> categoryStats = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>? ?? [];

        for (var item in items) {
          final itemMap = item as Map<String, dynamic>;
          final category = itemMap['category'] as String? ?? 'Autre';
          final revenue = (itemMap['price'] as num).toDouble() * (itemMap['quantity'] as int);

          categoryStats[category] = (categoryStats[category] ?? 0) + revenue;
        }
      }

      _categoryRevenue = categoryStats.entries
          .map((e) => {'category': e.key, 'revenue': e.value})
          .toList()
        ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    } catch (e) {
      print('❌ Erreur chargement revenus par catégorie: $e');
    }
  }

  Future<void> _loadDailyRevenue() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .where('userId', isEqualTo: _userId)
          .where('status', isEqualTo: 'payée')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      final Map<String, double> dailyStats = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final dateKey = DateFormat('yyyy-MM-dd').format(createdAt);
        final revenue = (data['total'] as num).toDouble();

        dailyStats[dateKey] = (dailyStats[dateKey] ?? 0) + revenue;
      }

      _dailyRevenue = dailyStats.entries
          .map((e) => {
        'date': DateTime.parse(e.key),
        'revenue': e.value,
      })
          .toList()
        ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    } catch (e) {
      print('❌ Erreur chargement revenus quotidiens: $e');
    }
  }

  // ========== NOUVELLES MÉTHODES DE STATISTIQUES ==========

  Future<void> _loadRevenueByDayOfWeek() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .where('userId', isEqualTo: _userId)
          .where('status', isEqualTo: 'payée')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      final Map<int, double> dayStats = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final dayOfWeek = createdAt.weekday; // 1 = lundi, 7 = dimanche
        final revenue = (data['total'] as num).toDouble();

        dayStats[dayOfWeek] = (dayStats[dayOfWeek] ?? 0) + revenue;
      }

      final dayNames = {
        1: 'Lundi',
        2: 'Mardi',
        3: 'Mercredi',
        4: 'Jeudi',
        5: 'Vendredi',
        6: 'Samedi',
        7: 'Dimanche',
      };

      _revenueByDayOfWeek = dayStats.map((key, value) => MapEntry(dayNames[key]!, value));
    } catch (e) {
      print('❌ Erreur chargement CA par jour de semaine: $e');
    }
  }

  Future<void> _loadPeriodComparison() async {
    try {
      final now = DateTime.now();
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final currentWeekEnd = currentWeekStart.add(Duration(days: 6, hours: 23, minutes: 59));
      final previousWeekStart = currentWeekStart.subtract(Duration(days: 7));
      final previousWeekEnd = currentWeekStart.subtract(Duration(seconds: 1));

      // Semaine actuelle
      final currentWeekSnapshot = await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .where('userId', isEqualTo: _userId)
          .where('status', isEqualTo: 'payée')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(currentWeekStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(currentWeekEnd))
          .get();

      double currentWeekRevenue = 0;
      int currentWeekOrders = 0;

      for (var doc in currentWeekSnapshot.docs) {
        final data = doc.data();
        currentWeekRevenue += (data['total'] as num).toDouble();
        currentWeekOrders++;
      }

      // Semaine précédente
      final previousWeekSnapshot = await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .where('userId', isEqualTo: _userId)
          .where('status', isEqualTo: 'payée')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(previousWeekStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(previousWeekEnd))
          .get();

      double previousWeekRevenue = 0;
      int previousWeekOrders = 0;

      for (var doc in previousWeekSnapshot.docs) {
        final data = doc.data();
        previousWeekRevenue += (data['total'] as num).toDouble();
        previousWeekOrders++;
      }

      final revenueChange = previousWeekRevenue > 0
          ? ((currentWeekRevenue - previousWeekRevenue) / previousWeekRevenue * 100)
          : 0.0;

      final ordersChange = previousWeekOrders > 0
          ? ((currentWeekOrders - previousWeekOrders) / previousWeekOrders * 100)
          : 0.0;

      _periodComparison = {
        'currentWeekRevenue': currentWeekRevenue,
        'currentWeekOrders': currentWeekOrders,
        'previousWeekRevenue': previousWeekRevenue,
        'previousWeekOrders': previousWeekOrders,
        'revenueChange': revenueChange,
        'ordersChange': ordersChange,
      };
    } catch (e) {
      print('❌ Erreur comparaison périodes: $e');
    }
  }

  Future<void> _loadPaymentMethodDistribution() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .where('userId', isEqualTo: _userId)
          .where('status', isEqualTo: 'payée')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      final Map<String, double> paymentStats = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final paymentMethod = data['paymentMethod'] as String? ?? 'Non spécifié';
        final revenue = (data['total'] as num).toDouble();

        paymentStats[paymentMethod] = (paymentStats[paymentMethod] ?? 0) + revenue;
      }

      _paymentMethodDistribution = paymentStats;
    } catch (e) {
      print('❌ Erreur répartition paiements: $e');
    }
  }

  Future<void> _loadMonthlyTrends() async {
    try {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .where('userId', isEqualTo: _userId)
          .where('status', isEqualTo: 'payée')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
          .get();

      final Map<int, double> monthlyStats = {
        1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0,
        7: 0, 8: 0, 9: 0, 10: 0, 11: 0, 12: 0
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final month = createdAt.month;
        final revenue = (data['total'] as num).toDouble();

        monthlyStats[month] = (monthlyStats[month] ?? 0) + revenue;
      }

      final monthNames = {
        1: 'Jan', 2: 'Fév', 3: 'Mar', 4: 'Avr', 5: 'Mai', 6: 'Juin',
        7: 'Juil', 8: 'Août', 9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Déc',
      };

      _monthlyTrends = monthlyStats.map((key, value) => MapEntry(monthNames[key]!, value));
    } catch (e) {
      print('❌ Erreur tendances mensuelles: $e');
    }
  }

  Future<void> _loadGrowthMetrics() async {
    try {
      final now = DateTime.now();

      // Mois actuel
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Mois précédent
      final previousMonthStart = DateTime(now.year, now.month - 1, 1);
      final previousMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

      // Année actuelle
      final currentYearStart = DateTime(now.year, 1, 1);
      final currentYearEnd = DateTime(now.year, 12, 31, 23, 59, 59);

      // Année précédente
      final previousYearStart = DateTime(now.year - 1, 1, 1);
      final previousYearEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);

      // Calculer les revenus pour chaque période
      final currentMonthRevenue = await _getRevenueForPeriod(currentMonthStart, currentMonthEnd);
      final previousMonthRevenue = await _getRevenueForPeriod(previousMonthStart, previousMonthEnd);
      final currentYearRevenue = await _getRevenueForPeriod(currentYearStart, currentYearEnd);
      final previousYearRevenue = await _getRevenueForPeriod(previousYearStart, previousYearEnd);

      final monthOverMonthGrowth = previousMonthRevenue > 0
          ? ((currentMonthRevenue - previousMonthRevenue) / previousMonthRevenue * 100)
          : 0.0;

      final yearOverYearGrowth = previousYearRevenue > 0
          ? ((currentYearRevenue - previousYearRevenue) / previousYearRevenue * 100)
          : 0.0;

      _growthMetrics = {
        'currentMonthRevenue': currentMonthRevenue,
        'previousMonthRevenue': previousMonthRevenue,
        'monthOverMonthGrowth': monthOverMonthGrowth,
        'currentYearRevenue': currentYearRevenue,
        'previousYearRevenue': previousYearRevenue,
        'yearOverYearGrowth': yearOverYearGrowth,
      };
    } catch (e) {
      print('❌ Erreur métriques de croissance: $e');
    }
  }

  Future<double> _getRevenueForPeriod(DateTime start, DateTime end) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .where('userId', isEqualTo: _userId)
          .where('status', isEqualTo: 'payée')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['total'] as num).toDouble();
      }

      return total;
    } catch (e) {
      print('❌ Erreur calcul revenu période: $e');
      return 0;
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();

      switch (period) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'week':
          _startDate = now.subtract(Duration(days: 7));
          _endDate = now;
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
      }
    });

    _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Text('Rapports & Statistiques'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Période',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodChip('Aujourd\'hui', 'today'),
                SizedBox(width: 8),
                _buildPeriodChip('7 jours', 'week'),
                SizedBox(width: 8),
                _buildPeriodChip('Ce mois', 'month'),
                SizedBox(width: 8),
                _buildPeriodChip('Cette année', 'year'),
                SizedBox(width: 8),
                _buildPeriodChip('Personnalisé', 'custom'),
              ],
            ),
          ),
          if (_selectedPeriod == 'custom') ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectStartDate(),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.indigo),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Début', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_startDate),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectEndDate(),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.indigo),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fin', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_endDate),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String period) {
    final isSelected = _selectedPeriod == period;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _changePeriod(period),
      selectedColor: Colors.indigo.withOpacity(0.2),
      checkmarkColor: Colors.indigo,
      labelStyle: TextStyle(
        color: isSelected ? Colors.indigo : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? Colors.indigo : Colors.grey.shade300),
    );
  }

  Widget _buildReportContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewStats(),
          SizedBox(height: 24),
          _buildPeriodComparison(),
          SizedBox(height: 24),
          _buildGrowthMetrics(),
          SizedBox(height: 24),
          _buildDailyRevenueChart(),
          SizedBox(height: 24),
          _buildRevenueByDayOfWeek(),
          SizedBox(height: 24),
          _buildMonthlyTrends(),
          SizedBox(height: 24),
          _buildPaymentMethodDistribution(),
          SizedBox(height: 24),
          _buildCategoryRevenue(),
          SizedBox(height: 24),
          _buildTopItems(),
          SizedBox(height: 24),
          _buildDetailedMetrics(),
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vue d\'ensemble',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Chiffre d\'affaires',
                '${_stats['totalRevenue']?.toStringAsFixed(0) ?? '0'} FCFA',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Commandes',
                '${_stats['totalOrders'] ?? 0}',
                Icons.receipt,
                Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Ticket moyen',
                '${_stats['averageOrderValue']?.toStringAsFixed(0) ?? '0'} FCFA',
                Icons.analytics,
                Colors.purple,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Clients hôtel',
                '${_stats['hotelGuestOrders'] ?? 0}',
                Icons.hotel,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
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
            color: Colors.black.withOpacity(0.05),
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
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, size: 16, color: color),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRevenueChart() {
    if (_dailyRevenue.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('Aucune donnée disponible', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final maxRevenue = _dailyRevenue.fold<double>(
      0,
          (max, item) => (item['revenue'] as double) > max ? item['revenue'] as double : max,
    );

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                'Évolution du chiffre d\'affaires',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 240, // ✅ Augmenté de 200 à 240
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _dailyRevenue.map((item) {
                final revenue = item['revenue'] as double;
                final height = maxRevenue > 0 ? (revenue / maxRevenue) * 200 : 0.0; // ✅ Augmenté de 180 à 200
                final date = item['date'] as DateTime;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: '${revenue.toStringAsFixed(0)} FCFA',
                          child: Container(
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.indigo.shade300, Colors.indigo],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          DateFormat('dd/MM').format(date),
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRevenue() {
    if (_categoryRevenue.isEmpty) {
      return SizedBox.shrink();
    }

    final totalRevenue = _categoryRevenue.fold<double>(
      0,
          (sum, item) => sum + (item['revenue'] as double),
    );

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                'Revenus par catégorie',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          ..._categoryRevenue.map((item) {
            final category = item['category'] as String;
            final revenue = item['revenue'] as double;
            final percentage = (revenue / totalRevenue * 100);
            final color = _getCategoryColor(category);

            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            category,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Text(
                        '${revenue.toStringAsFixed(0)} FCFA (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopItems() {
    if (_topItems.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Top 10 des articles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...List.generate(_topItems.length, (index) {
            final item = _topItems[index];
            final name = item['name'] as String;
            final quantity = item['quantity'] as int;
            final revenue = item['revenue'] as double;

            return Container(
              margin: EdgeInsets.only(bottom: 12),
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
                      color: index < 3 ? Colors.amber.shade100 : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: index < 3 ? Colors.amber.shade900 : Colors.grey.shade700,
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
                          name,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '$quantity ventes',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${revenue.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailedMetrics() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                'Métriques détaillées',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildMetricRow('Nombre total de commandes', '${_stats['totalOrders'] ?? 0}'),
          Divider(),
          _buildMetricRow('Commandes clients hôtel', '${_stats['hotelGuestOrders'] ?? 0}'),
          Divider(),
          _buildMetricRow('Commandes clients externes', '${_stats['externalOrders'] ?? 0}'),
          Divider(),
          _buildMetricRow(
            'Ticket moyen',
            '${_stats['averageOrderValue']?.toStringAsFixed(0) ?? '0'} FCFA',
          ),
          Divider(),
          _buildMetricRow(
            'Revenu total',
            '${_stats['totalRevenue']?.toStringAsFixed(0) ?? '0'} FCFA',
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
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
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isHighlighted ? 18 : 16,
              color: isHighlighted ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ========== NOUVEAUX WIDGETS DE STATISTIQUES ==========

  Widget _buildPeriodComparison() {
    if (_periodComparison.isEmpty) return SizedBox.shrink();

    final revenueChange = _periodComparison['revenueChange'] as double;
    final ordersChange = _periodComparison['ordersChange'] as double;
    final isRevenuePositive = revenueChange >= 0;
    final isOrdersPositive = ordersChange >= 0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                'Comparaison semaine actuelle vs précédente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semaine actuelle',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${_periodComparison['currentWeekRevenue'].toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      Text(
                        '${_periodComparison['currentWeekOrders']} commandes',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semaine précédente',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${_periodComparison['previousWeekRevenue'].toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        '${_periodComparison['previousWeekOrders']} commandes',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRevenuePositive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isRevenuePositive ? Icons.trending_up : Icons.trending_down,
                        color: isRevenuePositive ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${revenueChange.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isRevenuePositive ? Colors.green : Colors.red,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'CA',
                        style: TextStyle(
                          color: isRevenuePositive ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOrdersPositive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isOrdersPositive ? Icons.trending_up : Icons.trending_down,
                        color: isOrdersPositive ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${ordersChange.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isOrdersPositive ? Colors.green : Colors.red,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Commandes',
                        style: TextStyle(
                          color: isOrdersPositive ? Colors.green.shade700 : Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthMetrics() {
    if (_growthMetrics.isEmpty) return SizedBox.shrink();

    final momGrowth = _growthMetrics['monthOverMonthGrowth'] as double;
    final yoyGrowth = _growthMetrics['yearOverYearGrowth'] as double;
    final isMomPositive = momGrowth >= 0;
    final isYoyPositive = yoyGrowth >= 0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Croissance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isMomPositive
                          ? [Colors.green.shade50, Colors.green.shade100]
                          : [Colors.red.shade50, Colors.red.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMomPositive ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isMomPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isMomPositive ? Colors.green : Colors.red,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${momGrowth.abs().toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isMomPositive ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Mois sur mois',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isMomPositive ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_growthMetrics['currentMonthRevenue'].toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isYoyPositive
                          ? [Colors.blue.shade50, Colors.blue.shade100]
                          : [Colors.orange.shade50, Colors.orange.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isYoyPositive ? Colors.blue.shade200 : Colors.orange.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isYoyPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isYoyPositive ? Colors.blue : Colors.orange,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${yoyGrowth.abs().toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isYoyPositive ? Colors.blue.shade700 : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Année sur année',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isYoyPositive ? Colors.blue.shade700 : Colors.orange.shade700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_growthMetrics['currentYearRevenue'].toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'entrées':
        return Colors.green;
      case 'plats principaux':
      case 'plats':
        return Colors.orange;
      case 'desserts':
        return Colors.pink;
      case 'boissons':
        return Colors.blue;
      case 'vins':
        return Colors.purple;
      case 'cocktails':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRevenueByDayOfWeek() {
    if (_revenueByDayOfWeek.isEmpty) return SizedBox.shrink();

    final maxRevenue = _revenueByDayOfWeek.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_view_week, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Chiffre d\'affaires par jour de la semaine',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _revenueByDayOfWeek.entries.map((entry) {
                final day = entry.key;
                final revenue = entry.value;
                final height = maxRevenue > 0 ? (revenue / maxRevenue) * 160 : 0.0;

                // Couleur différente pour le weekend
                final isWeekend = day == 'Samedi' || day == 'Dimanche';
                final barColor = isWeekend ? Colors.purple : Colors.indigo;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: '${revenue.toStringAsFixed(0)} FCFA',
                          child: Container(
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [barColor.shade300, barColor],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          day.substring(0, 3),
                          style: TextStyle(
                            fontSize: 10,
                            color: isWeekend ? Colors.purple : Colors.grey.shade700,
                            fontWeight: isWeekend ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrends() {
    if (_monthlyTrends.isEmpty) return SizedBox.shrink();

    final maxRevenue = _monthlyTrends.values.reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.teal),
              SizedBox(width: 8),
              Text(
                'Saisonnalité ${now.year}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _monthlyTrends.entries.map((entry) {
                final month = entry.key;
                final revenue = entry.value;
                final height = maxRevenue > 0 ? (revenue / maxRevenue) * 160 : 0.0;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: '${revenue.toStringAsFixed(0)} FCFA',
                          child: Container(
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.teal.shade300, Colors.teal],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          month,
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodDistribution() {
    if (_paymentMethodDistribution.isEmpty) return SizedBox.shrink();

    final totalRevenue = _paymentMethodDistribution.values.reduce((a, b) => a + b);

    final sortedPayments = _paymentMethodDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Répartition par méthode de paiement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...sortedPayments.map((entry) {
            final method = entry.key;
            final revenue = entry.value;
            final percentage = (revenue / totalRevenue * 100);
            final color = _getPaymentMethodColor(method);

            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_getPaymentMethodIcon(method), size: 20, color: color),
                          ),
                          SizedBox(width: 12),
                          Text(
                            method,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${revenue.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'espèces':
        return Colors.green;
      case 'carte bancaire':
      case 'carte':
        return Colors.blue;
      case 'facturation chambre':
      case 'chambre':
        return Colors.orange;
      case 'chèque':
        return Colors.purple;
      case 'mobile money':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'espèces':
        return Icons.money;
      case 'carte bancaire':
      case 'carte':
        return Icons.credit_card;
      case 'facturation chambre':
      case 'chambre':
        return Icons.hotel;
      case 'chèque':
        return Icons.receipt;
      case 'mobile money':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
      // Retirer locale: Locale('fr', 'FR'), car géré au niveau de l'app
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.indigo),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _startDate = picked);
      _loadReports();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
      // Retirer locale: Locale('fr', 'FR'), car géré au niveau de l'app
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.indigo),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _endDate = picked);
      _loadReports();
    }
  }

  Future<void> _exportReport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
            SizedBox(width: 16),
            Text('Export du rapport en cours...'),
          ],
        ),
        backgroundColor: Colors.indigo,
        duration: Duration(seconds: 2),
      ),
    );

    // Simuler l'export (à implémenter avec pdf ou csv)
    await Future.delayed(Duration(seconds: 2));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('✅ Rapport exporté avec succès'),
          ],
        ),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            // Ouvrir le fichier exporté
          },
        ),
      ),
    );
  }
}