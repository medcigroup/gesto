import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import 'Screens/employee/cuisine/KitchenScreen.dart';
import 'Screens/employee/dashboard/DashboardScreen.dart';
import 'Screens/employee/reservation/ReservationScreen.dart';
import 'Screens/employee/serveur/ServerScreen.dart';
import 'Screens/employee/service_chambre/RoomServiceScreen.dart';
import 'Screens/employee/tasks/TasksScreen.dart';
import 'Screens/manager/CheckInPage.dart';
import 'Screens/manager/HourlyCheckInPage.dart';
import 'Screens/manager/OccupiedRoomsPage.dart';
import 'Screens/manager/PaymentPage.dart';
import 'Screens/manager/TaskManagementPage.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isLoading = true;

  // Variables utilisateur regroupées dans une seule structure
  Map<String, dynamic> _userData = {
    'firstName': '',
    'lastName': '',
    'role': 'employee',
    'email': ''
  };

  // Liste de tous les items possibles du menu
  final List<Map<String, dynamic>> _allMenuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard, 'roles': ['all']},
    {'title': 'Tâches', 'icon': Icons.task_alt, 'roles': ['all']},
    {'title': 'Gestions des Tâches', 'icon': Icons.task_outlined, 'roles': ['manager']},
    {'title': 'Réservation', 'icon': Icons.book_online, 'roles': ['Réceptionniste', 'manager', 'admin']},
    {'title': 'Enregistrement', 'icon': Icons.how_to_reg, 'roles': ['Réceptionniste', 'manager', 'admin']},
    {'title': 'Passage', 'icon': Icons.bed, 'roles': ['Réceptionniste', 'manager', 'admin']},
    {'title': 'Départ', 'icon': Icons.exit_to_app, 'roles': ['Réceptionniste', 'manager', 'admin']},
    {'title': 'Paiement', 'icon': Icons.payment, 'roles': ['Réceptionniste', 'manager', 'admin', 'accountant']},
    {'title': 'Cuisine', 'icon': Icons.restaurant, 'roles': ['Chef', 'kitchen_staff', 'manager', 'admin']},
    {'title': 'Serveur', 'icon': Icons.room_service, 'roles': ['serveur', 'manager', 'admin']},
    {'title': 'Service de Chambre', 'icon': Icons.cleaning_services, 'roles': ['Femme de chambre','Agent d\'entretien', 'manager', 'admin']},
  ];

  // Liste filtrée des items de menu basée sur le rôle
  List<Map<String, dynamic>> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Une seule fonction pour charger toutes les données utilisateur
  }

  // Fonction unifiée pour charger les données utilisateur
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        // Stocker l'email de l'utilisateur directement depuis Auth
        _userData['email'] = currentUser.email ?? '';

        // Un seul appel Firestore pour récupérer toutes les données utilisateur
        final DocumentSnapshot staffDoc = await _firestore
            .collection('staff')
            .doc(currentUser.uid)
            .get();

        if (staffDoc.exists) {
          final data = staffDoc.data() as Map<String, dynamic>;
          setState(() {
            _userData['firstName'] = data['prenom'] ?? '';
            _userData['lastName'] = data['nom'] ?? '';
            _userData['role'] = data['poste'] ?? 'employee';
          });
        }
      }

      // Filtrer le menu après avoir chargé les données utilisateur
      _filterMenuByRole();
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
      setState(() {
        _userData['role'] = 'employee';
        _filterMenuByRole();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filtrer les éléments du menu en fonction du rôle
  void _filterMenuByRole() {
    final String userRole = _userData['role'];

    if (userRole == 'admin' || userRole == 'manager') {
      // Les admins et managers ont accès à tout
      _menuItems = List.from(_allMenuItems);
    } else {
      // Filtrer les éléments du menu en fonction du rôle
      _menuItems = _allMenuItems.where((item) {
        List<String> roles = List<String>.from(item['roles']);
        return roles.contains('all') || roles.contains(userRole);
      }).toList();
    }

    // Si l'index actuel n'est plus valide après le filtrage
    if (_selectedIndex >= _menuItems.length) {
      _selectedIndex = 0;
    }
  }

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

    // Construire le nom complet à afficher
    String fullName = 'Employé';
    if (_userData['firstName'].isNotEmpty || _userData['lastName'].isNotEmpty) {
      fullName = '${_userData['firstName']} ${_userData['lastName']}'.trim();
    } else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      fullName = user.displayName!;
    }

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
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                    _userData['firstName'].isNotEmpty && _userData['lastName'].isNotEmpty
                        ? '${_userData['firstName'][0]}${_userData['lastName'][0]}'
                        : 'E',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: GestoTheme.navyBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _userData['email'] ?? 'email@example.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                // Afficher le poste de l'utilisateur
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: GestoTheme.navyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _userData['role'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: GestoTheme.navyBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items du menu
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;
    final isTablet = size.width > 600 && size.width <= 1000;
    final isMobile = size.width <= 600;

    // Afficher un indicateur de chargement pendant que les données sont récupérées
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des données...')
            ],
          ),
        ),
      );
    }

    // Si l'utilisateur n'a pas accès à cette application (pas de menu items)
    if (_menuItems.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: GestoTheme.red),
              const SizedBox(height: 16),
              const Text(
                'Accès non autorisé',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous n\'avez pas les permissions nécessaires pour accéder à cette application.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GestoTheme.navyBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      );
    }

    // Contenu principal selon l'onglet sélectionné
    Widget mainContent = const Center(
      child: Text('Contenu non disponible'),
    );

    // Trouver l'index original (celui dans _allMenuItems) pour le menu sélectionné
    final String selectedTitle = _menuItems[_selectedIndex]['title'];
    final int originalIndex = _allMenuItems.indexWhere((item) => item['title'] == selectedTitle);

    // Sélection de la page en fonction de l'index original
    switch (originalIndex) {
      case 0:
        mainContent = const DashboardScreen();
        break;
      case 1:
        mainContent = const EmployeeTaskScreen();
        break;
      case 2:
        mainContent = TaskManagementPage();
        break;
      case 3:
        mainContent = ModernReservationPageEnploye();
        break;
      case 4:
        mainContent = CheckInPage();
        break;
      case 5:
        mainContent = HourlyCheckInPage();
        break;
      case 6:
        mainContent = OccupiedRoomsPage();
        break;
      case 7:
        mainContent = PaymentPage();
        break;
      case 8:
        mainContent = const KitchenScreen();
        break;
      case 9:
        mainContent = const ServerScreen();
        break;
      case 10:
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
      // BottomNavigationBar seulement pour mobile - limité aux premiers items disponibles
      bottomNavigationBar: isMobile && _menuItems.length > 0
          ? BottomNavigationBar(
        currentIndex: _selectedIndex > 2 ? 2 : _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: GestoTheme.navyBlue,
        unselectedItemColor: Colors.grey,
        items: [
          if (_menuItems.length > 0)
            BottomNavigationBarItem(
              icon: Icon(_menuItems[0]['icon']),
              label: _menuItems[0]['title'],
            ),
          if (_menuItems.length > 1)
            BottomNavigationBarItem(
              icon: Icon(_menuItems[1]['icon']),
              label: _menuItems[1]['title'],
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