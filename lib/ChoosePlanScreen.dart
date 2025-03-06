import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gesto/widgets/LoadingOverlay.dart';
import '../../../../../config/routes.dart';
import '../../../../../config/theme.dart';
import 'config/LicenceGenerator.dart';

enum PlanId { free, starter, pro, enterprise }

class Plan {
  final String title;
  final String price;
  final String duration;
  final List<String> features;
  final PlanId planId;
  final bool isRecommended;

  Plan({
    required this.title,
    required this.price,
    required this.duration,
    required this.features,
    required this.planId,
    required this.isRecommended,
  });
}

class ChoosePlanScreen extends StatefulWidget {
  const ChoosePlanScreen({Key? key}) : super(key: key);

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  bool _isLoading = false;
  PlanId? _selectedPlan;

  Future<void> _selectPlan(PlanId planId) async {
    setState(() {
      _isLoading = true;
      _selectedPlan = planId;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté. Veuillez vous connecter pour choisir un plan.');
      }

      await Future.delayed(const Duration(seconds: 1)); // Simule un délai

      // Définir la durée de validité en jours et le type de licence en fonction du plan
      int durationDays = 30; // Durée par défaut
      String licenceType = planId.name; // Type de licence par défaut
      if (planId == PlanId.enterprise) {
        durationDays = 365;
      }

      // Générer la licence avec les dates et le type
      final licenceData = await LicenceGenerator.generateUniqueLicence(durationDays, licenceType);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'plan': planId.name,
        'planStartDate': FieldValue.serverTimestamp(),
        'planExpiryDate': _getExpiryDate(planId),
        'licence': licenceData['code'],
        'licenceGenerationDate': Timestamp.fromDate(licenceData['generationDate']),
        'licenceExpiryDate': Timestamp.fromDate(licenceData['expiryDate']),
        'licenceType': licenceData['licenceType'],
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan mis à jour avec succès!')),
      );

      if (planId == PlanId.enterprise) {
        Navigator.pushReplacementNamed(context, AppRoutes.thankYou);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Timestamp _getExpiryDate(PlanId planId) {
    final durations = {
      PlanId.free: 30,
      PlanId.starter: 30,
      PlanId.pro: 30,
      PlanId.enterprise: 365,
    };
    final now = DateTime.now();
    return Timestamp.fromDate(now.add(Duration(days: durations[planId]!)));
  }

  Widget _buildPlanCard(BuildContext context, Plan plan) {
    final isSelected = _selectedPlan == plan.planId;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: plan.isRecommended ? Colors.blueAccent.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(plan.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(plan.price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green)),
            if (plan.duration.isNotEmpty) Text(plan.duration, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const Divider(),
            ...plan.features.map((feature) => Padding(
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
              onPressed: () => _selectPlan(plan.planId),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.green : Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isSelected ? 'Plan actuel' : 'Choisir ce plan', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = [
      Plan(title: 'Essai Gratuit', price: '0 FCFA', duration: '30 jours', features: ['Module de réservation', '14 chambres max', 'Support de base', 'Rapports hebdo'], planId: PlanId.free, isRecommended: false),
      Plan(title: 'Starter', price: '20000 FCFA', duration: '/mois', features: ['Module de réservation', '20 chambres max', 'Gestion resto', '10 tables resto', 'Support prioritaire', 'Rapports quotidiens'], planId: PlanId.starter, isRecommended: true),
      Plan(title: 'Starter Pro', price: '50000 FCFA', duration: '/mois', features: ['Module de réservation', 'Chambres illimitées', 'Gestion resto', 'Tables resto illimitées', 'Support 24/7', 'Analyses temps réel', 'Marketing tools', 'Formation incluse'], planId: PlanId.pro, isRecommended: false),
      Plan(title: 'Grand Hôtel', price: 'Sur mesure', duration: '', features: ['Solution personnalisée', 'Intégrations API', 'Account manager dédié', 'Formation avancée', 'Maintenance incluse'], planId: PlanId.enterprise, isRecommended: false),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Choisir votre formule'), centerTitle: true),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight, maxWidth: 1900),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('Sélectionnez la formule qui correspond à vos besoins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: GestoTheme.navyBlue), textAlign: TextAlign.center),
                    ),
                    Center(
                      child: SizedBox(
                        height: 600,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: plans.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 20),
                          itemBuilder: (context, index) => _buildPlanCard(context, plans[index]),
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



