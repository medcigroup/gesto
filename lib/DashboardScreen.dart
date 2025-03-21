

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gesto/widgets/side_menu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:intl/intl.dart';

// Composants importés
import '../components/dashboard/occupancy_chart.dart';
import '../components/dashboard/revenue_chart.dart';
import '../components/dashboard/recent_bookings.dart';
import '../components/dashboard/tasks_list.dart';
import 'Screens/RoomsPage.dart';
import 'components/dashboard/StatCard.dart';
import 'config/AuthService.dart';
import 'config/UserModel.dart';
import 'config/calculerOccupationChambres.dart';
import 'config/routes.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool _isDarkMode = false;
  UserModel? _userModel;
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  double _tauxOccupationActuel = 0.0;
  double _revenuJournalier = 0.0; // Ajout d'une variable pour stocker le revenu du jour
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStatistiques();
  }
  final User? user = FirebaseAuth.instance.currentUser;
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    UserModel? userModel = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _userModel = userModel;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistiques() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      // Calculer le taux d'occupation actuel pour aujourd'hui
      final aujourdhui = DateTime.now();
      final tauxOccupation = await _calculerTauxOccupationJour(aujourdhui);

      // Calculer le revenu du jour
      final revenuJour = await _calculerRevenuJour(aujourdhui);

      if (mounted) {
        setState(() {
          _tauxOccupationActuel = tauxOccupation;
          _revenuJournalier = revenuJour;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  // Nouvelle méthode pour calculer le revenu du jour
  Future<double> _calculerRevenuJour(DateTime jour) async {
    try {
      // Définir la plage horaire pour aujourd'hui
      final dateDebut = DateTime(jour.year, jour.month, jour.day);
      final dateFin = DateTime(jour.year, jour.month, jour.day, 23, 59, 59);

      // Récupérer les transactions de type 'payment' pour aujourd'hui
      final snapshotTransactions = await FirebaseFirestore.instance
          .collection('transactions')
          .where('customerId', isEqualTo: user?.uid) // Utiliser user.uid pour l'I
          .where('date', isGreaterThanOrEqualTo: dateDebut)
          .where('date', isLessThanOrEqualTo: dateFin)
          .where('type', isEqualTo: 'payment')
          .get();

      // Calculer la somme des montants
      double totalRevenu = 0.0;
      for (var doc in snapshotTransactions.docs) {
        final transaction = doc.data();
        totalRevenu += (transaction['amount'] as num).toDouble();
      }

      return totalRevenu;
    } catch (e) {
      print('Erreur lors du calcul du revenu journalier: $e');
      return 0.0;
    }
  }

  Future<double> _calculerTauxOccupationJour(DateTime jour) async {
    try {
      // Récupérer le nombre total de chambres
      final snapshotChambres = await FirebaseFirestore.instance
          .collection('rooms')
          .where('userId', isEqualTo: user?.uid) // Utiliser user.uid pour l'I
          .get();

      final nombreTotalChambres = snapshotChambres.docs.length;

      if (nombreTotalChambres <= 0) {
        return 0.0;
      }

      // Récupérer les réservations pour ce jour
      final dateDebut = DateTime(jour.year, jour.month, jour.day);
      final dateFin = DateTime(jour.year, jour.month, jour.day, 23, 59, 59);

      final snapshotReservations = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user?.uid) // Utiliser user.uid pour l'I
          .where('checkInDate', isLessThanOrEqualTo: dateFin)
          .where('checkOutDate', isGreaterThanOrEqualTo: dateDebut)
          .get();

      final nombreChambresOccupees = snapshotReservations.docs.length;

      // Calculer le taux d'occupation en pourcentage
      return (nombreChambresOccupees / nombreTotalChambres) * 100;
    } catch (e) {
      print('Erreur lors du calcul du taux d\'occupation: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formater le revenu avec séparateur de milliers et devise FCFA
    final formattedRevenu = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 0,
    ).format(_revenuJournalier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Tableau de bord'),
            const SizedBox(width: 8),
            Text(
              'v1.2.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Actions pour les notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              // Actions pour les messages
            },
          ),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
        ],
      ),
      drawer: const SideMenu(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 1200
                  ? 4
                  : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3 / 2,
              children: [
                StatCard(
                  title: "Taux d'occupation",
                  value: _isLoadingStats
                      ? "Chargement..."
                      : "${_tauxOccupationActuel.toStringAsFixed(1)}%",
                  icon: Icons.bed,
                  change: {"value": 12, "isPositive": true},
                  color: const Color(0xFF000080),
                ),
                StatCard(
                  title: "Commandes du restaurant",
                  value: "42",
                  icon: Icons.restaurant,
                  change: {"value": 8, "isPositive": true},
                  color: const Color(0xFFFFD700),
                ),
                StatCard(
                  title: "Nouveaux clients",
                  value: "18",
                  icon: Icons.people,
                  change: {"value": 5, "isPositive": true},
                  color: Colors.green,
                ),
                StatCard(
                  title: "Revenus du jour",
                  value: _isLoadingStats
                      ? "Chargement..."
                      : "$formattedRevenu FCFA",
                  icon: Icons.attach_money,
                  change: {"value": 15, "isPositive": true},
                  color: const Color(0xFF000080),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                return constraints.maxWidth > 800
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: OccupancyChartAvecDonnees()
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: RevenueChart()),
                  ],
                )
                    : Column(
                  children: [
                    OccupancyChartAvecDonnees(),
                    const SizedBox(height: 16),
                    RevenueChart(),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                return constraints.maxWidth > 800
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: RecentBookings()),
                    const SizedBox(width: 16),
                    Expanded(child: TasksList()),
                  ],
                )
                    : Column(
                  children: [
                    RecentBookings(),
                    const SizedBox(height: 16),
                    TasksList(),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Actions rapides",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 600
                        ? 4
                        : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                    children: [
                      _buildActionButton(
                          context: context,
                          icon: Icons.bed,
                          label: "Nouvelle réservation",
                          color: const Color(0xFF000080),
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.reservationPage);
                          }
                      ),
                      _buildActionButton(
                          context: context,
                          icon: Icons.event_available,
                          label: "Enregistrement",
                          color: Colors.green,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.enregistrement);
                          }
                      ),
                      _buildActionButton(
                          context: context,
                          icon: Icons.library_add_check_outlined,
                          label: "Départ",
                          color: Colors.red,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.checkoutPage);
                          }
                      ),
                      _buildActionButton(
                          context: context,
                          icon: Icons.assignment_turned_in,
                          label: "Nouvelle tâche",
                          color: const Color(0xFF000080),
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.reservationPage);
                          }
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]
          : Colors.grey[50],
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


