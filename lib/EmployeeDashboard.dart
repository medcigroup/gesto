import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import 'Screens/employee/cuisine/KitchenScreen.dart';
import 'Screens/employee/dashboard/DashboardScreen.dart';
import 'Screens/employee/departure/DepartureScreen.dart';
import 'Screens/employee/enregistrement/RegistrationScreen.dart';
import 'Screens/employee/passage/PassageScreen.dart';
import 'Screens/employee/payment/PaymentScreen.dart';
import 'Screens/employee/reservation/ReservationScreen.dart';
import 'Screens/employee/serveur/ServerScreen.dart';
import 'Screens/employee/service_chambre/RoomServiceScreen.dart';
import 'Screens/employee/tasks/TasksScreen.dart';

// Import des écrans


class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  // Titres des sections du menu latéral
  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard},
    {'title': 'Tâches', 'icon': Icons.task_alt},
    {'title': 'Réservation', 'icon': Icons.book_online},
    {'title': 'Enregistrement', 'icon': Icons.how_to_reg},
    {'title': 'Passage', 'icon': Icons.transfer_within_a_station},
    {'title': 'Départ', 'icon': Icons.exit_to_app},
    {'title': 'Paiement', 'icon': Icons.payment},
    {'title': 'Cuisine', 'icon': Icons.restaurant},
    {'title': 'Serveur', 'icon': Icons.room_service},
    {'title': 'Service de Chambre', 'icon': Icons.cleaning_services},
  ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation de déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
                _logout(); // Déconnexion
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GestoTheme.red,
              ),
              child: const Text('Déconnecter'),
            ),
          ],
        );
      },
    );
  }

  // Widget pour construire le menu latéral avec style moderne
  Widget _buildSideMenu(BuildContext context) {
    final user = _auth.currentUser;

    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
          // En-tête du menu avec info utilisateur
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: GestoTheme.navyBlue.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: GestoTheme.navyBlue.withOpacity(0.2),
                  child: const Icon(
                    Icons.person,
                    size: 35,
                    color: GestoTheme.navyBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? 'Employé',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'email@example.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Items du menu
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = index == _selectedIndex;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected
                        ? GestoTheme.navyBlue
                        : Colors.transparent,
                  ),
                  child: ListTile(
                    leading: Icon(
                      item['icon'],
                      color: isSelected ? Colors.white : GestoTheme.navyBlue,
                      size: 22,
                    ),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[800],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () => _onItemTapped(index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bouton déconnexion en bas du menu
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            child: ElevatedButton.icon(
              onPressed: _confirmLogout, // Appel à la fonction de confirmation
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: GestoTheme.red,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;
    final isTablet = size.width > 600 && size.width <= 1000;
    final isMobile = size.width <= 600;

    // Contenu principal selon l'onglet sélectionné
    Widget mainContent = Center(
      child: Text('Contenu non disponible'),
    );

    // Sélection de la page en fonction de l'index
    switch (_selectedIndex) {
      case 0:
        mainContent = const DashboardScreen();
        break;
      case 1:
        mainContent = const TasksScreen();
        break;
      case 2:
        mainContent = const ReservationScreen();
        break;
      case 3:
        mainContent = const RegistrationScreen();
        break;
      case 4:
        mainContent = const PassageScreen();
        break;
      case 5:
        mainContent = const DepartureScreen();
        break;
      case 6:
        mainContent = const PaymentScreen();
        break;
      case 7:
        mainContent = const KitchenScreen();
        break;
      case 8:
        mainContent = const ServerScreen();
        break;
      case 9:
        mainContent = const RoomServiceScreen();
        break;
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: GestoTheme.navyBlue,
        title: const Text(
          'GESTO - Espace Employé',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        leading: isMobile || isTablet
            ? IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              // Afficher les notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aucune nouvelle notification')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              // Afficher l'aide
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Centre d\'aide non disponible pour le moment')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
      ),
      drawer: (isMobile || isTablet) ? Drawer(child: _buildSideMenu(context)) : null,
      body: Container(
        color: Colors.grey[100],
        child: Row(
          children: [
            // Menu latéral (seulement visible en mode desktop)
            if (!isMobile && !isTablet) _buildSideMenu(context),

            // Contenu principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: mainContent,
                ),
              ),
            ),
          ],
        ),
      ),
      // BottomNavigationBar seulement pour mobile
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
        currentIndex: _selectedIndex > 2 ? 2 : _selectedIndex, // Limite aux 3 premiers items
        onTap: _onItemTapped,
        selectedItemColor: GestoTheme.navyBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tâches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Plus',
          ),
        ],
      )
          : null,
    );
  }
}