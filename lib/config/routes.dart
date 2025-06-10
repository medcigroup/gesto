import 'package:flutter/material.dart';
import '../ChoosePlanScreen.dart';
import '../DashboardManager.dart';
import '../DashboardScreen.dart';
import '../EmployeeDashboard.dart';
import '../GestoLandingPage.dart';
import '../GestoPricingPage.dart';
import '../PaiementPlan.dart';
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
import 'ContactPage.dart';

class AppRoutes {
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
  static const String reservationPage = '/reservation';// Changement de nom ici
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
      case home:
        return MaterialPageRoute(builder: (_) => GestoLandingPage());
      case hourlyCheckInPage:
        return MaterialPageRoute(builder: (_) => HourlyCheckInPage());
      case comingSoonPage:
        return MaterialPageRoute(builder: (_) => ComingSoonPage());
      case settingspage:
        return MaterialPageRoute(builder: (_) => SettingsPage());
      case paiement:
        return MaterialPageRoute(builder: (_) => PaymentPage());
      case finance:
        return MaterialPageRoute(builder: (_) => FinancePage());
      case tarifpage:
        return MaterialPageRoute(builder: (_) => GestoPricingPage());
      case contactpage:
        return MaterialPageRoute(builder: (_) => ContactPage());
      case dashboard:
        return MaterialPageRoute(builder: (_) => DashboardManager());
      case activatelicence:
        return MaterialPageRoute(builder: (_) => ActivateLicencePage());
      case employees:
        return MaterialPageRoute(builder: (_) => GestionPersonnelPage());
      case chooseplanUpgrade:
        return MaterialPageRoute(builder: (_) => ChoosePlanUpgrade());
      case renewlicencePage:
        return MaterialPageRoute(builder: (_) => RenewLicencePage());
      case checkoutPage:
        return MaterialPageRoute(builder: (_) => CheckoutPage());
      case occupiedrooms:
        return MaterialPageRoute(builder: (_) => OccupiedRoomsPage());
      case thankYou:
        return MaterialPageRoute(builder: (_) => ThankYouScreen());
      case choosePlan:
        return MaterialPageRoute(builder: (_) => paiementplan());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case roomsPage:
        return MaterialPageRoute(builder: (_) => RoomsPage());
      case reservationPage:
        return MaterialPageRoute(builder: (_) => ModernReservationPage());
      case enregistrement:
        return MaterialPageRoute(builder: (_) => CheckInPage());
      case administration:
        return MaterialPageRoute(builder: (_) => UserManagementScreen());
      case services:
        return MaterialPageRoute(builder: (_) => TaskManagementPage());
      case employeeDashboard:
        return MaterialPageRoute(builder: (_) => EmployeeDashboard());


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
