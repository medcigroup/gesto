import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'Screens/client/HotelOptionsStorePage.dart';
import 'config/routes.dart';
import 'services/support_service.dart';
import 'services/HotelSlugService.dart';
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

/// Dashboard principal de Gesto avec système de navigation intelligent
///
/// Fonctionnalités :
/// - Navigation multi-pages avec filtrage par rôle et licence
/// - Rafraîchissement automatique des pages lors du changement
/// - Gestion des badges de notifications
/// - Support du mode sombre/clair
/// - Tutorial intégré pour les nouveaux utilisateurs
/// - Système de licences (Basic, Starter, Pro, Entreprise)
///
/// Système de rafraîchissement :
/// - Chaque page est associée à une clé unique (UniqueKey)
/// - Lors d'un changement de page, une nouvelle clé est générée
/// - Cela force Flutter à reconstruire complètement le widget
/// - Les pages avec StreamBuilder se reconnectent automatiquement
///
/// Utilisation depuis l'extérieur :
/// ```dart
/// // Accéder au state du Dashboard
/// final dashboardState = context.findAncestorStateOfType<DashboardManagerState>();
/// // Rafraîchir manuellement la page actuelle
/// dashboardState?.refreshCurrentPage();
/// ```
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

  // Variable pour stocker le slug de l'hôtel (pour licence entreprise)
  String? _hotelSlug;
  bool _isLoadingSlug = true;

  // Liste complète des pages disponibles
  // Ordre logique : Dashboard → Opérations quotidiennes → Gestion → Administration → Support → Paramètres
  final List<Widget Function()> _allPages = [
        // 0. Tableau de bord principal
        () => const Dashboard(),

        // 1-6. Opérations quotidiennes (Réception & Hébergement)
        () => ModernReservationPage(),
        () => CheckInPage(),
        () => HourlyCheckInPage(),
        () => OccupiedRoomsPage(),
        () => RoomsPage(),
        () => PaymentPage(),

        // 7-8. Services additionnels
        () => RestaurantDashboard(),
        () => const HotelOptionsStorePage(),

        // 9-12. Gestion RH et organisation
        () => TaskManagementPage(),
        () => ModernScheduleManagementPage(),
        () => GestionPersonnelPage(),
        () => UserManagementScreen(),

        // 13-14. Finances et reporting
        () => FinancePage(),
        () => RenewLicencePage(),

        // 15-17. Support et administration SaaS
        () => const SupportClientPage(),
        () => const SupportAdminPage(),
        () => const RoadmapAdminPage(),

        // 18. Paramètres
        () => SettingsPage(),
  ];

  // Titres de toutes les pages
  final List<String> _allPageTitles = [
    // Dashboard
    'Tableau de bord',

    // Opérations quotidiennes
    'Réservations',
    'Enregistrement',
    'Passages',
    'Départ',
    'Chambres',
    'Paiements',

    // Services additionnels
    'Restaurant',
    'Boutique d\'options',

    // Gestion RH
    'Tâches',
    'Emplois du temps',
    'Personnel',
    'Administration',

    // Finances
    'Finances',
    'Licences',

    // Support
    'Support',
    'Support Admin',
    'Roadmap Admin',

    // Paramètres
    'Paramètres',
  ];

  // Icônes de toutes les pages pour le menu
  final List<IconData> _allPageIcons = [
    // Dashboard
    Icons.dashboard_rounded,

    // Opérations quotidiennes
    Icons.event_note_rounded,
    Icons.login_rounded,
    Icons.access_time_rounded,
    Icons.logout_rounded,
    Icons.hotel_rounded,
    Icons.payment_rounded,

    // Services additionnels
    Icons.restaurant_rounded,
    Icons.storefront_rounded,

    // Gestion RH
    Icons.task_alt_rounded,
    Icons.calendar_month_rounded,
    Icons.groups_rounded,
    Icons.admin_panel_settings_rounded,

    // Finances
    Icons.analytics_rounded,
    Icons.workspace_premium_rounded,

    // Support
    Icons.support_agent_rounded,
    Icons.admin_panel_settings_rounded,
    Icons.map_rounded,

    // Paramètres
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
      print('[DASHBOARD] 📄 Changement vers page: ${_pageTitles[index]}');
    });

    // Sauvegarder l'index sélectionné
    _saveSelectedIndex(index);

    // Rafraîchir la page nouvellement sélectionnée
    _refreshCurrentPage();
  }

  /// Sauvegarde l'index de page sélectionné dans le localStorage
  Future<void> _saveSelectedIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dashboard_selected_index', index);
      print('[DASHBOARD] 💾 Index sauvegardé: $index');
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur sauvegarde index: $e');
    }
  }

  /// Restaure l'index de page sélectionné depuis le localStorage
  Future<void> _restoreSelectedIndexFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt('dashboard_selected_index');

      if (savedIndex != null && mounted) {
        // Attendre que les pages soient initialisées
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted && savedIndex < _pages.length) {
          setState(() {
            _selectedIndex = savedIndex;
          });
          print('[DASHBOARD] 🔄 Index restauré: $savedIndex -> ${_pageTitles[savedIndex]}');
        }
      }
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur restauration index: $e');
    }
  }

  /// Rafraîchit intelligemment la page actuelle en fonction de son type
  void _refreshCurrentPage() {
    if (_selectedIndex >= _pageTitles.length) return;

    final pageTitle = _pageTitles[_selectedIndex];
    print('[DASHBOARD] 🔄 Rafraîchissement de la page: $pageTitle');

    // Forcer le rafraîchissement en créant une nouvelle clé pour la page
    // Cela permet de reconstruire complètement le widget de la page
    setState(() {
      _pageKeys[_selectedIndex] = UniqueKey();
    });

    // Rafraîchissements spécifiques selon le type de page
    try {
      switch (pageTitle) {
        case 'Tableau de bord':
          // Le Dashboard se rafraîchit automatiquement grâce à ses StreamBuilders
          print('[DASHBOARD] 🏠 Dashboard rafraîchi avec nouvelle clé');
          break;

        case 'Réservations':
          // Les réservations utilisent des streams Firestore
          print('[DASHBOARD] 📅 Réservations rafraîchies');
          break;

        case 'Chambres':
          // Les chambres se mettent à jour via Firestore
          print('[DASHBOARD] 🏨 État des chambres rafraîchi');
          break;

        case 'Personnel':
        case 'Administration':
          // Gestion du personnel et utilisateurs
          print('[DASHBOARD] 👥 Liste du personnel rafraîchie');
          break;

        case 'Finances':
          // Données financières
          print('[DASHBOARD] 💰 Données financières rafraîchies');
          break;

        case 'Restaurant':
          // Dashboard restaurant
          print('[DASHBOARD] 🍽️ Dashboard restaurant rafraîchi');
          break;

        case 'Support':
        case 'Support Admin':
          // Pages de support avec compteurs de notifications
          print('[DASHBOARD] 💬 Support rafraîchi');
          break;

        case 'Tâches':
          // Gestion des tâches
          print('[DASHBOARD] ✅ Tâches rafraîchies');
          break;

        case 'Emplois du temps':
          // Planning du personnel
          print('[DASHBOARD] 📆 Emplois du temps rafraîchis');
          break;

        default:
          // Autres pages : rafraîchissement standard
          print('[DASHBOARD] 🔄 Page "$pageTitle" rafraîchie');
      }
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur lors du rafraîchissement: $e');
    }
  }

  /// Méthode publique pour rafraîchir manuellement la page actuelle
  /// Utile pour les rafraîchissements déclenchés depuis l'extérieur
  void refreshCurrentPage() {
    _refreshCurrentPage();
  }

  @override
  void initState() {
    super.initState();
    _initializePageKeys();
    _initializeNotifications();
    _forceReloadLicense(); // 🔄 FORCER le rechargement de la licence AVANT tout
    _getUserRole();
    _checkAndInitializeTutorial();
    _loadHotelSlug();
    _restoreSelectedIndexFromStorage();
  }

  /// Force le rechargement de la licence depuis Firestore
  Future<void> _forceReloadLicense() async {
    try {
      final licenseManager = Provider.of<LicenseManager>(context, listen: false);
      print('[DASHBOARD] 🔄 Rechargement forcé de la licence...');
      await licenseManager.loadLicenseInfo();
      print('[DASHBOARD] ✅ Licence rechargée: ${licenseManager.currentLicenseType.name}');
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur rechargement licence: $e');
    }
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

  // Charger le slug de l'hôtel pour les utilisateurs entreprise
  Future<void> _loadHotelSlug() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final slug = await authService.getUserHotelSlug();
      
      if (mounted) {
        setState(() {
          _hotelSlug = slug;
          _isLoadingSlug = false;
        });
        
        if (slug != null) {
          print('[DASHBOARD] 🏨 Slug de l\'hôtel chargé: $slug');
        }
      }
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur chargement slug: $e');
      if (mounted) {
        setState(() {
          _isLoadingSlug = false;
        });
      }
    }
  }

  // Stream pour compter les réservations non confirmées (en attente)
  Stream<int> _getPendingReservationsCount() {
    if (_userId == null || _userId == 'anonymous') {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: _userId)
        .where('status', isEqualTo: 'en attente')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Ouvrir la page publique de l'hôtel
  Future<void> _openPublicHotelPage() async {
    if (_hotelSlug == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Page publique non disponible. Veuillez configurer votre hôtel dans les paramètres.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Navigation interne vers la page publique au lieu d'ouvrir dans le navigateur externe
      Navigator.pushNamed(context, '/hotel/$_hotelSlug');
      print('[DASHBOARD] 🌐 Navigation vers la page publique: $_hotelSlug');
    } catch (e) {
      print('[DASHBOARD] ⚠️ Erreur navigation page publique: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ouverture de la page: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

      // Pages réservées aux admins uniquement
      const adminOnlyPages = ['Administration', 'Support Admin', 'Roadmap Admin'];

      // Pages disponibles même avec licence expirée
      const essentialPages = ['Tableau de bord', 'Licences', 'Support', 'Paramètres'];

      // Admin a accès à TOUTES les pages sans restriction
      if (_userRole == UserRole.admin) {
        roleBasedIndices = List.generate(_allPages.length, (index) => index);
        print('[DASHBOARD] 👑 Administrateur : accès complet à toutes les pages');
      } else {
        final licenseManager = Provider.of<LicenseManager>(context, listen: false);

        // Filtrer les pages selon le rôle et la licence
        roleBasedIndices = List.generate(_allPages.length, (index) => index)
            .where((index) {
              final pageTitle = _allPageTitles[index];

              // Exclure les pages admin pour les non-admins
              if (adminOnlyPages.contains(pageTitle)) {
                return false;
              }

              // Si licence expirée : uniquement pages essentielles
              if (licenseManager.isExpired) {
                return essentialPages.contains(pageTitle);
              }

              // Sinon : vérifier les permissions de licence
              // Le support client est toujours accessible
              return pageTitle == 'Support' || licenseManager.canAccessPage(pageTitle);
            }).toList();

        // S'assurer que Licences est présent si licence expirée
        if (licenseManager.isExpired) {
          final licencesIndex = _allPageTitles.indexOf('Licences');
          if (licencesIndex != -1 && !roleBasedIndices.contains(licencesIndex)) {
            roleBasedIndices.add(licencesIndex);
          }
          print('[DASHBOARD] ⏰ Licence expirée, accès limité aux pages essentielles');
        }
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
      // Rediriger vers la page d'accueil et supprimer tout l'historique
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
      
      // Message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez été déconnecté avec succès'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
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
        // 🔄 ATTENDRE que la licence soit chargée depuis Firestore
        if (licenseManager.isLoading) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    'Chargement de votre licence...',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

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
                // Notifications (en premier)
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, _) => Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Column(
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
                ),

                const SizedBox(width: 8),

                // Aide
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: _buildTopBarIcon('Aide', Icons.help_outline_rounded, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpDocumentationPage(),
                      ),
                    );
                  }, showLabel: _showTopBarLabels),
                ),

                const SizedBox(width: 8),

                // Tutorial
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: _buildTopBarIcon('Tutorial', Icons.school_outlined, () async {
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
                ),

                const SizedBox(width: 8),

                // Roadmap
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: _buildTopBarIcon('Roadmap', Icons.rocket_launch_rounded, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RoadmapPage(),
                      ),
                    );
                  }, showLabel: _showTopBarLabels),
                ),

                const SizedBox(width: 8),

                // Icône Page Publique pour utilisateurs Entreprise
                if (licenseManager.currentLicenseType == LicenseType.entreprise) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: _buildTopBarIcon(
                      'Page Publique', 
                      Icons.public_rounded, 
                      _openPublicHotelPage,
                      showLabel: _showTopBarLabels,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Déconnexion
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: _buildTopBarIcon('Déconnexion', Icons.logout, () {
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
                ),


              ] else ...[
                // Pour petits écrans, seulement les icônes
                // Notifications
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
                // Icône Page Publique pour utilisateurs Entreprise (petit écran)
                if (licenseManager.currentLicenseType == LicenseType.entreprise)
                  IconButton(
                    icon: const Icon(Icons.public_rounded),
                    tooltip: 'Page publique de l\'hôtel',
                    onPressed: _openPublicHotelPage,
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

              // Badge licence avec design amélioré pour Entreprise
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: licenseManager.currentLicenseType == LicenseType.entreprise ? 12 : 8, 
                    vertical: licenseManager.currentLicenseType == LicenseType.entreprise ? 6 : 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: licenseManager.currentLicenseType == LicenseType.entreprise && !licenseManager.isExpired
                        ? const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0x8B6C63FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: licenseManager.currentLicenseType != LicenseType.entreprise
                        ? (licenseManager.isExpired
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1))
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: licenseManager.currentLicenseType == LicenseType.entreprise && !licenseManager.isExpired
                          ? const Color(0xFFFFD700)
                          : (licenseManager.isExpired
                              ? Colors.red.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3)),
                      width: licenseManager.currentLicenseType == LicenseType.entreprise ? 2 : 1,
                    ),
                    boxShadow: licenseManager.currentLicenseType == LicenseType.entreprise && !licenseManager.isExpired
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        licenseManager.isExpired
                            ? Icons.warning_amber_outlined
                            : (licenseManager.currentLicenseType == LicenseType.entreprise
                                ? Icons.workspace_premium_rounded
                                : Icons.verified_outlined),
                        size: licenseManager.currentLicenseType == LicenseType.entreprise ? 16 : 12,
                        color: licenseManager.currentLicenseType == LicenseType.entreprise && !licenseManager.isExpired
                            ? Colors.white
                            : (licenseManager.isExpired ? Colors.red : Colors.green),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getLicenseTypeString(licenseManager.currentLicenseType),
                        style: TextStyle(
                          fontSize: licenseManager.currentLicenseType == LicenseType.entreprise ? 11 : 10,
                          fontWeight: FontWeight.bold,
                          color: licenseManager.currentLicenseType == LicenseType.entreprise && !licenseManager.isExpired
                              ? Colors.white
                              : (licenseManager.isExpired ? Colors.red : Colors.green),
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (licenseManager.currentLicenseType == LicenseType.entreprise && !licenseManager.isExpired)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.white,
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
              final settingsGlobalIndex = _allPageTitles.indexOf('Paramètres');
              if (settingsGlobalIndex != -1) {
                final settingsPageIndex = _accessiblePageIndices.indexOf(settingsGlobalIndex);
                if (settingsPageIndex != -1) {
                  changeSelectedIndex(settingsPageIndex);
                }
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
          // Bouton flottant pour fonctionnalités entreprise
          floatingActionButton: licenseManager.currentLicenseType == LicenseType.entreprise && !licenseManager.isExpired
              ? _buildEnterpriseFloatingMenu(context, isDark)
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
    final isReservationsPage = pageTitle == 'Réservations';

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
                  // Badge pour les réservations non confirmées
                  if (isReservationsPage && _userId != null)
                    StreamBuilder<int>(
                      stream: _getPendingReservationsCount(),
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
                              color: Colors.deepOrange,
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
        return 'Entreprise';
    }
  }

  // Menu flottant pour les fonctionnalités entreprise
  Widget _buildEnterpriseFloatingMenu(BuildContext context, bool isDark) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x796C63FF), Color(0x796C63FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Fonctionnalités Entreprise',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildEnterpriseMenuItem(
                        icon: Icons.public_rounded,
                        title: 'Page Publique',
                        subtitle: 'Voir votre page publique',
                        onTap: () {
                          Navigator.pop(context);
                          _openPublicHotelPage();
                        },
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      _buildEnterpriseMenuItem(
                        icon: Icons.analytics_rounded,
                        title: 'Rapports Avancés',
                        subtitle: 'Analytics et statistiques détaillées',
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📊 Rapports avancés - Fonctionnalité en développement'),
                              backgroundColor: Color(0xFFFFAA00),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      _buildEnterpriseMenuItem(
                        icon: Icons.file_download_rounded,
                        title: 'Exports Personnalisés',
                        subtitle: 'Exporter vos données en différents formats',
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('💾 Exports personnalisés - Fonctionnalité en développement'),
                              backgroundColor: Color(0xFFFFAA00),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      _buildEnterpriseMenuItem(
                        icon: Icons.api_rounded,
                        title: 'API & Intégrations',
                        subtitle: 'Connectez vos outils externes',
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔌 API & Intégrations - Fonctionnalité en développement'),
                              backgroundColor: Color(0xFFFFAA00),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      backgroundColor: const Color(0xFFFFD700),
      child: const Icon(
        Icons.workspace_premium_rounded,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEnterpriseMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}