import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Cette fonction récupère les réservations depuis Firebase et calcule
/// le taux d'occupation pour chaque jour de la semaine
Future<List<FlSpot>> calculerOccupationChambres(
    DateTime dateDebut, {
      int nombreTotalChambres = 0,
    }) async {
  // Vérifier que le nombre total de chambres est valide
  if (nombreTotalChambres <= 0) {
    // Récupérer le nombre total de chambres depuis Firebase si non fourni
    final snapshotChambres = await FirebaseFirestore.instance
        .collection('rooms')
        .get();

    nombreTotalChambres = snapshotChambres.docs.length;

    // Si toujours 0, utiliser une valeur par défaut
    if (nombreTotalChambres <= 0) {
      nombreTotalChambres = 1; // Pour éviter division par zéro
    }
  }

  // Calculer la date de fin (7 jours après la date de début)
  final dateFin = dateDebut.add(const Duration(days: 6));
  final User? user = FirebaseAuth.instance.currentUser;
  // Récupérer toutes les réservations qui chevauchent la période
  final snapshotReservations = await FirebaseFirestore.instance
      .collection('bookings')
      .where('userId', isEqualTo: user?.uid) // Utiliser user.uid pour l'I
      .where('checkInDate', isLessThanOrEqualTo: dateFin)
      .where('checkOutDate', isGreaterThanOrEqualTo: dateDebut)
      .get();

  // Initialiser les compteurs pour chaque jour (0 = lundi, 6 = dimanche)
  final List<int> chambresOccupees = List.filled(7, 0);

  // Pour chaque réservation, compter les chambres occupées par jour
  for (var doc in snapshotReservations.docs) {
    final reservation = doc.data();

    // Convertir les timestamps Firestore en DateTime
    final dateArrivee = (reservation['checkInDate'] as Timestamp).toDate();
    final dateDepart = (reservation['checkOutDate'] as Timestamp).toDate();

    // Pour chaque jour entre l'arrivée et le départ
    for (var jour = dateDebut; jour.isBefore(dateFin.add(const Duration(days: 1))); jour = jour.add(const Duration(days: 1))) {
      // Vérifier si le jour est entre la date d'arrivée et la date de départ
      if (jour.isAfter(dateArrivee.subtract(const Duration(days: 1))) &&
          jour.isBefore(dateDepart)) {
        // Calculer l'index du jour (0 pour lundi, 6 pour dimanche)
        final indexJour = jour.weekday - 1;
        // Incrémenter le compteur pour ce jour
        if (indexJour >= 0 && indexJour < 7) {
          chambresOccupees[indexJour]++;
        }
      }
    }
  }

  // Convertir en pourcentage d'occupation et en FlSpot pour le graphique
  final List<FlSpot> donneesTauxOccupation = [];

  for (int i = 0; i < 7; i++) {
    final pourcentage = (chambresOccupees[i] / nombreTotalChambres) * 100;
    donneesTauxOccupation.add(FlSpot(i.toDouble(), pourcentage));
  }

  return donneesTauxOccupation;
}

/// Fonction pour mettre à jour le widget OccupancyChart avec les données
/// de la semaine actuelle
Future<void> mettreAJourGraphiqueOccupation(
    Function(List<FlSpot>) onDonneesChargees,
    ) async {
  // Trouver le lundi de la semaine actuelle
  final aujourdhui = DateTime.now();
  final debutSemaine = aujourdhui.subtract(Duration(days: aujourdhui.weekday - 1));

  // Récupérer les données d'occupation
  final donnees = await calculerOccupationChambres(debutSemaine);

  // Appeler le callback avec les données
  onDonneesChargees(donnees);
}

enum OccupancyPeriodFilter { jour, semaine, mois }

/// Widget moderne OccupancyChart avec filtres
class OccupancyChartAvecDonnees extends StatefulWidget {
  const OccupancyChartAvecDonnees({Key? key}) : super(key: key);

  @override
  State<OccupancyChartAvecDonnees> createState() => _OccupancyChartAvecDonneesState();
}

class _OccupancyChartAvecDonneesState extends State<OccupancyChartAvecDonnees> {
  List<FlSpot> occupancyData = [];
  bool isLoading = true;
  OccupancyPeriodFilter _selectedFilter = OccupancyPeriodFilter.semaine;
  double _averageOccupancy = 0;

