import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ChoosePlanScreen.dart';
import '../DashboardManager.dart';
import '../DashboardScreen.dart';
import '../EmployeeDashboard.dart';
import '../GestoLandingPage.dart';
import '../GestoPricingPage.dart';
import '../gesto_mobile_download_page.dart';
import '../PaiementPlan.dart';
import '../RestaurantDashboard.dart';
import '../Screens/manager/ActivateLicencePage.dart';
import '../Screens/manager/CheckInPage.dart';
import '../Screens/manager/CheckoutPage.dart';
import '../Screens/manager/ChoosePlanUpgrade.dart';
import '../Screens/manager/ComingSoonPage.dart';
import '../Screens/manager/FinancePage.dart';
import '../Screens/manager/GestionPersonnelPage.dart';
import '../Screens/manager/HourlyCheckInPage.dart';
import '../Screens/manager/OccupiedRoomsPage.dart';
import '../Screens/manager/PaymentPage.dart';
import '../Screens/manager/RoomsPage.dart';
import '../Screens/manager/SettingsPage.dart';
import '../Screens/manager/TaskManagementPage.dart';
import '../Screens/manager/UserManagementScreen.dart';
import '../Screens/manager/ManagePublicPageScreen.dart';
import '../Screens/manager/renew_licence_page.dart';
import '../components/reservation/ModernReservationPage.dart';
import '../modules/auth/screens/ThankYouScreen.dart';
import '../modules/auth/screens/login_screen.dart';
import '../modules/auth/screens/register_screen.dart';
import '../widgets/LicenseProtectedRoute.dart';
import '../widgets/AuthStateWrapper.dart';
import '../Screens/public/PublicHotelPage.dart';
import '../Screens/client/ClientDashboard.dart';
import '../Screens/client/ModernClientBookingPage.dart';
import 'ContactPage.dart';

class AppRoutes {
  // Routes publiques - accessibles sans authentification
  static const List<String> publicRoutes = [
    home,
    login,
    register,
    tarifpage,
    contactpage,
    choosePlan,
    thankYou,
    mobileDownload,
    clientDashboard,
    modernClientBooking,
    // Les routes dynamiques /hotel/* sont gérées dans onGenerateRoute
  ];

  // Constantes de routes
  static const String home = '/home';
  static const String mobileDownload = '/mobile-download';
  static const String hotelBase = '/hotel';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String rooms = '/rooms';
  static const String restaurant = '/restaurant';
  static const String clients = '/clients';
  static const String employees = '/employees';
  static const String statistiques = '/statistiques';
  static const String finance = '/finance';
  static const String settingspage = '/settingspage ';
  static const String choosePlan = '/choose-plan';
  static const String thankYou = '/thank-you';
  static const String roomsPage = '/roomsPage';
  static const String reservationPage = '/reservation';
  static const String enregistrement = '/enregistrement';
  static const String checkoutPage = '/checkoutPage';
  static const String renewlicencePage = '/renewlicencePage';
  static const String chooseplanUpgrade = '/chooseplanUpgrade';
  static const String activatelicence = '/ActivateLicencePage';
  static const String administration = '/Administration';
  static const String tarifpage = '/tarifpage';
  static const String contactpage = '/contactpage';
  static const String comingSoonPage = '/comingSoonPage';
  static const String paiement = '/paiement';
  static const String occupiedrooms = '/occupiedrooms';
  static const String hourlyCheckInPage = '/hourlyCheckInPage';
  static const String services = '/services';
  static const String employeeDashboard = '/employeeDashboard';
  static const String managePublicPage = '/manage-public-page';
  static const String clientDashboard = '/client-dashboard';
  static const String modernClientBooking = '/modern-client-booking';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    print('📍 Route demandée: ${settings.name}');
    
