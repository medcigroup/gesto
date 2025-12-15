import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'DashboardScreen.dart';
import 'RestaurantDashboard.dart';
import 'Screens/manager/CheckInPage.dart';
import 'Screens/manager/ComingSoonPage.dart';
import 'Screens/manager/FinancePage.dart';
import 'Screens/manager/GestionPersonnelPage.dart';
import 'Screens/manager/HourlyCheckInPage.dart';
import 'Screens/manager/OccupiedRoomsPage.dart';
import 'Screens/manager/PaymentPage.dart';
import 'Screens/manager/RoomsPage.dart';
import 'Screens/manager/ScheduleManagementPage.dart';
import 'Screens/manager/SettingsPage.dart';
import 'Screens/manager/TaskManagementPage.dart';
import 'Screens/manager/UserManagementScreen.dart';
import 'Screens/manager/renew_licence_page.dart';
import 'components/dashboard/licence_Ui.dart';
import 'components/messagerie/NotificationPanel.dart';
import 'components/messagerie/NotificationProvider.dart';
import 'components/reservation/ModernReservationPage.dart';
import 'config/AppConstants.dart';
import 'config/AuthService.dart';
import 'LicenseFeatures.dart';

enum UserRole {
  admin,
  manager,
  receptionist,
  employee,
  kitchen
}

class DashboardManager extends StatefulWidget {
  const DashboardManager({Key? key}) : super(key: key);

  @override
  _DashboardManagerState createState() => _DashboardManagerState();
}

