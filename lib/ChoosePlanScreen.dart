import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gesto/widgets/LoadingOverlay.dart';
import '../../../../../config/routes.dart';
import '../../../../../config/theme.dart';

class ChoosePlanScreen extends StatefulWidget {
  const ChoosePlanScreen({Key? key}) : super(key: key);

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  bool _isLoading = false;
  String? _selectedPlan;

  Future<void> _selectPlan(String planId) async {
    setState(() {
      _isLoading = true; // Active l'overlay
      _selectedPlan = planId;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Simule un délai de 10 secondes
      await Future.delayed(const Duration(seconds: 20));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'plan': planId,
        'planStartDate': FieldValue.serverTimestamp(),
        'planExpiryDate': _getExpiryDate(planId),
      });

      if (!mounted) return;

      // Redirection immédiate vers "Merci" si le plan est "Enterprise"
      if (planId == 'enterprise') {
        Navigator.pushReplacementNamed(context, AppRoutes.thankYou);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false); // Désactive l'overlay
    }
  }

  Timestamp _getExpiryDate(String planId) {
    final now = DateTime.now();
    switch (planId) {
      case 'free':
        return Timestamp.fromDate(now.add(const Duration(days: 30)));
      case 'enterprise':
        return Timestamp.fromDate(now.add(const Duration(days: 365)));
      default:
        return Timestamp.fromDate(now.add(const Duration(days: 30)));
    }
  }

  Widget _buildPlanCard(BuildContext context, {
    required String title,
    required String price,
    required String duration,
    required List<String> features,
    required String planId,
    required bool isRecommended,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isRecommended ? Colors.blueAccent.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              price,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green),
            ),
            if (duration.isNotEmpty)
              Text(duration, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const Divider(),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 18),
                  const SizedBox(width: 5),
                  Expanded(child: Text(feature, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _selectPlan(planId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Choisir ce plan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir votre formule'),
        centerTitle: true,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading, // Contrôle l'affichage de l'overlay
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: 1900,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Sélectionnez la formule qui correspond à vos besoins',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: GestoTheme.navyBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Center( // Centre horizontalement la ListView
                      child: SizedBox(
                        height: 600,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 4,
                          separatorBuilder: (context, index) => const SizedBox(width: 20),
                          itemBuilder: (context, index) {
                            switch (index) {
                              case 0:
                                return _buildPlanCard(
                                  context,
                                  title: 'Essai Gratuit',
                                  price: '0 FCFA',
                                  duration: '30 jours',
                                  features: [
                                    'Module de réservation',
                                    '14 chambres maximum',
                                    'Support de base',
                                    'Rapports hebdomadaires',
                                  ],
                                  planId: 'free',
                                  isRecommended: false,
                                );
                              case 1:
                                return _buildPlanCard(
                                  context,
                                  title: 'Starter',
                                  price: '20000 FCFA',
                                  duration: '/mois',
                                  features: [
                                    'Module de réservation',
                                    '20 chambres maximum',
                                    'Module de gestion restaurant activé',
                                    '10 tables de restaurant maximum',
                                    'Support prioritaire',
                                    'Rapports quotidiens',
                                  ],
                                  planId: 'starter',
                                  isRecommended: true,
                                );
                              case 2:
                                return _buildPlanCard(
                                  context,
                                  title: 'Starter Pro',
                                  price: '50000 FCFA',
                                  duration: '/mois',
                                  features: [
                                    'Module de réservation',
                                    'Chambres illimitées',
                                    'Module de gestion restaurant activé',
                                    'Tables de restaurant illimitées',
                                    'Support 24/7',
                                    'Analyses en temps réel',
                                    'Marketing tools',
                                    'Formation incluse',
                                  ],
                                  planId: 'pro',
                                  isRecommended: false,
                                );
                              case 3:
                                return _buildPlanCard(
                                  context,
                                  title: 'Grand Hôtel',
                                  price: 'Sur mesure',
                                  duration: '',
                                  features: [
                                    'Solution personnalisée',
                                    'Intégrations API',
                                    'Account manager dédié',
                                    'Formation avancée',
                                    'Maintenance incluse',
                                  ],
                                  planId: 'enterprise',
                                  isRecommended: false,
                                );
                              default:
                                return const SizedBox();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}



