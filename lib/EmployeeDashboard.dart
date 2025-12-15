import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import 'Screens/employee/cuisine/KitchenScreen.dart';
import 'Screens/employee/dashboard/DashboardScreen.dart';
import 'Screens/employee/reservation/ReservationScreen.dart';
import 'Screens/employee/restaurant/CashierRestaurantPage.dart';
import 'Screens/employee/serveur/ServerScreen.dart';
import 'Screens/employee/service_chambre/RoomServiceScreen.dart';
import 'Screens/employee/tasks/TasksScreen.dart';
import 'Screens/manager/CheckInPage.dart';
import 'Screens/manager/HourlyCheckInPage.dart';
import 'Screens/manager/OccupiedRoomsPage.dart';
import 'Screens/manager/PaymentPage.dart';
import 'Screens/manager/TaskManagementPage.dart';
import 'Screens/employee/restaurant/RestaurantDashboardPage.dart';


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

  // ✅ Liste de tous les items possibles du menu AVEC la page Caisse Restaurant
  // ✅ Liste de tous les items possibles du menu avec les deux dashboards en premier
  final List<Map<String, dynamic>> _allMenuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard, 'roles': ['Réceptionniste', 'manager', 'admin']},
    {'title': 'Restaurant Dashboard', 'icon': Icons.dashboard_outlined, 'roles': ['Caissier', 'manager', 'admin']},
    {'title': 'Tâches', 'icon': Icons.task_alt, 'roles': ['all']},
    {'title': 'Gestions des Tâches', 'icon': Icons.task_outlined, 'roles': ['manager']},
    {'title': 'Réservation', 'icon': Icons.book_online, 'roles': ['Réceptionniste', 'manager', 'admin']},
    {'title': 'Enregistrement', 'icon': Icons.how_to_reg, 'roles': ['Réceptionniste', 'manager', 'admin']},
    {'title': 'Passage', 'icon': Icons.bed, 'roles': ['Réceptionniste', 'manager', 'admin']},
    {'title': 'Départ', 'icon': Icons.exit_to_app, 'roles': ['Réceptionniste', 'manager', 'admin']},
    {'title': 'Paiement', 'icon': Icons.payment, 'roles': ['Réceptionniste', 'manager', 'admin', 'accountant']},
    {'title': 'Caisse Restaurant', 'icon': Icons.point_of_sale, 'roles': ['Caissier', 'manager', 'admin']},
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GestoTheme.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout,
                  color: GestoTheme.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirmation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Êtes-vous sûr de vouloir vous déconnecter ?',
              style: TextStyle(fontSize: 16),
            ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GestoTheme.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Déconnecter',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget pour construire un item de la bottom navigation bar
  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                  builder: (context, value, child) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Colors.transparent,
                          GestoTheme.navyBlue.withValues(alpha: 0.1),
                          value,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Color.lerp(
                          Colors.grey[600],
                          GestoTheme.navyBlue,
                          value,
                        ),
                        size: 24,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? GestoTheme.navyBlue : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget pour construire le menu latéral avec style moderne et animations
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
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000), // black with 0.05 opacity
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête du menu avec info utilisateur - Design modernisé
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  GestoTheme.navyBlue,
                  Color(0xCC2C3E50), // navyBlue with 0.8 opacity
                ],
              ),
            ),
            child: Column(
              children: [
                // Avatar avec animation
                Hero(
                  tag: 'user-avatar',
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000), // black with 0.2 opacity
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : CircleAvatar(
                              radius: 38,
                              backgroundColor: GestoTheme.gold,
                              child: Text(
                                _userData['firstName'].isNotEmpty && _userData['lastName'].isNotEmpty
                                    ? '${_userData['firstName'][0]}${_userData['lastName'][0]}'
                                    : 'E',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _userData['email'] ?? 'email@example.com',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xCCFFFFFF), // white with 0.8 opacity
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Badge du rôle modernisé
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: GestoTheme.gold,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4DF1C40F), // gold with 0.3 opacity
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _userData['role'].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items du menu avec animations
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = index == _selectedIndex;

                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                  builder: (context, value, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  GestoTheme.navyBlue,
                                  Color(0xCC2C3E50), // navyBlue with 0.8 opacity
                                ],
                              )
                            : null,
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: Color(0x4D2C3E50), // navyBlue with 0.3 opacity
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _onItemTapped(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item['icon'],
                                  color: isSelected ? Colors.white : GestoTheme.navyBlue,
                                  size: 22,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    item['title'],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[800],
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Color(0xB3FFFFFF), // white with 0.7 opacity
                                    size: 14,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Bouton déconnexion modernisé
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _confirmLogout,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [GestoTheme.red, Color(0xFFC0392B)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4DE74C3C), // red with 0.3 opacity
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Déconnexion',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600 && size.width <= 1000;
    final isMobile = size.width <= 600;

    // Afficher un indicateur de chargement moderne pendant que les données sont récupérées
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GestoTheme.navyBlue,
                Color(0xFF34495E),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/gesto_logo2.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(GestoTheme.gold),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chargement de votre espace...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Si l'utilisateur n'a pas accès à cette application (pas de menu items)
    if (_menuItems.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[100]!,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: GestoTheme.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 60,
                      color: GestoTheme.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Accès non autorisé',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: GestoTheme.navyBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Vous n\'avez pas les permissions nécessaires pour accéder à cette application.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour à la connexion'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GestoTheme.navyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),
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

    // ✅ Sélection de la page en fonction de l'index original - Dashboards en premier
    switch (originalIndex) {
      case 0: // Dashboard général
        mainContent = const DashboardScreen();
        break;
      case 1: // Restaurant Dashboard
        mainContent = const RestaurantDashboardPage();
        break;
      case 2: // Tâches
        mainContent = const EmployeeTaskScreen();
        break;
      case 3: // Gestion des Tâches
        mainContent = TaskManagementPage();
        break;
      case 4: // Réservation
        mainContent = ModernReservationPageEnploye();
        break;
      case 5: // Enregistrement
        mainContent = CheckInPage();
        break;
      case 6: // Passage
        mainContent = HourlyCheckInPage();
        break;
      case 7: // Départ
        mainContent = OccupiedRoomsPage();
        break;
      case 8: // Paiement
        mainContent = PaymentPage();
        break;
      case 9: // Caisse Restaurant
        mainContent = CashierRestaurantPage();
        break;
      case 10: // Cuisine
        mainContent = const KitchenScreen();
        break;
      case 11: // Serveur
        mainContent = const ServerScreen();
        break;
      case 12: // Service de Chambre
        mainContent = const RoomServiceScreen();
        break;
      default:
        mainContent = const Center(
          child: Text('Contenu non disponible'),
        );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GestoTheme.navyBlue,
                Color(0xFF34495E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/gesto_logo2.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'GESTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Espace Employé',
                      style: TextStyle(
                        color: GestoTheme.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            leading: isMobile || isTablet
                ? IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  )
                : null,
            actions: [
              // Badge de notifications
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                    tooltip: 'Notifications',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.white),
                              SizedBox(width: 12),
                              Text('Aucune nouvelle notification'),
                            ],
                          ),
                          backgroundColor: GestoTheme.navyBlue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: GestoTheme.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
                tooltip: 'Aide',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.help_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Centre d\'aide bientôt disponible'),
                        ],
                      ),
                      backgroundColor: GestoTheme.navyBlue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      drawer: (isMobile || isTablet) ? Drawer(child: _buildSideMenu(context)) : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[100]!,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Row(
          children: [
            // Menu latéral (seulement visible en mode desktop)
            if (!isMobile && !isTablet) _buildSideMenu(context),

            // Contenu principal avec animation de transition
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.02, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey<int>(_selectedIndex),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 40,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: mainContent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // BottomNavigationBar modernisé pour mobile
      bottomNavigationBar: isMobile && _menuItems.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (_menuItems.isNotEmpty)
                        _buildBottomNavItem(
                          icon: _menuItems[0]['icon'],
                          label: _menuItems[0]['title'],
                          isSelected: _selectedIndex == 0,
                          onTap: () => _onItemTapped(0),
                        ),
                      if (_menuItems.length > 1)
                        _buildBottomNavItem(
                          icon: _menuItems[1]['icon'],
                          label: _menuItems[1]['title'],
                          isSelected: _selectedIndex == 1,
                          onTap: () => _onItemTapped(1),
                        ),
                      _buildBottomNavItem(
                        icon: Icons.menu_rounded,
                        label: 'Menu',
                        isSelected: false,
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}