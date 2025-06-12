import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'Screens/manager/SettingsPage.dart';
import 'Screens/manager/TaskManagementPage.dart';
import 'Screens/manager/UserManagementScreen.dart';
import 'Screens/manager/renew_licence_page.dart';
import 'components/dashboard/licence_Ui.dart';
import 'components/messagerie/NotificationPanel.dart';
import 'components/messagerie/NotificationProvider.dart';
import 'components/reservation/ModernReservationPage.dart';
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

  // Liste complète des pages disponibles
  final List<Widget> _allPages = [
    const Dashboard(),
    ModernReservationPage(),
    RoomsPage(),
    TaskManagementPage(),
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
    Provider.of<NotificationProvider>(context, listen: false).initialiser();
    _getUserRole();
  }

  // Récupère le rôle de l'utilisateur
  Future<void> _getUserRole() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userRoleStr = await authService.getCurrentUserRole();

      if (userRoleStr != null) {
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
          // Initialiser les pages après avoir obtenu le rôle
          _initPagesBasedOnRoleAndLicense();
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération du rôle: $e');
      // Garder le rôle par défaut
      _initPagesBasedOnRoleAndLicense();
    }
  }

  // Configure les pages disponibles en fonction du rôle ET de la licence
  void _initPagesBasedOnRoleAndLicense() {
    // Vérifier d'abord les pages accessibles par rôle
    List<int> roleBasedIndices = [];

    switch (_userRole) {
      case UserRole.admin:
      // L'admin a accès à toutes les pages (sous réserve de licence)
        roleBasedIndices = List.generate(_allPages.length, (index) => index);
        break;
      case UserRole.manager:
      // Le manager a accès à la plupart des pages sauf administration
        roleBasedIndices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13];
        break;
      case UserRole.receptionist:
      // Le réceptionniste a accès aux pages liées à l'accueil
        roleBasedIndices = [0, 1, 2, 5, 6, 7, 13];
        break;
      case UserRole.employee:
      // L'employé a accès à un ensemble limité de pages
        roleBasedIndices = [0, 3, 13];
        break;
      case UserRole.kitchen:
      // Le personnel de cuisine a accès au tableau de bord, tâches et restaurant
        roleBasedIndices = [0, 3, 8, 13];
        break;
    }

    // Ensuite, filtrer en fonction de la licence
    final licenseManager = Provider.of<LicenseManager>(context, listen: false);

    // Si la licence est expirée, accès limité
    if (licenseManager.isExpired) {
      roleBasedIndices = roleBasedIndices.where((index) =>
      _allPageTitles[index] == 'Tableau de bord' ||
          _allPageTitles[index] == 'Licences' ||
          _allPageTitles[index] == 'Paramètres'
      ).toList();

      // S'assurer que la page de renouvellement de licence est accessible
      if (!roleBasedIndices.contains(11)) { // Index de 'Licences'
        roleBasedIndices.add(11);
      }
    }
    // Sinon, filtrer selon le type de licence
    else {
      roleBasedIndices = roleBasedIndices.where((index) =>
          licenseManager.canAccessPage(_allPageTitles[index])
      ).toList();
    }

    setState(() {
      _accessiblePageIndices = roleBasedIndices;
      _pages = _accessiblePageIndices.map((i) => _allPages[i]).toList();
      _pageTitles = _accessiblePageIndices.map((i) => _allPageTitles[i]).toList();
      _pageIcons = _accessiblePageIndices.map((i) => _allPageIcons[i]).toList();

      // S'assurer que l'index sélectionné est valide
      if (_selectedIndex >= _pages.length) {
        _selectedIndex = 0;
      }
    });
  }

  // Vérifier si la licence a expiré au moment de l'affichage
  void _checkLicenseStatus() {
    final licenseManager = Provider.of<LicenseManager>(context, listen: false);
    licenseManager.checkExpiration();

    // Si la licence a expiré, afficher une boîte de dialogue
    if (licenseManager.isExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => LicenseExpiredDialog(
            expiryDate: licenseManager.expiryDate,
            licenseType: licenseManager.currentLicenseType,
          ),
        );
      });
    }

    // Rafraîchir les pages disponibles
    _initPagesBasedOnRoleAndLicense();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Vérifier la licence à chaque changement de dépendances
    _checkLicenseStatus();
  }

  void _logout() {
    // Logique de déconnexion
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF3F51B5); // Indigo
    final licenseManager = Provider.of<LicenseManager>(context);

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
                'v1.2.7',
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
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Confirmation'),
                    content: Text('Voulez-vous vraiment vous déconnecter ?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                        },
                        child: Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          _logout();
                        },
                        child: Text('Déconnecter',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Consumer<NotificationProvider>(
              builder: (context, notificationProvider, _) => Badge(
                label: Text('${notificationProvider.nonLuesCount}'),
                isLabelVisible: notificationProvider.nonLuesCount > 0,
                child: Icon(Icons.notifications_outlined, color: isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            onPressed: () {
              // Afficher le panneau de notifications
              showDialog(
                context: context,
                builder: (BuildContext context) {
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
          // Navigation latérale pour écrans larges (visible uniquement sur grand écran)
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
  }

  // Construire un élément du menu avec badge premium si nécessaire
  Widget _buildMenuTile(int index, bool isDark, Color primaryColor, LicenseManager licenseManager) {
    final pageTitle = _pageTitles[index];
    final isPremium = licenseManager.isFeaturePremium(pageTitle);

    return ListTile(
      leading: Icon(
        _pageIcons[index],
        color: _selectedIndex == index ? primaryColor : isDark ? Colors.white70 : Colors.black54,
      ),
      title: Row(
        children: [
          Text(
            pageTitle,
            style: TextStyle(
              color: _selectedIndex == index ? primaryColor : isDark ? Colors.white : Colors.black87,
              fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          SizedBox(width: 8),
          if (isPremium) PremiumFeatureBadge(featureName: pageTitle),
        ],
      ),
      selected: _selectedIndex == index,
      onTap: () {
        if (isPremium) {
          // Afficher une boîte de dialogue pour les fonctionnalités premium
          _showPremiumFeatureDialog(pageTitle);
        } else {
          _changeSelectedIndex(index);
          Navigator.pop(context); // Fermer le drawer
        }
      },
    );
  }

  // Construire une destination pour NavigationRail avec badge premium si nécessaire
  NavigationRailDestination _buildNavigationRailDestination(int index, LicenseManager licenseManager) {
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
                child: Text(
                  '⭐',
                  style: TextStyle(fontSize: 8),
                ),
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
                child: Text(
                  '⭐',
                  style: TextStyle(fontSize: 8),
                ),
              ),
            ),
        ],
      ),
      label: Text(pageTitle),
    );
  }

  // Construire une destination pour NavigationBar avec badge premium si nécessaire
  NavigationDestination _buildNavigationDestination(int index, LicenseManager licenseManager) {
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
                child: Text(
                  '⭐',
                  style: TextStyle(fontSize: 8),
                ),
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
                child: Text(
                  '⭐',
                  style: TextStyle(fontSize: 8),
                ),
              ),
            ),
        ],
      ),
      label: pageTitle,
    );
  }

  // Afficher une boîte de dialogue pour les fonctionnalités premium
  void _showPremiumFeatureDialog(String featureName) {
    final licenseManager = Provider.of<LicenseManager>(context, listen: false);
    final requiredLicense = licenseManager.getRequiredLicenseNameForFeature(featureName);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'Fonctionnalité Premium',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La fonctionnalité "$featureName" nécessite une licence $requiredLicense ou supérieure.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Votre licence actuelle est : ${_getLicenseTypeString(licenseManager.currentLicenseType)}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade700.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade700.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber.shade700,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mettez à niveau votre licence pour accéder à toutes les fonctionnalités de Gesto.',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              'Fermer',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Mettre à niveau'),
            onPressed: () {
              Navigator.of(context).pop();
              // Rediriger vers la page de renouvellement de licence
              Navigator.of(context).pushNamed('/renewlicencePage');
            },
          ),
        ],
      ),
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