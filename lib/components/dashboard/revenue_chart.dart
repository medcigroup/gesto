import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum PeriodFilter { jour, semaine, mois }

class RevenueChart extends StatefulWidget {
  @override
  _RevenueChartState createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart> {
  List<FlSpot> revenueData = [];
  bool isLoading = true;
  PeriodFilter _selectedFilter = PeriodFilter.semaine;
  double _maxRevenue = 0;
  double _totalRevenue = 0;

  final List<Color> gradientColors = [
    const Color(0xFF008000), // Green
    const Color(0xFF8FBC8F), // DarkSeaGreen
  ];

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    try {
      final now = DateTime.now();
      List<FlSpot> spots = [];
      double total = 0;
      double maxValue = 0;

      switch (_selectedFilter) {
        case PeriodFilter.jour:
          // Afficher les 24 dernières heures
          for (int i = 23; i >= 0; i--) {
            final hour = now.subtract(Duration(hours: i));
            final revenue = await _fetchHourlyRevenue(hour);
            spots.add(FlSpot((23 - i).toDouble(), revenue));
            total += revenue;
            if (revenue > maxValue) maxValue = revenue;
          }
          break;

        case PeriodFilter.semaine:
          // Afficher les 7 derniers jours
          for (int i = 6; i >= 0; i--) {
            final day = now.subtract(Duration(days: i));
            final revenue = await _fetchDailyRevenue(day);
            spots.add(FlSpot((6 - i).toDouble(), revenue));
            total += revenue;
            if (revenue > maxValue) maxValue = revenue;
          }
          break;

        case PeriodFilter.mois:
          // Afficher les 30 derniers jours
          for (int i = 29; i >= 0; i--) {
            final day = now.subtract(Duration(days: i));
            final revenue = await _fetchDailyRevenue(day);
            spots.add(FlSpot((29 - i).toDouble(), revenue));
            total += revenue;
            if (revenue > maxValue) maxValue = revenue;
          }
          break;
      }

      if (mounted) {
        setState(() {
          revenueData = spots;
          _maxRevenue = maxValue;
          _totalRevenue = total;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des données de revenus : $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  final User? user = FirebaseAuth.instance.currentUser;

  Future<double> _fetchHourlyRevenue(DateTime hour) async {
    try {
      final start = DateTime(hour.year, hour.month, hour.day, hour.hour);
      final end = DateTime(hour.year, hour.month, hour.day, hour.hour, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('customerId', isEqualTo: user?.uid)
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .where('type', isEqualTo: 'payment')
          .get();

      double totalRevenue = 0.0;
      for (var doc in snapshot.docs) {
        totalRevenue += (doc['amount'] as num).toDouble();
      }

      return totalRevenue;
    } catch (e) {
      print('Erreur lors du calcul du revenu horaire : $e');
      return 0.0;
    }
  }

  Future<double> _fetchDailyRevenue(DateTime day) async {
    try {
      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('customerId', isEqualTo: user?.uid)
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .where('type', isEqualTo: 'payment')
          .get();

      double totalRevenue = 0.0;
      for (var doc in snapshot.docs) {
        totalRevenue += (doc['amount'] as num).toDouble();
      }

      return totalRevenue;
    } catch (e) {
      print('Erreur lors du calcul du revenu journalier : $e');
      return 0.0;
    }
  }

  String _getPeriodLabel() {
    switch (_selectedFilter) {
      case PeriodFilter.jour:
        return "Dernières 24 heures";
      case PeriodFilter.semaine:
        return "7 derniers jours";
      case PeriodFilter.mois:
        return "30 derniers jours";
    }
  }

  String _getBottomTitle(double value) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case PeriodFilter.jour:
        final hour = now.subtract(Duration(hours: 23 - value.toInt()));
        return '${hour.hour}h';
      case PeriodFilter.semaine:
        final day = now.subtract(Duration(days: 6 - value.toInt()));
        final weekDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        return weekDays[day.weekday - 1];
      case PeriodFilter.mois:
        if (value.toInt() % 5 == 0) {
          final day = now.subtract(Duration(days: 29 - value.toInt()));
          return DateFormat('d/M').format(day);
        }
        return '';
    }
  }

  double _getMaxX() {
    switch (_selectedFilter) {
      case PeriodFilter.jour:
        return 23;
      case PeriodFilter.semaine:
        return 6;
      case PeriodFilter.mois:
        return 29;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedTotal = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 0,
    ).format(_totalRevenue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF263238) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statistiques et filtres
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Revenus",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPeriodLabel(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Filtres modernes avec chips
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildFilterChip('J', PeriodFilter.jour, isDark),
                    _buildFilterChip('S', PeriodFilter.semaine, isDark),
                    _buildFilterChip('M', PeriodFilter.mois, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total revenue display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: gradientColors[0].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: gradientColors[0].withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: gradientColors[0], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Total: $formattedTotal FCFA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: gradientColors[0],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Graphique
          SizedBox(
            height: 250,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: _maxRevenue > 0 ? _maxRevenue / 4 : 500,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _selectedFilter == PeriodFilter.mois ? 5 : 1,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _getBottomTitle(value),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  NumberFormat.compact(locale: 'fr').format(value),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      minX: 0,
                      maxX: _getMaxX(),
                      minY: 0,
                      maxY: _maxRevenue * 1.2 > 0 ? _maxRevenue * 1.2 : 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: revenueData,
                          isCurved: true,
                          gradient: LinearGradient(colors: gradientColors),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: _selectedFilter != PeriodFilter.mois,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: gradientColors[0],
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: gradientColors
                                  .map((color) => color.withOpacity(0.2))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, PeriodFilter filter, bool isDark) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
          _loadRevenueData();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF008000)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}



