import 'package:flutter/material.dart';
import '../ChoosePlanScreen.dart';
import '../DashboardScreen.dart';
import '../GestoLandingPage.dart';
import '../GestoPricingPage.dart';
import '../Screens/ActivateLicencePage.dart';
import '../Screens/CheckInPage.dart';
import '../Screens/CheckoutPage.dart';
import '../Screens/ChoosePlanUpgrade.dart';
import '../Screens/ComingSoonPage.dart';
import '../Screens/FinancePage.dart';
import '../Screens/GestionPersonnelPage.dart';
import '../Screens/PaymentPage.dart';
import '../Screens/ReservationPage.dart';
import '../Screens/RoomsPage.dart';
import '../Screens/SettingsPage.dart';
import '../Screens/UserManagementScreen.dart';
import '../Screens/renew_licence_page.dart';
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


  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => GestoLandingPage());
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
        return MaterialPageRoute(builder: (_) => Dashboard());
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
      case thankYou:
        return MaterialPageRoute(builder: (_) => ThankYouScreen());
      case choosePlan:
        return MaterialPageRoute(builder: (_) => ChoosePlanScreen());
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
