import 'package:flutter/material.dart';
import '../ChoosePlanScreen.dart';
import '../DashboardScreen.dart';
import '../GestoLandingPage.dart';
import '../Screens/ReservationPage.dart';
import '../Screens/RoomsPage.dart';
import '../modules/auth/screens/ThankYouScreen.dart';
import '../modules/auth/screens/login_screen.dart';
import '../modules/auth/screens/register_screen.dart';

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
  static const String settings = '/settings';
  static const String choosePlan = '/choose-plan';
  static const String thankYou = '/thank-you';
  static const String roomsPage = '/roomsPage';
  static const String reservationPage = '/reservation';// Changement de nom ici

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => GestoLandingPage());
      case dashboard:
        return MaterialPageRoute(builder: (_) => Dashboard());

      case thankYou:
        return MaterialPageRoute(builder: (_) => ThankYouScreen());
      case choosePlan:
        return MaterialPageRoute(builder: (_) => ChoosePlanScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case roomsPage: // Correspond à la nouvelle route roomsPage
        return MaterialPageRoute(builder: (_) => RoomsPage());
      case reservationPage: // Correspond à la nouvelle route roomsPage
        return MaterialPageRoute(builder: (_) => ReservationPage());

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
