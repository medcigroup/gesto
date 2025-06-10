import 'package:flutter/material.dart';
import 'dart:async';

class ComingSoonPage extends StatefulWidget {
  const ComingSoonPage({Key? key}) : super(key: key);

  @override
  State<ComingSoonPage> createState() => _ComingSoonPageState();
}

class _ComingSoonPageState extends State<ComingSoonPage> {
  final int _totalDays = 30;
  int _remainingDays = 30;
  Timer? _timer;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Simuler la progression du développement
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_remainingDays > 0) {
        setState(() {
          _remainingDays--;
          _progress = 1 - (_remainingDays / _totalDays);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.6),
            ],
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            margin: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(32),
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.construction_rounded,
                    size: 80,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nouvelle fonctionnalité en cours de développement',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Notre équipe travaille activement sur cette nouvelle fonctionnalité pour vous offrir une expérience exceptionnelle. Revenez bientôt pour découvrir toutes les nouveautés !',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progression',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lancement estimé: $_remainingDays jours restants',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Me notifier'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vous serez notifié au lancement !'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.info_outline),
                        label: const Text('En savoir plus'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('À propos de cette fonctionnalité'),
                              content: const Text(
                                'Cette nouvelle fonctionnalité vous permettra de gérer plus efficacement vos projets grâce à des outils d\'analyse avancés et une interface entièrement repensée pour une meilleure productivité.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Fermer'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}