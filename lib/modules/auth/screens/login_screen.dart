import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../config/routes.dart';
import '../../../../../config/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../config/AppConstants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Ajout d'une variable pour suivre le mode de connexion sélectionné
  String _loginMode = "admin"; // Par défaut: "admin" ou "employee"

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        print('Tentative de connexion pour: $email');

        // Connexion avec Firebase Auth (la persistance est déjà configurée dans main.dart)
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        print('Authentification Firebase réussie');

        // Récupération de l'ID utilisateur authentifié
        final String uid = userCredential.user!.uid;

        // Vérification du type d'utilisateur dans Firestore
        final firestore = FirebaseFirestore.instance;

        if (_loginMode == "admin") {
          print('vérification des droits admin...');
          // Vérifier si l'utilisateur existe dans la collection 'users' (admin/manager)
          final userDoc = await firestore.collection('users').doc(uid).get();

          if (!userDoc.exists) {
            print('Pas de document admin trouvé');
            // L'utilisateur n'est pas un admin/manager
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Vous n'avez pas les droits d'administrateur ou de manager"),
                backgroundColor: Colors.red,
              ),
            );
            await FirebaseAuth.instance.signOut(); // DÃ©connexion
            setState(() => _isLoading = false);
            return;
          }

          print('Droits admin confirmés');
          // Vérifier si l'utilisateur a une licence
          final hasLicence = await _checkUserLicence(uid);
          
          if (!mounted) return;
          
          if (!hasLicence) {
            // Pas de licence ou licence expirée
            final userData = userDoc.data();
            if (userData == null || userData['licence'] == null) {
              // Nouvel utilisateur sans licence
              print('ðŸŽ¯ Nouvel utilisateur - redirection vers choosePlan');
              Navigator.pushReplacementNamed(context, AppRoutes.choosePlan);
            } else {
              // Licence expirée
              print('🎯 Licence expirée - redirection vers renewlicencePage');
              Navigator.pushReplacementNamed(context, AppRoutes.renewlicencePage);
            }
          } else {
            // Licence valide - redirection vers dashboard
            print('ðŸŽ¯ Licence valide - redirection vers dashboard');
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          }

        } else {
          print('🔍 Vérification des droits employé...');
          // Vérifier si l'utilisateur existe dans la collection 'staff' (employé)
          final staffDoc = await firestore.collection('staff').doc(uid).get();

          if (!staffDoc.exists) {
            print('❌ Pas de document staff trouvé');
            // L'utilisateur n'est pas un employé
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Vous n'avez pas les droits d'employé"),
                backgroundColor: Colors.red,
              ),
            );
            await FirebaseAuth.instance.signOut(); // Déconnexion
            setState(() => _isLoading = false);
            return;
          }

          print('✅ Droits employé confirmés');
          // Vérifier la licence du propriétaire
          final hasOwnerLicence = await _checkEmployeeOwnerLicense(uid);
          
          if (!mounted) return;
          
          if (hasOwnerLicence) {
            print('🎯 Licence propriétaire valide - redirection vers employeeDashboard');
            Navigator.pushReplacementNamed(context, AppRoutes.employeeDashboard);
          } else {
            print('❌ Licence propriétaire expirée');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("La licence de votre administrateur a expiré. Veuillez le contacter."),
                backgroundColor: Colors.orange,
              ),
            );
            await FirebaseAuth.instance.signOut();
            setState(() => _isLoading = false);
            return;
          }
        }

        // La redirection se fera automatiquement via authStateChanges
        print('🎯 Connexion réussie - en attente de redirection automatique...');

      } on FirebaseAuthException catch (e) {
        print('Erreur Firebase Auth: ${e.code}');
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'Aucun utilisateur trouvé avec cet email';
            break;
          case 'wrong-password':
            errorMessage = 'Mot de passe incorrect';
            break;
          case 'invalid-email':
            errorMessage = 'Email invalide';
            break;
          case 'user-disabled':
            errorMessage = 'Compte désactivé';
            break;
          case 'invalid-credential':
            errorMessage = 'Email ou mot de passe incorrect';
            break;
          default:
            errorMessage = 'Erreur de connexion: ${e.message}';
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      } catch (e) {
        print('❌ Erreur inattendue: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isMobile = size.width < 800;

    return Scaffold(
      body: Row(
        children: [
          if (!isMobile)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  color: GestoTheme.navyBlue,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElasticIn(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/gesto_logo2.png',
                            width: 250,
                            height: 250,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppConstants.appName,  // Utilise la constante
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: GestoTheme.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' ${AppConstants.appVersion}',  // Utilise la constante
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ]
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'Plateforme modulaire de gestion hôtelière et de restauration',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: GestoTheme.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            flex: isMobile ? 1 : 4,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 64,
                vertical: 32,
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isMobile) ...[
                        Center(
                          child: Icon(
                            Icons.home_work,
                            size: 80,
                            color: GestoTheme.navyBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'GESTO',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: GestoTheme.navyBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      Text(
                        'Connexion',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Veuillez saisir vos identifiants pour vous connecter',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sélection du mode de connexion
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _loginMode = "admin";
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _loginMode == "admin" ? GestoTheme.navyBlue : Colors.grey[300],
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Administrateur / Manager',
                                style: TextStyle(
                                  color: _loginMode == "admin" ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _loginMode = "employee";
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _loginMode == "employee" ? GestoTheme.navyBlue : Colors.grey[300],
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Employé',
                                style: TextStyle(
                                  color: _loginMode == "employee" ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez saisir votre email';
                                }
                                if (!value.contains('@')) {
                                  return 'Veuillez saisir un email valide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez saisir votre mot de passe';
                                }
                                if (value.length < 6) {
                                  return 'Le mot de passe doit contenir au moins 6 caractères';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _resetPassword,
                                child: const Text('Mot de passe oublié?'),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _loginMode == "admin"
                                      ? GestoTheme.white
                                      : Colors.white54,
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                    : Text(
                                  _loginMode == "admin"
                                      ? 'CONNEXION ADMINISTRATEUR'
                                      : 'CONNEXION EMPLOYÉ',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Vous n\'avez pas de compte?',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.register,
                                    );
                                  },
                                  child: const Text('Créer un compte'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre email')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email de réinitialisation envoyé à $email')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.message}'), backgroundColor: Colors.red),
      );
    }
  }
  Future<bool> _checkUserLicence(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      final userData = userDoc.data();
      if (userData == null || userData['licence'] == null) return false;
      if (userData['licenceExpiry'] != null || userData['licenceExpiryDate'] != null) {
        Timestamp? expiryTimestamp = userData['licenceExpiry'] ?? userData['licenceExpiryDate'];
        if (expiryTimestamp != null) {
          DateTime expiryDate = expiryTimestamp.toDate();
          if (expiryDate.isBefore(DateTime.now())) return false;
        }
      }
      return true;
    } catch (e) {
      print('Erreur vérification licence: $e');
      return false;
    }
  }

  Future<bool> _checkEmployeeOwnerLicense(String employeeId) async {
    try {
      final staffDoc = await FirebaseFirestore.instance.collection('staff').doc(employeeId).get();
      if (!staffDoc.exists) return false;
      final staffData = staffDoc.data();
      if (staffData == null || staffData['idadmin'] == null) return false;
      String ownerId = staffData['idadmin'];
      return await _checkUserLicence(ownerId);
    } catch (e) {
      print('Erreur vérification licence propriétaire: $e');
      return false;
    }
  }
}
