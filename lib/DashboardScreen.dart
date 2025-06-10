import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

// Composants importés
import '../components/dashboard/revenue_chart.dart';
import '../components/dashboard/recent_bookings.dart';
import '../components/dashboard/tasks_list.dart';

import 'components/messagerie/NotificationPanel.dart';
import 'components/messagerie/NotificationProvider.dart';
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
  double _revenuJournalier = 0.0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    // Initialiser les données de localisation françaises
    initializeDateFormatting('fr_FR', null).then((_) {
      _loadUserData();
      _loadStatistiques();

      Provider.of<NotificationProvider>(context, listen: false).initialiser();
    });
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

  Future<double> _calculerRevenuJour(DateTime jour) async {
    try {
      // Définir la plage horaire pour aujourd'hui
      final dateDebut = DateTime(jour.year, jour.month, jour.day);
      final dateFin = DateTime(jour.year, jour.month, jour.day, 23, 59, 59);

      // Récupérer les transactions de type 'payment' pour aujourd'hui
      final snapshotTransactions = await FirebaseFirestore.instance
          .collection('transactions')
          .where('customerId', isEqualTo: user?.uid)
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
          .where('userId', isEqualTo: user?.uid)
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
          .where('userId', isEqualTo: user?.uid)
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
    final formattedRevenu = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 0,
    ).format(_revenuJournalier);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = const Color(0xFF3F51B5); // Indigo
    final secondaryColor = const Color(0xFF03A9F4); // Light Blue
    final accentColor = const Color(0xFFFF9800); // Orange
    final successColor = const Color(0xFF4CAF50); // Green
    final warningColor = const Color(0xFFFFEB3B); // Yellow
    final dangerColor = const Color(0xFFF44336); // Red

    // Format de date avec gestion des erreurs
    String formattedDate;
    try {
      formattedDate = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now());
    } catch (e) {
      formattedDate = DateTime.now().toString().substring(0, 10); // Fallback au format simple
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec salutation et boutons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${_userModel?.fullName ?? "Utilisateur"}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: Icon(Icons.add, size: 18, color: primaryColor),
                        label: Text(
                          'Nouvelle réservation',
                          style: TextStyle(color: primaryColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.reservationPage);
                        },
                      ),
                      OutlinedButton.icon(
                        icon: Icon(Icons.add, size: 18, color: primaryColor),
                        label: Text(
                          'Nouvel enregistrement',
                          style: TextStyle(color: primaryColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.enregistrement);
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Cards de statistiques
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildStatCard(
                      icon: Icons.bed,
                      iconColor: primaryColor,
                      title: "Taux d'occupation",
                      value: _isLoadingStats
                          ? "Chargement..."
                          : "${_tauxOccupationActuel.toStringAsFixed(1)}%",
                      change: "+12%",
                      changePositive: true,
                      color: isDark ? const Color(0xFF263238) : Colors.white,
                      width: 240,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      icon: Icons.payments_outlined,
                      iconColor: secondaryColor,
                      title: "Revenus du jour",
                      value: _isLoadingStats
                          ? "Chargement..."
                          : "$formattedRevenu FCFA",
                      change: "+15%",
                      changePositive: true,
                      color: isDark ? const Color(0xFF263238) : Colors.white,
                      width: 240,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Text(
                'Performance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Graphiques
              LayoutBuilder(
                builder: (context, constraints) {
                  return constraints.maxWidth > 800
                      ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCard(
                          child: OccupancyChartAvecDonnees(),
                          title: "Taux d'occupation",
                          actions: [
                            _buildDropdownFilter(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCard(
                          child: RevenueChart(),
                          title: "Revenus",
                          actions: [
                            _buildDropdownFilter(),
                          ],
                        ),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      _buildCard(
                        child: OccupancyChartAvecDonnees(),
                        title: "Taux d'occupation",
                        actions: [
                          _buildDropdownFilter(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        child: RevenueChart(),
                        title: "Revenus",
                        actions: [
                          _buildDropdownFilter(),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),
              Text(
                'Activités',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Activités récentes
              LayoutBuilder(
                builder: (context, constraints) {
                  return constraints.maxWidth > 800
                      ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCard(
                          child: RecentBookings(),
                          title: "Réservations récentes",
                          actions: [
                            TextButton(
                              onPressed: () {Navigator.pushNamed(context, AppRoutes.reservationPage);},
                              child: Text(
                                'Voir tout',
                                style: TextStyle(color: primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCard(
                          child: TasksList(),
                          title: "Tâches",
                          actions: [
                            IconButton(
                              icon: Icon(Icons.add, color: primaryColor),
                              onPressed: () {Navigator.pushNamed(context, AppRoutes.services);},
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      _buildCard(
                        child: RecentBookings(),
                        title: "Réservations récentes",
                        actions: [
                          TextButton(
                            onPressed: () {Navigator.pushNamed(context, AppRoutes.reservationPage);},
                            child: Text(
                              'Voir tout',
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        child: TasksList(),
                        title: "Tâches",
                        actions: [
                          IconButton(
                            icon: Icon(Icons.add, color: primaryColor),
                            onPressed: () {Navigator.pushNamed(context, AppRoutes.services);},
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),
              _buildCard(
                title: "Actions rapides",
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildActionButton(
                      context: context,
                      icon: Icons.bed,
                      label: "Nouvelle réservation",
                      color: primaryColor,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.reservationPage);
                      },
                    ),
                    _buildActionButton(
                      context: context,
                      icon: Icons.login,
                      label: "Enregistrement",
                      color: successColor,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.enregistrement);
                      },
                    ),
                    _buildActionButton(
                      context: context,
                      icon: Icons.logout,
                      label: "Départ",
                      color: dangerColor,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.occupiedrooms);
                      },
                    ),
                    _buildActionButton(
                      context: context,
                      icon: Icons.assignment_outlined,
                      label: "Nouvelle tâche",
                      color: secondaryColor,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.services);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter() {
    return DropdownButton<String>(
      value: 'mois',
      underline: Container(),
      icon: const Icon(Icons.keyboard_arrow_down),
      items: <String>['jour', 'semaine', 'mois', 'année']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value.substring(0, 1).toUpperCase() + value.substring(1),
            style: TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {},
    );
  }

  Widget _buildCard({
    required Widget child,
    required String title,
    List<Widget>? actions,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (actions != null)
                  Row(
                    children: actions,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String change,
    required bool changePositive,
    required Color color,
    required double width,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: changePositive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      changePositive
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: changePositive ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      change,
                      style: TextStyle(
                        color: changePositive ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}