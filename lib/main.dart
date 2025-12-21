import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';
import '../../../config/routes.dart';
import 'FirebaseOptions.dart';
import 'package:provider/provider.dart';
import 'LicenseFeatures.dart';
import 'components/messagerie/NotificationProvider.dart';
import 'config/AuthService.dart';
import 'GestoLandingPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Active le routing sans # pour le web (URLs propres)
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  
  try {
    await Firebase.initializeApp(options: FirebaseConfig.options);
    print("Firebase est bien connecté !");
    
    // Configure la persistance de l'authentification pour le web
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      print("Persistance d'authentification configurée (LOCAL)");
    }
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
        title: 'Gesto - Gestion Hôtelière',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}

/// Widget qui gère la persistance d'authentification au démarrage
class AuthenticationGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // En attente de la vérification d'authentification
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Chargement...'),
                ],
              ),
            ),
          );
        }
        
        // Si l'utilisateur est connecté, utilise AuthChecker pour rediriger
        // (sauf pour les clients qui ont accès libre)
        if (snapshot.hasData && snapshot.data != null) {
          print('🔐 Session persistante détectée pour: ${snapshot.data!.email}');
          return AuthChecker();
        }
        
        // Sinon, affiche la page d'accueil
        print('👤 Aucune session - affichage de la page d\'accueil');
        return const GestoLandingPage();
      },
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

  Future<void> _checkAuthState() async {
    final User? user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      await _handleAuthenticatedUser(user);
    }
    // Si pas d'utilisateur, ne rien faire (sera géré par AuthenticationGate)
  }

  Future<void> _handleAuthenticatedUser(User user) async {
    try {
      // Vérifier d'abord si c'est un client
      bool isClient = await _checkIfClient(user.uid);
      if (isClient) {
        // Les clients ne sont PAS redirigés automatiquement
        // Ils restent sur la page d'accueil et peuvent naviguer librement
        print('👤 Client connecté - accès libre aux pages publiques');
        _navigateToHome();
        return;
      }
      
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

  Future<bool> _checkIfClient(String userId) async {
    try {
      final clientDoc = await FirebaseFirestore.instance
          .collection('clients')
          .doc(userId)
          .get();
      return clientDoc.exists;
    } catch (e) {
      print('Erreur lors de la vérification du statut client: $e');
      return false;
    }
  }

  Future<void> _handleClientUser() async {
    print('👤 Client détecté - redirection vers ClientDashboard');
    _navigateToClientDashboard();
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
    // Vérifier d'abord si l'utilisateur vient de s'inscrire (pas encore de licence)
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    if (!userDoc.exists) {
      _navigateToHome();
      return;
    }
    
    final userData = userDoc.data();
    
    // Si l'utilisateur n'a pas de champ 'licence', c'est qu'il vient de s'inscrire
    // Rediriger vers choosePlan
    if (userData == null || userData['licence'] == null) {
      print('📝 Nouvel utilisateur sans licence - redirection vers choosePlan');
      _navigateToChoosePlan();
      return;
    }
    
    bool hasLicence = await _checkUserLicence(userId);

    if (hasLicence) {
      _initializeNotifications();
      _navigateToDashboard();
    } else {
      // Pour les propriétaires avec licence expirée, rediriger vers la page de renouvellement
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

  void _navigateToClientDashboard() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.clientDashboard);
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

  void _navigateToChoosePlan() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.choosePlan);
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