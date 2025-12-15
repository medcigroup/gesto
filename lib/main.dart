import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/routes.dart';
import 'FirebaseOptions.dart';
import 'package:provider/provider.dart';
import 'LicenseFeatures.dart';
import 'components/messagerie/NotificationProvider.dart';
import 'config/AuthService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: FirebaseConfig.options);
    print("Firebase est bien connecté !");
  } catch (e) {
    print("Erreur de connexion à Firebase : $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => LicenseManager()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hotel Management App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: AuthChecker(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}

class AuthChecker extends StatefulWidget {
  @override
  _AuthCheckerState createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        Future.microtask(() async {
          if (user != null) {
            await _handleAuthenticatedUser(user);
          } else {
            _navigateToHome();
          }
        });
      }
    });
  }

  Future<void> _handleAuthenticatedUser(User user) async {
    try {
      bool isEmployee = await _checkIfEmployee(user.uid);

      if (isEmployee) {
        await _handleEmployeeUser(user.uid);
      } else {
        await _handleOwnerUser(user.uid);
      }
    } catch (e) {
      print('Erreur lors de la vérification de l\'utilisateur: $e');
      _showErrorAndRedirect('Une erreur est survenue. Veuillez réessayer.');
    }
  }

  Future<void> _handleEmployeeUser(String userId) async {
    bool hasOwnerValidLicense = await _checkEmployeeOwnerLicense(userId);

    if (hasOwnerValidLicense) {
      _navigateToEmployeeDashboard();
    } else {
      // Pour les employés, on déconnecte car ils ne peuvent pas renouveler
      await FirebaseAuth.instance.signOut();
      _showErrorAndRedirect(
        "La licence de votre administrateur a expiré. Veuillez le contacter pour renouveler.",
      );
    }
  }

  Future<void> _handleOwnerUser(String userId) async {
    bool hasLicence = await _checkUserLicence(userId);

    if (hasLicence) {
      _initializeNotifications();
      _navigateToDashboard();
    } else {
      // Pour les propriétaires, rediriger vers la page de renouvellement
      _navigateToRenewLicence();
    }
  }

  Future<bool> _checkIfEmployee(String userId) async {
    try {
      final staffDoc = await FirebaseFirestore.instance
          .collection('staff')
          .doc(userId)
          .get();
      return staffDoc.exists;
    } catch (e) {
      print('Erreur lors de la vérification du statut d\'employé: $e');
      return false;
    }
  }

  Future<bool> _checkEmployeeOwnerLicense(String employeeId) async {
    try {
      final staffDoc = await FirebaseFirestore.instance
          .collection('staff')
          .doc(employeeId)
          .get();

      if (!staffDoc.exists) {
        return false;
      }

      final staffData = staffDoc.data();
      if (staffData == null || staffData['idadmin'] == null) {
        return false;
      }

      String ownerId = staffData['idadmin'];
      return await _checkUserLicence(ownerId);
    } catch (e) {
      print('Erreur lors de la vérification de la licence du propriétaire: $e');
      return false;
    }
  }

  Future<bool> _checkUserLicence(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data();
      if (userData == null || userData['licence'] == null) {
        return false;
      }

      if (userData['licenceExpiry'] != null || userData['licenceExpiryDate'] != null) {
        Timestamp? expiryTimestamp = userData['licenceExpiry'] ?? userData['licenceExpiryDate'];
        if (expiryTimestamp != null) {
          DateTime expiryDate = expiryTimestamp.toDate();
          if (expiryDate.isBefore(DateTime.now())) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      print('Erreur lors de la vérification de la licence: $e');
      return false;
    }
  }

  void _initializeNotifications() {
    if (mounted) {
      Provider.of<NotificationProvider>(context, listen: false).initialiser();
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  void _navigateToEmployeeDashboard() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.employeeDashboard);
    }
  }

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  void _navigateToRenewLicence() {
    if (mounted) {
      // Afficher un message avant la redirection
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Votre licence a expiré. Veuillez la renouveler pour continuer."),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );

      // Rediriger vers la page de renouvellement
      Navigator.pushReplacementNamed(context, AppRoutes.renewlicencePage);
    }
  }

  void _showErrorAndRedirect(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Vérification de votre accès...'),
          ],
        ),
      ),
    );
  }
}