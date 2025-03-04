import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gesto/widgets/side_menu.dart';

// Composants importés
import '../components/dashboard/occupancy_chart.dart';
import '../components/dashboard/revenue_chart.dart';
import '../components/dashboard/recent_bookings.dart';
import '../components/dashboard/tasks_list.dart';
import 'Screens/RoomsPage.dart';
import 'components/dashboard/StatCard.dart';
import 'config/AuthService.dart';
import 'config/UserModel.dart';
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
  bool _isLoading = true; // Ajout de l'état de chargement

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true; // Début du chargement
    });
    UserModel? userModel = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _userModel = userModel;
        _isLoading = false; // Fin du chargement
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
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
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                try {
                  await FirebaseAuth.instance.signOut(); // Déconnexion de Firebase
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.home, (route) => false);
                } catch (e) {
                  // Gérer les erreurs de déconnexion
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la déconnexion : $e')),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Déconnexion'),
              ),
            ],
          ),
        ],
      ),
      drawer: const SideMenu(),
      body: SingleChildScrollView(
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
                  value: "85%",
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
                  value: "\$4,285",
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
                    Expanded(child: OccupancyChart()),
                    const SizedBox(width: 16),
                    Expanded(child: RevenueChart()),
                  ],
                )
                    : Column(
                  children: [
                    OccupancyChart(),
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
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.restaurant,
                        label: "Nouvelle commande",
                        color: const Color(0xFF000080),
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.event_available,
                        label: "Enregistrement",
                        color: const Color(0xFF000080),
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.assignment_turned_in,
                        label: "Nouvelle tâche",
                        color: const Color(0xFF000080),
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
  }) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]
          : Colors.grey[50],
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {},
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