class _DashboardManagerState extends State<DashboardManager> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  UserRole _userRole = UserRole.employee;
  StreamSubscription? _notificationSubscription; // Ajout pour gérer le stream

  // Liste complète des pages disponibles
  final List<Widget> _allPages = [
    const Dashboard(),
    ModernReservationPage(),
    RoomsPage(),
    TaskManagementPage(),
    ModernScheduleManagementPage(),
    PaymentPage(),
    CheckInPage(),
    HourlyCheckInPage(),
    OccupiedRoomsPage(),
    RestaurantDashboard(),
    GestionPersonnelPage(),
    FinancePage(),
    RenewLicencePage(),
    UserManagementScreen(),
    SettingsPage(),
  ];

  // Titres de toutes les pages
  final List<String> _allPageTitles = [
    'Tableau de bord',
    'Réservations',
    'Chambres',
    'Taches',
    'Emplois du temps',
    'Paiements',
    'Enregistrement',
    'Passages',
    'Départ',
    'Restaurant',
    'Personnel',
    'Finances',
    'Licences',
    'Administration',
    'Paramètres',
  ];

  // Icônes de toutes les pages pour le menu
  final List<IconData> _allPageIcons = [
    Icons.dashboard_outlined,
    Icons.calendar_today_outlined,
    Icons.hotel_outlined,
    Icons.task_outlined,
    Icons.schedule_outlined,
    Icons.payment_outlined,
    Icons.app_registration_outlined,
    Icons.bed,
    Icons.exit_to_app_outlined,
    Icons.restaurant_outlined,
    Icons.people_outlined,
    Icons.attach_money_outlined,
    Icons.card_membership_outlined,
    Icons.admin_panel_settings_outlined,
    Icons.settings_outlined,
  ];

  // Listes actives qui seront ajustées en fonction du rôle et de la licence
  late List<Widget> _pages;
  late List<String> _pageTitles;
  late List<IconData> _pageIcons;
  late List<int> _accessiblePageIndices;

  void _changeSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _getUserRole();
  }

  // Initialiser les notifications avec gestion du stream
  void _initializeNotifications() {
    try {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.initialiser();
      print('[DASHBOARD] ✅ Notifications initialisées');
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur initialisation notifications: $e');
    }
  }

  // Récupère le rôle de l'utilisateur
  Future<void> _getUserRole() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userRoleStr = await authService.getCurrentUserRole();

      if (userRoleStr != null && mounted) {
        setState(() {
          // Convertir la chaîne du rôle en énumération
          switch (userRoleStr.toLowerCase()) {
            case 'superadmin':
              _userRole = UserRole.admin;
              break;
            case 'manager':
              _userRole = UserRole.manager;
              break;
            case 'receptionist':
              _userRole = UserRole.receptionist;
              break;
            case 'kitchen':
              _userRole = UserRole.kitchen;
              break;
            default:
              _userRole = UserRole.employee;
          }
          print('[DASHBOARD] 👤 Rôle utilisateur: $_userRole');
          // Initialiser les pages après avoir obtenu le rôle
          _initPagesBasedOnRoleAndLicense();
        });
      }
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur lors de la récupération du rôle: $e');
      // Garder le rôle par défaut et initialiser quand même
      if (mounted) {
        _initPagesBasedOnRoleAndLicense();
      }
    }
  }

  // Configure les pages disponibles en fonction du rôle ET de la licence
  void _initPagesBasedOnRoleAndLicense() {
    if (!mounted) {
      print('[DASHBOARD] ⚠️ Widget non monté, abandon initialisation pages');
      return;
    }

    try {
      // Vérifier d'abord les pages accessibles par rôle
      List<int> roleBasedIndices = [];

      switch (_userRole) {
        case UserRole.admin:
          roleBasedIndices = List.generate(_allPages.length, (index) => index);
          break;
        case UserRole.manager:
          roleBasedIndices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14];
          break;
        case UserRole.receptionist:
          roleBasedIndices = [0, 1, 2, 6, 7, 8, 14];
          break;
        case UserRole.employee:
          roleBasedIndices = [0, 3, 4, 14];
          break;
        case UserRole.kitchen:
          roleBasedIndices = [0, 3, 4, 9, 14];
          break;
      }

      // Ensuite, filtrer en fonction de la licence
      final licenseManager = Provider.of<LicenseManager>(context, listen: false);

      // Si la licence est expirée, accès limité
      if (licenseManager.isExpired) {
        print('[DASHBOARD] ⏰ Licence expirée, accès limité');
        roleBasedIndices = roleBasedIndices.where((index) =>
        _allPageTitles[index] == 'Tableau de bord' ||
            _allPageTitles[index] == 'Licences' ||
            _allPageTitles[index] == 'Paramètres'
        ).toList();

        // S'assurer que la page de renouvellement de licence est accessible
        if (!roleBasedIndices.contains(12)) {
          roleBasedIndices.add(12);
        }
      }
      // Sinon, filtrer selon le type de licence
      else {
        roleBasedIndices = roleBasedIndices.where((index) =>
            licenseManager.canAccessPage(_allPageTitles[index])
        ).toList();
      }

      if (mounted) {
        setState(() {
          _accessiblePageIndices = roleBasedIndices;
          _pages = _accessiblePageIndices.map((i) => _allPages[i]).toList();
          _pageTitles = _accessiblePageIndices.map((i) => _allPageTitles[i]).toList();
          _pageIcons = _accessiblePageIndices.map((i) => _allPageIcons[i]).toList();

          // S'assurer que l'index sélectionné est valide
          if (_selectedIndex >= _pages.length) {
            _selectedIndex = 0;
          }
          print('[DASHBOARD] 📄 ${_pages.length} pages accessibles initialisées');
        });
      }
    } catch (e) {
      print('[DASHBOARD] ❌ Erreur initialisation pages: $e');
    }
  }

  // Vérifier si la licence a expiré au moment de l'affichage
  void _checkLicenseStatus() {
    if (!mounted) {
      print('[DASHBOARD] ⚠️ Widget non monté, abandon vérification licence');
      return;
    }

    try {
      final licenseManager = Provider.of<LicenseManager>(context, listen: false);
      licenseManager.checkExpiration();

      // Si la licence a expiré, afficher une boîte de dialogue
      if (licenseManager.isExpired && mounted) {
        print('[DASHBOARD] ⏰ Licence expirée détectée');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => LicenseExpiredDialog(
                expiryDate: licenseManager.expiryDate,
                licenseType: licenseManager.currentLicenseType,
              ),
            );
          }
        });
      }

      // Rafraîchir les pages disponibles
      _initPagesBasedOnRoleAndLicense();
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur vérification licence: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Vérifier la licence à chaque changement de dépendances
    // Mais seulement si le widget est monté
    if (mounted) {
      _checkLicenseStatus();
    }
  }

  @override
  void dispose() {
    // Annuler tous les streams avant de disposer
    _notificationSubscription?.cancel();
    print('[DASHBOARD] 🧹 Nettoyage des resources');
    super.dispose();
  }

  void _logout() {
    if (!mounted) return;

    try {
      // Logique de déconnexion
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.logout();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF3F51B5);

    // Utiliser Consumer au lieu de Provider.of directement pour éviter les erreurs
    return Consumer<LicenseManager>(
      builder: (context, licenseManager, child) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            title: Row(
              children: [
                const Text(
                  'Gesto',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ' ${AppConstants.appVersion}',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              // Logout button
              IconButton(
                icon: Icon(
                  Icons.logout,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                tooltip: 'Déconnexion',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: Text('Confirmation'),
                        content: Text('Voulez-vous vraiment vous déconnecter ?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _logout();
                            },
                            child: Text(
                              'Déconnecter',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              // Notifications
              IconButton(
                icon: Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, _) => Badge(
                    label: Text('${notificationProvider.nonLuesCount}'),
                    isLabelVisible: notificationProvider.nonLuesCount > 0,
                    child: Icon(
                      Icons.notifications_outlined,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return Dialog(
                        insetPadding: EdgeInsets.only(top: 0, bottom: 0, right: 0),
                        alignment: Alignment.centerRight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        child: NotificationPanel(),
                      );
                    },
                  );
                },
              ),
              // Dark mode toggle
              IconButton(
                icon: Icon(
                  _isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _isDarkMode = !_isDarkMode;
                  });
                },
              ),
              // Badge pour afficher le type de licence
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: licenseManager.isExpired
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: licenseManager.isExpired
                          ? Colors.red.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        licenseManager.isExpired
                            ? Icons.warning_amber_outlined
                            : Icons.verified_outlined,
                        size: 12,
                        color: licenseManager.isExpired ? Colors.red : Colors.green,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _getLicenseTypeString(licenseManager.currentLicenseType),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: licenseManager.isExpired ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Builder(
                  builder: (context) => CircleAvatar(
                    radius: 16,
                    backgroundColor: primaryColor,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.person, size: 16, color: Colors.white),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Row(
            children: [
              // Navigation latérale pour écrans larges
              if (MediaQuery.of(context).size.width > 1200)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _changeSelectedIndex,
                  labelType: NavigationRailLabelType.selected,
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  selectedLabelTextStyle: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  selectedIconTheme: IconThemeData(
                    color: primaryColor,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  destinations: [
                    for (int i = 0; i < _pageIcons.length; i++)
                      _buildNavigationRailDestination(i, licenseManager),
                  ],
                ),
              // Contenu principal
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
          // Navigation du bas pour petit écran
          bottomNavigationBar: MediaQuery.of(context).size.width <= 1200
              ? NavigationBar(
            onDestinationSelected: _changeSelectedIndex,
            selectedIndex: _selectedIndex,
            destinations: [
              for (int i = 0; i < _pageIcons.length; i++)
                _buildNavigationDestination(i, licenseManager),
            ],
          )
              : null,
        );
      },
    );
  }

  // Construire une destination pour NavigationRail avec badge premium
  NavigationRailDestination _buildNavigationRailDestination(
      int index,
      LicenseManager licenseManager,
      ) {
    final pageTitle = _pageTitles[index];
    final isPremium = licenseManager.isFeaturePremium(pageTitle);

    return NavigationRailDestination(
      icon: Stack(
        children: [
          Icon(_pageIcons[index]),
          if (isPremium)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  shape: BoxShape.circle,
                ),
                child: Text('⭐', style: TextStyle(fontSize: 8)),
              ),
            ),
        ],
      ),
      selectedIcon: Stack(
        children: [
          Icon(_pageIcons[index]),
          if (isPremium)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  shape: BoxShape.circle,
                ),
                child: Text('⭐', style: TextStyle(fontSize: 8)),
              ),
            ),
        ],
      ),
      label: Text(pageTitle),
    );
  }

  // Construire une destination pour NavigationBar avec badge premium
  NavigationDestination _buildNavigationDestination(
      int index,
      LicenseManager licenseManager,
      ) {
    final pageTitle = _pageTitles[index];
    final isPremium = licenseManager.isFeaturePremium(pageTitle);

    return NavigationDestination(
      icon: Stack(
        children: [
          Icon(_pageIcons[index]),
          if (isPremium)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  shape: BoxShape.circle,
                ),
                child: Text('⭐', style: TextStyle(fontSize: 8)),
              ),
            ),
        ],
      ),
      selectedIcon: Stack(
        children: [
          Icon(_pageIcons[index]),
          if (isPremium)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  shape: BoxShape.circle,
                ),
                child: Text('⭐', style: TextStyle(fontSize: 8)),
              ),
            ),
        ],
      ),
      label: pageTitle,
    );
  }

  // Obtenir la représentation en chaîne du type de licence
  String _getLicenseTypeString(LicenseType licenseType) {
    switch (licenseType) {
      case LicenseType.basic:
        return 'Basic';
      case LicenseType.starter:
        return 'Starter';
      case LicenseType.pro:
        return 'Pro';
      case LicenseType.entreprise:
        return 'Enterprise';
      default:
        return 'Basic';
    }
  }
}