// Screens/welcome/InitialSetupChoiceScreen.dart
import 'package:flutter/material.dart';
import 'package:gesto/Screens/manager/onboarding/services/setup_checker.dart';
import 'package:gesto/Screens/manager/onboarding/services/tutorial_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/AuthService.dart';


class InitialSetupChoiceScreen extends StatefulWidget {
  const InitialSetupChoiceScreen({Key? key}) : super(key: key);

  @override
  _InitialSetupChoiceScreenState createState() => _InitialSetupChoiceScreenState();
}

class _InitialSetupChoiceScreenState extends State<InitialSetupChoiceScreen> {
  bool _isLoading = false;

  Future<void> _startWithTutorial() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final tutorialService = TutorialService(prefs);
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();
      final userId = user?.email ?? 'anonymous';

      // Réinitialiser le tutoriel pour être sûr
      await tutorialService.resetTutorial(userId, 'initial_setup_tutorial');

      // Naviguer vers le dashboard avec le tutoriel
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      print('Erreur démarrage avec tutoriel: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  Future<void> _startWithoutTutorial() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final setupChecker = SetupChecker(prefs);
      final tutorialService = TutorialService(prefs);
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();
      final userId = user?.email ?? 'anonymous';

      // Marquer le setup comme complété (l'utilisateur le fera manuellement)
      await setupChecker.markInitialSetupComplete();
      await tutorialService.completeTutorial(userId, 'initial_setup_tutorial');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      print('Erreur démarrage sans tutoriel: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3F51B5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hotel,
                  size: 60,
                  color: Color(0xFF3F51B5),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Bienvenue sur Gesto Hotel',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              const Text(
                'Votre solution complète de gestion hôtelière',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'Comment souhaitez-vous commencer ?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      _buildOptionCard(
                        icon: Icons.pause_presentation,
                        title: 'Avec le guide de configuration',
                        description: 'Nous vous guiderons étape par étape pour configurer votre hôtel',
                        color: const Color(0xFF3F51B5),
                        onTap: _startWithTutorial,
                      ),

                      const SizedBox(height: 16),

                      _buildOptionCard(
                        icon: Icons.explore_outlined,
                        title: 'Découvrir par moi-même',
                        description: 'Je préfère explorer les fonctionnalités à mon rythme',
                        color: Colors.grey,
                        onTap: _startWithoutTutorial,
                      ),

                      const SizedBox(height: 16),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              TextButton(
                onPressed: () {
                  // Afficher plus d'informations
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('À propos du guide de configuration'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Le guide vous aidera à :'),
                          SizedBox(height: 8),
                          Text('• Configurer les informations de votre hôtel'),
                          Text('• Créer vos chambres et leurs tarifs'),
                          Text('• Ajouter les membres de votre équipe'),
                          Text('• Comprendre les fonctionnalités principales'),
                          SizedBox(height: 16),
                          Text('Vous pourrez à tout moment relancer ce guide depuis les paramètres.'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Fermer'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'En savoir plus sur le guide',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}