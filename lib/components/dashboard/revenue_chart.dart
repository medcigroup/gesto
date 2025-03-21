import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RevenueChart extends StatefulWidget {
  @override
  _RevenueChartState createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart> {
  List<FlSpot> revenueData =[];
  bool isLoading = true;

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
      List<FlSpot> spots =[];

      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final revenue = await _fetchDailyRevenue(day);
        spots.add(FlSpot((6 - i).toDouble(), revenue));
      }

      if (mounted) {
        setState(() {
          revenueData = spots;
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
  final User? user = FirebaseAuth.instance.currentUser; // Récupérer l'utilisateur connecté
  Future<double> _fetchDailyRevenue(DateTime day) async {
    try {
      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('customerId',isEqualTo: user?.uid)
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Revenus des 7 derniers jours",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.grey[800],
            ),
          ),
          Text(
            "Dernière semaine",
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 500, // Adjust based on your revenue range
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white, // Couleur forcée pour le test
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.white, // Couleur forcée pour le test
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final now = DateTime.now();
                        final day = now.subtract(Duration(days: 6 - value.toInt()));
                        final weekDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            weekDays[day.weekday - 1],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60, // Adjusted for currency
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            NumberFormat.compact().format(value),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : Colors.grey[300]!,
                  ),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                // maxY will be determined by the data
                lineBarsData: [
                  LineChartBarData(
                    spots: revenueData,
                    isCurved: true,
                    gradient: LinearGradient(colors: gradientColors),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: gradientColors[0],
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: gradientColors
                            .map((color) => color.withOpacity(0.3))
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
}



