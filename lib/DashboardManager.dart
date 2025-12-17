import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'DashboardScreen.dart';
import 'RestaurantDashboard.dart';
import 'Screens/manager/CheckInPage.dart';
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
import 'Screens/manager/help/help_documentation_page.dart';
import 'Screens/manager/roadmap_page.dart';
import 'Screens/manager/roadmap_admin_page.dart';
import 'Screens/manager/support_client_page.dart';
import 'Screens/manager/support_admin_page.dart';
import 'services/support_service.dart';
import 'Screens/manager/onboarding/components/tutorial/tutorial_overlay.dart';
import 'Screens/manager/onboarding/services/tutorial_service.dart';
import 'Screens/manager/onboarding/services/initial_setup_tutorial_manager.dart';
import 'Screens/manager/onboarding/models/tutorial_step.dart';
import 'components/dashboard/licence_Ui.dart';
import 'components/dashboard/hotel_profile_drawer.dart';
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
  DashboardManagerState createState() => DashboardManagerState();
}

class DashboardManagerState extends State<DashboardManager> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  UserRole _userRole = UserRole.employee;
  StreamSubscription? _notificationSubscription;

  // Variables pour suivre l'état de l'UI
  bool _showSidebarLabels = true;
  bool _showTopBarLabels = true;

  // Variables pour le tutorial
  bool _showTutorial = false;
  List<TutorialStep> _tutorialSteps = [];
  TutorialService? _tutorialService;
  String? _userId;

  // Support service pour les notifications
  final SupportService _supportService = SupportService();

  // Liste complète des pages disponibles
  final List<Widget Function()> _allPages = [
        () => const Dashboard(),
        () => ModernReservationPage(),
        () => CheckInPage(),
        () => RoomsPage(),
        () => HourlyCheckInPage(),
        () => OccupiedRoomsPage(),
        () => PaymentPage(),
        () => FinancePage(),
        () => RestaurantDashboard(),
        () => TaskManagementPage(),
        () => ModernScheduleManagementPage(),
        () => GestionPersonnelPage(),
        () => RenewLicencePage(),
        () => UserManagementScreen(),
        () => const SupportClientPage(),
        () => const SupportAdminPage(),
        () => const RoadmapAdminPage(),
        () => SettingsPage(),
  ];

  // Titres de toutes les pages
  final List<String> _allPageTitles = [
    'Tableau de bord',
    'Réservations',
    'Enregistrement',
    'Chambres',
    'Passages',
    'Départ',
    'Paiements',
    'Finances',
    'Restaurant',
    'Tâches',
    'Emplois du temps',
    'Personnel',
    'Licences',
    'Administration',
    'Support',
    'Support Admin',
    'Roadmap Admin',
    'Paramètres',
  ];

  // Icônes de toutes les pages pour le menu
  final List<IconData> _allPageIcons = [
    Icons.dashboard_rounded,
    Icons.event_note_rounded,
    Icons.login_rounded,
    Icons.hotel_rounded,
    Icons.access_time_rounded,
    Icons.logout_rounded,
    Icons.payment_rounded,
    Icons.analytics_rounded,
    Icons.restaurant_rounded,
    Icons.task_alt_rounded,
    Icons.calendar_month_rounded,
    Icons.groups_rounded,
    Icons.workspace_premium_rounded,
    Icons.admin_panel_settings_rounded,
    Icons.support_agent_rounded,
    Icons.admin_panel_settings_rounded,
    Icons.map_rounded,
    Icons.settings_rounded,
  ];

  // Listes actives qui seront ajustées en fonction du rôle et de la licence
  late List<Widget Function()> _pages;
  late List<String> _pageTitles;
  late List<IconData> _pageIcons;
  late List<int> _accessiblePageIndices;

  // Clé pour forcer le rafraîchissement des pages
  final Map<int, UniqueKey> _pageKeys = {};

  void changeSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
      // Créer une nouvelle clé pour forcer le rafraîchissement de la page
      _pageKeys[index] = UniqueKey();
      print('[DASHBOARD] 📄 Changement vers page: ${_pageTitles[index]}');
    });

    // Rafraîchir les données si nécessaire
    _refreshCurrentPage();
  }

  void _refreshCurrentPage() {
    // Vous pouvez ajouter ici une logique pour rafraîchir les données
    // de la page actuelle si nécessaire
    print('[DASHBOARD] 🔄 Rafraîchissement de la page: ${_pageTitles[_selectedIndex]}');
  }

  @override
  void initState() {
    super.initState();
    _initializePageKeys();
    _initializeNotifications();
    _getUserRole();
    _checkAndInitializeTutorial();
  }

  void _initializePageKeys() {
    // Initialiser les clés pour toutes les pages
    for (int i = 0; i < _allPages.length; i++) {
      _pageKeys[i] = UniqueKey();
    }
  }

  void _initializeNotifications() {
    try {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.initialiser();
      print('[DASHBOARD] ✅ Notifications initialisées');
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur initialisation notifications: $e');
    }
  }

  Future<void> _checkAndInitializeTutorial() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Utiliser uid de FirebaseAuth pour les notifications support
      if (mounted) {
        setState(() {
          _userId = currentUser?.uid ?? 'anonymous';
        });
      }

      final prefs = await SharedPreferences.getInstance();
      _tutorialService = TutorialService(prefs);

      // Vérifier si le tutorial a déjà été complété
      final hasCompleted = await _tutorialService!.hasCompletedTutorial(_userId!, 'initial_setup_tutorial');

      if (!hasCompleted && mounted) {
        setState(() {
          _tutorialSteps = InitialSetupTutorialManager.getInitialSetupTutorialSteps();
          _showTutorial = true;
        });
        print('[DASHBOARD] 📖 Tutorial initialisé pour l\'utilisateur');
      } else {
        print('[DASHBOARD] ✅ Tutorial déjà complété');
      }
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur initialisation tutorial: $e');
    }
  }

  void _completeTutorial() {
    setState(() {
      _showTutorial = false;
    });
    print('[DASHBOARD] ✅ Tutorial complété');
  }

  void _skipTutorial() async {
    if (_tutorialService != null && _userId != null) {
      await _tutorialService!.completeTutorial(_userId!, 'initial_setup_tutorial');
    }
    setState(() {
      _showTutorial = false;
    });
    print('[DASHBOARD] ⏭️ Tutorial ignoré');
  }

  Future<void> _getUserRole() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userRoleStr = await authService.getCurrentUserRole();

      if (userRoleStr != null && mounted) {
        setState(() {
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
          _initPagesBasedOnRoleAndLicense();
        });
      }
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur lors de la récupération du rôle: $e');
      if (mounted) {
        _initPagesBasedOnRoleAndLicense();
      }
    }
  }

  void _initPagesBasedOnRoleAndLicense() {
    if (!mounted) {
      print('[DASHBOARD] ⚠️ Widget non monté, abandon initialisation pages');
      return;
    }

    try {
      List<int> roleBasedIndices = [];

      switch (_userRole) {
        case UserRole.admin:
          // Super admin du SaaS : accès complet incluant Support Admin et Roadmap Admin
          roleBasedIndices = List.generate(_allPages.length, (index) => index);
          break;
        case UserRole.manager:
          // Manager d'établissement : accès au Support Client uniquement
          roleBasedIndices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 17];
          break;
        case UserRole.receptionist:
          // Pas d'accès au support ni administration
          roleBasedIndices = [0, 1, 2, 3, 4, 5, 6, 17];
          break;
        case UserRole.employee:
          // Pas d'accès au support ni administration
          roleBasedIndices = [0, 3, 9, 10, 17];
          break;
        case UserRole.kitchen:
          // Pas d'accès au support ni administration
          roleBasedIndices = [0, 8, 9, 10, 17];
          break;
      }

      final licenseManager = Provider.of<LicenseManager>(context, listen: false);

      if (licenseManager.isExpired) {
        print('[DASHBOARD] ⏰ Licence expirée, accès limité');
        roleBasedIndices = roleBasedIndices.where((index) {
          final pageTitle = _allPageTitles[index];
          if (pageTitle == 'Tableau de bord' || pageTitle == 'Licences' || pageTitle == 'Paramètres') {
            return true;
          }
          // Support et Support Admin / Roadmap Admin uniquement pour les admins
          if (_userRole == UserRole.admin && (pageTitle == 'Support Admin' || pageTitle == 'Roadmap Admin')) {
            return true;
          }
          // Support Client pour les managers
          if (_userRole == UserRole.manager && pageTitle == 'Support') {
            return true;
          }
          return false;
        }).toList();

        if (!roleBasedIndices.contains(12)) {
          roleBasedIndices.add(12);
        }
      } else {
        // Filtrer par licence
        roleBasedIndices = roleBasedIndices.where((index) {
          final pageTitle = _allPageTitles[index];
          // Le support client est toujours accessible pour les managers, même avec licence de base
          if (_userRole == UserRole.manager && pageTitle == 'Support') {
            return true;
          }
          // Support Admin et Roadmap Admin uniquement pour les admins
          if (_userRole == UserRole.admin && (pageTitle == 'Support Admin' || pageTitle == 'Roadmap Admin')) {
            return true;
          }
          return licenseManager.canAccessPage(pageTitle);
        }).toList();
      }

      if (mounted) {
        setState(() {
          _accessiblePageIndices = roleBasedIndices;
          _pages = _accessiblePageIndices.map((i) => _allPages[i]).toList();
          _pageTitles = _accessiblePageIndices.map((i) => _allPageTitles[i]).toList();
          _pageIcons = _accessiblePageIndices.map((i) => _allPageIcons[i]).toList();

          if (_selectedIndex >= _pages.length) {
            _selectedIndex = 0;
          }

          // Recréer les clés pour les nouvelles pages
          for (int i = 0; i < _pages.length; i++) {
            _pageKeys[i] = UniqueKey();
          }

          print('[DASHBOARD] 📄 ${_pages.length} pages accessibles initialisées');
          print('[DASHBOARD] 📋 Pages disponibles: ${_pageTitles.join(", ")}');
          print('[DASHBOARD] 👤 Rôle actuel: $_userRole');
        });
      }
    } catch (e) {
      print('[DASHBOARD] ❌ Erreur initialisation pages: $e');
    }
  }

  void _checkLicenseStatus() {
    if (!mounted) {
      print('[DASHBOARD] ⚠️ Widget non monté, abandon vérification licence');
      return;
    }

    try {
      final licenseManager = Provider.of<LicenseManager>(context, listen: false);
      licenseManager.checkExpiration();

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

      _initPagesBasedOnRoleAndLicense();
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur vérification licence: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      _checkLicenseStatus();
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    print('[DASHBOARD] 🧹 Nettoyage des resources');
    super.dispose();
  }

  void _logout() {
    if (!mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.logout();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur logout: $e');
    }
  }

  Widget _buildTopBarIcon(String title, IconData icon, VoidCallback onPressed, {bool showLabel = true}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          tooltip: title,
        ),
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 10),
            ),
          ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF3F51B5);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return Consumer<LicenseManager>(
      builder: (context, licenseManager, child) {
        return Stack(
          children: [
            Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
          appBar: AppBar(
            toolbarHeight: 60,
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
              // Icones avec labels en haut
              if (isLargeScreen) ...[
                _buildTopBarIcon('Roadmap', Icons.rocket_launch_rounded, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoadmapPage(),
                    ),
                  );
                }, showLabel: _showTopBarLabels),
                
                _buildTopBarIcon('Tutorial', Icons.school_outlined, () async {
                  if (_tutorialService != null && _userId != null) {
                    await _tutorialService!.resetTutorial(_userId!, 'initial_setup_tutorial');
                    setState(() {
                      _tutorialSteps = InitialSetupTutorialManager.getInitialSetupTutorialSteps();
                      _showTutorial = true;
                    });
                    // Naviguer vers la première page du tutorial
                    if (_tutorialSteps.isNotEmpty && _tutorialSteps[0].pageIndex != null) {
                      final firstPageIndex = _accessiblePageIndices.indexOf(_tutorialSteps[0].pageIndex!);
                      if (firstPageIndex != -1) {
                        changeSelectedIndex(firstPageIndex);
                      }
                    }
                  }
                }, showLabel: _showTopBarLabels),

                _buildTopBarIcon('Aide', Icons.help_outline_rounded, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpDocumentationPage(),
                    ),
                  );
                }, showLabel: _showTopBarLabels),

                _buildTopBarIcon('Déconnexion', Icons.logout, () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Confirmation'),
                        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _logout();
                            },
                            child: const Text(
                              'Déconnecter',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }, showLabel: _showTopBarLabels),

                // Notifications
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Badge(
                          label: Text('${notificationProvider.nonLuesCount}'),
                          isLabelVisible: notificationProvider.nonLuesCount > 0,
                          child: const Icon(Icons.notifications_outlined),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return Dialog(
                                insetPadding: const EdgeInsets.only(top: 0, bottom: 0, right: 0),
                                alignment: Alignment.centerRight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(0),
                                ),
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                child:  NotificationPanel(),
                              );
                            },
                          );
                        },
                      ),
                      if (_showTopBarLabels)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            'Notif',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ),


              ] else ...[
                // Pour petits écrans, seulement les icônes
                IconButton(
                  icon: const Icon(Icons.rocket_launch_rounded),
                  tooltip: 'Roadmap',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RoadmapPage(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.school_outlined),
                  tooltip: 'Relancer le tutorial',
                  onPressed: () async {
                    if (_tutorialService != null && _userId != null) {
                      await _tutorialService!.resetTutorial(_userId!, 'initial_setup_tutorial');
                      setState(() {
                        _tutorialSteps = InitialSetupTutorialManager.getInitialSetupTutorialSteps();
                        _showTutorial = true;
                      });
                      // Naviguer vers la première page du tutorial
                      if (_tutorialSteps.isNotEmpty && _tutorialSteps[0].pageIndex != null) {
                        final firstPageIndex = _accessiblePageIndices.indexOf(_tutorialSteps[0].pageIndex!);
                        if (firstPageIndex != -1) {
                          changeSelectedIndex(firstPageIndex);
                        }
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded),
                  tooltip: 'Aide & Documentation',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpDocumentationPage(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Déconnexion',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text('Confirmation'),
                          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _logout();
                              },
                              child: const Text(
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
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, _) => IconButton(
                    icon: Badge(
                      label: Text('${notificationProvider.nonLuesCount}'),
                      isLabelVisible: notificationProvider.nonLuesCount > 0,
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return Dialog(
                            insetPadding: const EdgeInsets.only(top: 0, bottom: 0, right: 0),
                            alignment: Alignment.centerRight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            child:  NotificationPanel(),
                          );
                        },
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _isDarkMode = !_isDarkMode;
                    });
                  },
                ),
              ],

              // Badge licence
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
                      const SizedBox(width: 4),
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
                      icon: const Icon(Icons.person, size: 16, color: Colors.white),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          endDrawer: HotelProfileDrawer(
            onNavigateToSettings: () {
              // Trouver l'index de la page Paramètres dans les pages accessibles
              final settingsPageIndex = _accessiblePageIndices.indexOf(14);
              if (settingsPageIndex != -1) {
                changeSelectedIndex(settingsPageIndex);
              }
            },
          ),
          body: Row(
            children: [
              // Navigation latérale pour écrans larges
              if (isLargeScreen)
                Container(
                  width: _showSidebarLabels ? 200 : 80,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListView(
                    children: [
                      // Bouton pour afficher/masquer les labels
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                _showSidebarLabels ? Icons.chevron_left : Icons.chevron_right,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showSidebarLabels = !_showSidebarLabels;
                                });
                              },
                              tooltip: _showSidebarLabels ? 'Masquer les noms' : 'Afficher les noms',
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      for (int i = 0; i < _pageIcons.length; i++)
                        _buildSidebarItem(i, licenseManager),
                    ],
                  ),
                ),
              // Contenu principal
              Expanded(
                child: _pages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : KeyedSubtree(
                  key: _pageKeys[_selectedIndex],
                  child: _pages[_selectedIndex](),
                ),
              ),
            ],
          ),
          // Navigation du bas pour petit écran
          bottomNavigationBar: !isLargeScreen
              ? NavigationBar(
            onDestinationSelected: changeSelectedIndex,
            selectedIndex: _selectedIndex,
            destinations: [
              for (int i = 0; i < _pageIcons.length; i++)
                _buildNavigationDestination(i, licenseManager),
            ],
          )
              : null,
        ),
            // Afficher le tutorial si activé
            if (_showTutorial && _tutorialSteps.isNotEmpty)
              TutorialOverlay(
                steps: _tutorialSteps,
                tutorialId: 'initial_setup_tutorial',
                onComplete: _completeTutorial,
                onSkip: _skipTutorial,
                showSkipButton: true,
                showProgress: true,
                onNavigateToPage: (pageIndex) {
                  // Trouver l'index correspondant dans les pages accessibles
                  final accessibleIndex = _accessiblePageIndices.indexOf(pageIndex);
                  if (accessibleIndex != -1 && accessibleIndex < _pages.length) {
                    changeSelectedIndex(accessibleIndex);
                  }
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildSidebarItem(int index, LicenseManager licenseManager) {
    final pageTitle = _pageTitles[index];
    final isPremium = licenseManager.isFeaturePremium(pageTitle);
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF3F51B5);
    
    // Vérifier si c'est la page Support ou Support Admin pour afficher le badge
    final isSupportPage = pageTitle == 'Support';
    final isSupportAdminPage = pageTitle == 'Support Admin';

    return Material(
      color: isSelected
          ? primaryColor.withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: () => changeSelectedIndex(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              // Icône avec badge premium et/ou notifications
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    _pageIcons[index],
                    color: isSelected
                        ? primaryColor
                        : isDark ? Colors.white70 : Colors.black54,
                    size: 24,
                  ),
                  if (isPremium)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('⭐', style: TextStyle(fontSize: 8)),
                      ),
                    ),
                  // Badge de notifications pour la page Support
                  if (isSupportPage && _userId != null)
                    StreamBuilder<int>(
                      stream: _supportService.getTotalNotificationsCount(_userId!),
                      initialData: 0,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        
                        return Positioned(
                          right: isPremium ? -4 : -6,
                          top: isPremium ? 8 : -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  // Badge de notifications pour la page Support Admin (nouveaux messages utilisateur)
                  if (isSupportAdminPage)
                    StreamBuilder<int>(
                      stream: _supportService.getAdminNotificationsCount(),
                      initialData: 0,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        
                        return Positioned(
                          right: isPremium ? -4 : -6,
                          top: isPremium ? 8 : -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              if (_showSidebarLabels) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    pageTitle,
                    style: TextStyle(
                      color: isSelected
                          ? primaryColor
                          : isDark ? Colors.white70 : Colors.black54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Text('⭐', style: TextStyle(fontSize: 8)),
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Text('⭐', style: TextStyle(fontSize: 8)),
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
    }
  }
}