  final List<Color> gradientColors = [
    const Color(0xFF000080), // Navy
    const Color(0xFF1E88E5),
  ];

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() {
      isLoading = true;
    });

    try {
      final aujourdhui = DateTime.now();
      List<FlSpot> spots = [];
      double totalOccupancy = 0;

      switch (_selectedFilter) {
        case OccupancyPeriodFilter.jour:
          // Afficher les 24 dernières heures
          for (int i = 23; i >= 0; i--) {
            final hour = aujourdhui.subtract(Duration(hours: i));
            final occupancy = await _fetchHourlyOccupancy(hour);
            spots.add(FlSpot((23 - i).toDouble(), occupancy));
            totalOccupancy += occupancy;
          }
          break;

        case OccupancyPeriodFilter.semaine:
          // Afficher les 7 derniers jours
          for (int i = 6; i >= 0; i--) {
            final day = aujourdhui.subtract(Duration(days: i));
            final occupancy = await _fetchDailyOccupancy(day);
            spots.add(FlSpot((6 - i).toDouble(), occupancy));
            totalOccupancy += occupancy;
          }
          break;

        case OccupancyPeriodFilter.mois:
          // Afficher les 30 derniers jours
          for (int i = 29; i >= 0; i--) {
            final day = aujourdhui.subtract(Duration(days: i));
            final occupancy = await _fetchDailyOccupancy(day);
            spots.add(FlSpot((29 - i).toDouble(), occupancy));
            totalOccupancy += occupancy;
          }
          break;
      }

      setState(() {
        occupancyData = spots;
        _averageOccupancy = spots.isNotEmpty ? totalOccupancy / spots.length : 0;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<double> _fetchHourlyOccupancy(DateTime hour) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      // Récupérer le nombre total de chambres
      final snapshotChambres = await FirebaseFirestore.instance
          .collection('rooms')
          .where('userId', isEqualTo: user?.uid)
          .get();

      final nombreTotalChambres = snapshotChambres.docs.length;
      if (nombreTotalChambres <= 0) return 0.0;

      // Récupérer les réservations pour cette heure
      final hourStart = DateTime(hour.year, hour.month, hour.day, hour.hour);
      final hourEnd = DateTime(hour.year, hour.month, hour.day, hour.hour, 59, 59);

      final snapshotReservations = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user?.uid)
          .where('checkInDate', isLessThanOrEqualTo: hourEnd)
          .where('checkOutDate', isGreaterThanOrEqualTo: hourStart)
          .get();

      return (snapshotReservations.docs.length / nombreTotalChambres) * 100;
    } catch (e) {
      print('Erreur lors du calcul du taux d\'occupation horaire: $e');
      return 0.0;
    }
  }

  Future<double> _fetchDailyOccupancy(DateTime day) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      // Récupérer le nombre total de chambres
      final snapshotChambres = await FirebaseFirestore.instance
          .collection('rooms')
          .where('userId', isEqualTo: user?.uid)
          .get();

      final nombreTotalChambres = snapshotChambres.docs.length;
      if (nombreTotalChambres <= 0) return 0.0;

      // Récupérer les réservations pour ce jour
      final dateDebut = DateTime(day.year, day.month, day.day);
      final dateFin = DateTime(day.year, day.month, day.day, 23, 59, 59);

      final snapshotReservations = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user?.uid)
          .where('checkInDate', isLessThanOrEqualTo: dateFin)
          .where('checkOutDate', isGreaterThanOrEqualTo: dateDebut)
          .get();

      return (snapshotReservations.docs.length / nombreTotalChambres) * 100;
    } catch (e) {
      print('Erreur lors du calcul du taux d\'occupation: $e');
      return 0.0;
    }
  }

  String _getPeriodLabel() {
    switch (_selectedFilter) {
      case OccupancyPeriodFilter.jour:
        return "Dernières 24 heures";
      case OccupancyPeriodFilter.semaine:
        return "7 derniers jours";
      case OccupancyPeriodFilter.mois:
        return "30 derniers jours";
    }
  }

  String _getBottomTitle(double value) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case OccupancyPeriodFilter.jour:
        final hour = now.subtract(Duration(hours: 23 - value.toInt()));
        return '${hour.hour}h';
      case OccupancyPeriodFilter.semaine:
        final day = now.subtract(Duration(days: 6 - value.toInt()));
        final weekDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        return weekDays[day.weekday - 1];
      case OccupancyPeriodFilter.mois:
        if (value.toInt() % 5 == 0) {
          final day = now.subtract(Duration(days: 29 - value.toInt()));
          return DateFormat('d/M').format(day);
        }
        return '';
    }
  }

  double _getMaxX() {
    switch (_selectedFilter) {
      case OccupancyPeriodFilter.jour:
        return 23;
      case OccupancyPeriodFilter.semaine:
        return 6;
      case OccupancyPeriodFilter.mois:
        return 29;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    "Taux d'occupation",
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
                    _buildFilterChip('J', OccupancyPeriodFilter.jour, isDark),
                    _buildFilterChip('S', OccupancyPeriodFilter.semaine, isDark),
                    _buildFilterChip('M', OccupancyPeriodFilter.mois, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Average occupancy display
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
                Icon(Icons.hotel, color: gradientColors[0], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Moyenne: ${_averageOccupancy.toStringAsFixed(1)}%',
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
                        horizontalInterval: 20,
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
                            interval: _selectedFilter == OccupancyPeriodFilter.mois ? 5 : 1,
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
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  '${value.toInt()}%',
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
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: occupancyData,
                          isCurved: true,
                          gradient: LinearGradient(colors: gradientColors),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: _selectedFilter != OccupancyPeriodFilter.mois,
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

  Widget _buildFilterChip(String label, OccupancyPeriodFilter filter, bool isDark) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
          _chargerDonnees();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF000080)
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