import 'package:flutter/material.dart';
import '../ChoosePlanScreen.dart';
import '../DashboardManager.dart';
import '../DashboardScreen.dart';
import '../EmployeeDashboard.dart';
import '../GestoLandingPage.dart';
import '../GestoPricingPage.dart';
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
import '../Screens/manager/renew_licence_page.dart';
import '../components/reservation/ModernReservationPage.dart';
import '../modules/auth/screens/ThankYouScreen.dart';
import '../modules/auth/screens/login_screen.dart';
import '../modules/auth/screens/register_screen.dart';
import '../widgets/LicenseProtectedRoute.dart';
import 'ContactPage.dart';

class AppRoutes {
  // Constantes de routes
  static const String home = '/home';
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

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
    // ===== ROUTES PUBLIQUES (pas de protection) =====

      case home:
        return MaterialPageRoute(builder: (_) => GestoLandingPage());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case tarifpage:
        return MaterialPageRoute(builder: (_) => GestoPricingPage());

      case contactpage:
        return MaterialPageRoute(builder: (_) => ContactPage());

      case choosePlan:
        return MaterialPageRoute(builder: (_) => paiementplan());

      case thankYou:
        return MaterialPageRoute(builder: (_) => ThankYouScreen());

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
}