    // Route racine - gérer l'authentification
    if (settings.name == '/' || settings.name == null || settings.name!.isEmpty) {
      return MaterialPageRoute(
        builder: (_) {
          // Importer AuthenticationGate depuis main.dart n'est pas possible
          // Donc on gère directement ici
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Si connecté, vérifier le type d'utilisateur
            return FutureBuilder<Widget>(
              future: _getHomePageForUser(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return snapshot.data ?? const GestoLandingPage();
              },
            );
          }
          return const GestoLandingPage();
        },
        settings: settings,
      );
    }
    
    // Gestion des routes dynamiques /hotel/:slug (TOUJOURS PUBLIQUES)
    if (settings.name != null && settings.name!.startsWith('/hotel/')) {
      final slug = settings.name!.replaceFirst('/hotel/', '');
      if (slug.isNotEmpty) {
        print('🏨 Chargement de la page publique pour: $slug');
        return MaterialPageRoute(
          builder: (_) => PublicHotelPage(hotelSlug: slug),
          settings: settings,
        );
      }
    }
    
    // Vérifier si la route demandée est une route protégée
    // Les routes /hotel/* sont déjà gérées ci-dessus, donc ne pas les vérifier ici
    final isPublicRoute = publicRoutes.contains(settings.name) || 
                          (settings.name?.startsWith('/hotel/') ?? false);
    final isProtectedRoute = !isPublicRoute;
    
    // Si c'est une route protégée et que l'utilisateur n'est pas connecté
    if (isProtectedRoute && FirebaseAuth.instance.currentUser == null) {
      // Rediriger vers login avec la route demandée en paramètre
      return MaterialPageRoute(
        builder: (_) => const LoginScreen(),
        settings: RouteSettings(arguments: settings.name),
      );
    }
    
    switch (settings.name) {
    // ===== ROUTES PUBLIQUES (pas de protection) =====

      case home:
        return MaterialPageRoute(builder: (_) => const GestoLandingPage());

      case login:
        return MaterialPageRoute(
          builder: (_) => const AuthStateWrapper(
            child: LoginScreen(),
          ),
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const AuthStateWrapper(
            child: RegisterScreen(),
          ),
        );

      case tarifpage:
        return MaterialPageRoute(builder: (_) => GestoPricingPage());

      case contactpage:
        return MaterialPageRoute(builder: (_) => ContactPage());

      case choosePlan:
        return MaterialPageRoute(builder: (_) => paiementplan());

      case thankYou:
        return MaterialPageRoute(builder: (_) => ThankYouScreen());

      case mobileDownload:
        return MaterialPageRoute(builder: (_) => const GestoMobileDownloadPage());

    // ===== PAGES TOUJOURS ACCESSIBLES (même avec licence expirée) =====

    // Page de renouvellement - CRITIQUE : doit être accessible même avec licence expirée
      case renewlicencePage:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Licences',
            bypassLicenseCheck: true, // ⚠️ IMPORTANT : bypass pour éviter la boucle
            child: RenewLicencePage(),
          ),
        );

    // Paramètres - Toujours accessible
      case settingspage:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Paramètres',
            child: SettingsPage(),
          ),
        );

    // Dashboard - Toujours accessible (mais avec fonctionnalités limitées si expiré)
      case dashboard:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Tableau de bord',
            child: DashboardManager(),
          ),
        );

    // Client Dashboard - Accessible pour les clients authentifiés
      case clientDashboard:
        return MaterialPageRoute(
          builder: (_) => const ClientDashboard(),
        );

    // Modern Client Booking - Nouvelle page de réservation moderne
      case modernClientBooking:
        return MaterialPageRoute(
          builder: (_) => const ModernClientBookingPage(),
        );

    // Activation de licence - Accessible même avec licence expirée
      case activatelicence:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            bypassLicenseCheck: true, // Permettre l'activation même avec licence expirée
            child: ActivateLicencePage(),
          ),
        );

    // Mise à niveau - Accessible même avec licence expirée
      case chooseplanUpgrade:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            bypassLicenseCheck: true, // Permettre de voir les offres
            child: ChoosePlanUpgrade(),
          ),
        );

    // ===== ROUTES PROTÉGÉES NORMALEMENT =====

    // Restaurant - Nécessite licence PRO ou supérieure
      case restaurant:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Restaurant',
            child: RestaurantDashboard(),
          ),
        );

    // Passages (Hourly Check-In)
      case hourlyCheckInPage:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Passages',
            child: HourlyCheckInPage(),
          ),
        );

    // Emplois du temps - Nécessite STARTER
      case comingSoonPage:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Emplois du temps',
            child: ComingSoonPage(),
          ),
        );

    // Paiements
      case paiement:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Paiements',
            child: PaymentPage(),
          ),
        );

    // Finances
      case finance:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Finances',
            child: FinancePage(),
          ),
        );

    // Personnel
      case employees:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Personnel',
            child: GestionPersonnelPage(),
          ),
        );

    // Départ (Checkout)
      case checkoutPage:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Départ',
            child: CheckoutPage(),
          ),
        );

    // Chambres occupées
      case occupiedrooms:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            child: OccupiedRoomsPage(),
          ),
        );

    // Gestion des chambres
      case roomsPage:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Chambres',
            child: RoomsPage(),
          ),
        );

    // Réservations
      case reservationPage:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Réservations',
            child: ModernReservationPage(),
          ),
        );

    // Enregistrement (Check-In)
      case enregistrement:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Enregistrement',
            child: CheckInPage(),
          ),
        );

    // Administration
      case administration:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Administration',
            child: UserManagementScreen(),
          ),
        );

    // Tâches - Nécessite STARTER
      case services:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Taches',
            child: TaskManagementPage(),
          ),
        );

    // Gestion de la page publique - Nécessite Entreprise
      case managePublicPage:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: false,
            pageTitle: 'Page Publique',
            child: const ManagePublicPageScreen(),
          ),
        );

    // ===== ROUTES EMPLOYÉS =====

      case employeeDashboard:
        return MaterialPageRoute(
          builder: (_) => LicenseProtectedRoute(
            isEmployeeRoute: true,
            pageTitle: 'Tableau de bord',
            child: EmployeeDashboard(),
          ),
        );

    // ===== ROUTE PAR DÉFAUT =====

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  // Fonction helper pour déterminer la page d'accueil selon le type d'utilisateur
  static Future<Widget> _getHomePageForUser(String userId) async {
    try {
      // Vérifier si c'est un client
      final clientDoc = await FirebaseFirestore.instance
          .collection('clients')
          .doc(userId)
          .get();
      
      if (clientDoc.exists) {
        // Les clients vont sur la landing page publique
        print('👤 Client connecté - landing page');
        return const GestoLandingPage();
      }

      // Vérifier si c'est un employé
      final staffDoc = await FirebaseFirestore.instance
          .collection('staff')
          .doc(userId)
          .get();

      if (staffDoc.exists) {
        print('👔 Employé connecté - employee dashboard');
        return EmployeeDashboard();
      }

      // Sinon c'est un propriétaire
      print('🏨 Propriétaire connecté - dashboard');
      return DashboardManager();
    } catch (e) {
      print('Erreur lors de la détermination de la page d\'accueil: $e');
      return const GestoLandingPage();
    }
  }
}