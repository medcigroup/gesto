import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gesto/widgets/LoadingOverlay.dart';
import '../../../../../config/routes.dart';
import '../../../../../config/theme.dart';
import '../config/LicenceGenerator.dart';


enum PlanId { basic, starter, pro, entreprise,}

class Plan {
  final String title;
  final String price;
  final String duration;
  final List<String> features;
  final PlanId planId;
  final bool isRecommended;
  final bool isDisabled;

  Plan({
    required this.title,
    required this.price,
    required this.duration,
    required this.features,
    required this.planId,
    required this.isRecommended,
    this.isDisabled = false,
  });
}

class ChoosePlanUpgrade extends StatefulWidget {
  const ChoosePlanUpgrade({Key? key}) : super(key: key);

  @override
  State<ChoosePlanUpgrade> createState() => _ChoosePlanUpgradeState();
}

class _ChoosePlanUpgradeState extends State<ChoosePlanUpgrade> {
  bool _isLoading = true;
  PlanId? _currentPlan;
  PlanId? _selectedPlan;
  DateTime? _currentPlanExpiryDate;
  int _remainingDays = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
  }

  Future<void> _loadCurrentPlan() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté. Veuillez vous connecter pour mettre à jour votre plan.');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData.containsKey('plan')) {
          final currentPlanStr = userData['plan'] as String;
          _currentPlan = PlanId.values.firstWhere(
                (p) => p.name == currentPlanStr,
            orElse: () => PlanId.basic,
          );

          if (userData.containsKey('licenceExpiryDate')) {
            final expiryTimestamp = userData['licenceExpiryDate'] as Timestamp?;
            if (expiryTimestamp != null) {
              _currentPlanExpiryDate = expiryTimestamp.toDate();

              final now = DateTime.now();
              _remainingDays = _currentPlanExpiryDate!.difference(now).inDays;
              if (_remainingDays < 0) _remainingDays = 0;
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement du plan: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  


  Future<void> _upgradePlan(PlanId planId) async {
    setState(() {
      _isLoading = true;
      _selectedPlan = planId;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté. Veuillez vous connecter pour mettre à jour votre plan.');
      }

      // Vérifier si c'est un downgrade ou un upgrade
      final isDowngrade = planId.index < (_currentPlan?.index ?? 0);

      if (isDowngrade) {
        // Demander confirmation pour un downgrade
        final shouldDowngrade = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmation'),
            content: const Text('Passer à un plan inférieur peut entraîner une perte de fonctionnalités. Êtes-vous sûr de vouloir continuer?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continuer'),
              ),
            ],
          ),
        );

        if (shouldDowngrade != true) {
          setState(() => _isLoading = false);
          return;
        }
      }

      await Future.delayed(const Duration(seconds: 1)); // Simule un délai

      // Définir la durée de validité en jours et le type de licence en fonction du plan
      int durationDays = 30; // Durée par défaut
      String licenceType = planId.name; // Type de licence par défaut
      if (planId == PlanId.entreprise) {
        durationDays = 365;
      }

      // Calcul de la durée ajustée si un plan est en cours
      if (_currentPlanExpiryDate != null && _remainingDays > 0) {
        // Ajouter les jours restants du plan actuel si upgrading
        if (!isDowngrade) {
          durationDays += _remainingDays;
        }
      }

      // Générer la nouvelle licence avec les dates et le type
      final licenceData = await LicenceGenerator.generateUniqueLicence(durationDays, licenceType);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'plan': planId.name,
        'planPreviousType': _currentPlan?.name,
        'planUpgradeDate': FieldValue.serverTimestamp(),
        'planStartDate': FieldValue.serverTimestamp(),
        'planExpiryDate': Timestamp.fromDate(licenceData['expiryDate']),
        'licence': licenceData['code'],
        'licenceGenerationDate': Timestamp.fromDate(licenceData['generationDate']),
        'licenceExpiryDate': Timestamp.fromDate(licenceData['expiryDate']),
        'licenceType': licenceData['licenceType'],
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDowngrade
              ? 'Plan rétrogradé avec succès!'
              : 'Plan mis à niveau avec succès!'),
          backgroundColor: Colors.green,
        ),
      );

      if (planId == PlanId.entreprise) {
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

  Widget _buildPlanCard(BuildContext context, Plan plan) {
    final isCurrentPlan = _currentPlan == plan.planId;
    final isSelected = _selectedPlan == plan.planId;
    final isUpgrade = _currentPlan != null && plan.planId.index > _currentPlan!.index;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: plan.isRecommended ? Colors.blueAccent.withOpacity(0.1) : Colors.white,
          border: isCurrentPlan
              ? Border.all(color: Colors.green, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isCurrentPlan)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Plan actuel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isUpgrade)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Mise à niveau',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 10),
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
            if (_remainingDays > 0 && isCurrentPlan)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Jours restants: $_remainingDays',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: plan.isDisabled || isCurrentPlan ? null : () => _upgradePlan(plan.planId),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? Colors.green
                    : isUpgrade
                    ? Colors.orange
                    : Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: Text(
                isCurrentPlan
                    ? 'Plan actuel'
                    : isUpgrade
                    ? 'Mettre à niveau'
                    : 'Changer de plan',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Générer la liste des plans en fonction du plan actuel
    final isFreePlanExpired = _currentPlan == PlanId.basic && _remainingDays <= 0;
    final plans = [
      Plan(
        title: 'Basic',
        price: '15000 FCFA',
        duration: '/mois',
        features: ['Module de réservation', '14 chambres max', 'Support de base', 'Rapports hebdo'],
        planId: PlanId.basic,
        isRecommended: false,
        isDisabled: isFreePlanExpired ||
            (_currentPlan != null && _currentPlan!.index > PlanId.basic.index),
      ),
      Plan(
        title: 'Starter',
        price: '20000 FCFA',
        duration: '/mois',
        features: ['Module de réservation', '20 chambres max', 'Gestion resto', '10 tables resto', 'Support prioritaire', 'Rapports quotidiens'],
        planId: PlanId.starter,
        isRecommended: _currentPlan == PlanId.basic,
        isDisabled: _currentPlan == PlanId.starter,
      ),
      Plan(
        title: 'Pro',
        price: '50000 FCFA',
        duration: '/mois',
        features: ['Module de réservation', 'Chambres illimitées', 'Gestion resto', 'Tables resto illimitées', 'Support 24/7', 'Analyses temps réel', 'Marketing tools', 'Formation incluse'],
        planId: PlanId.pro,
        isRecommended: _currentPlan == PlanId.starter,
        isDisabled: _currentPlan == PlanId.pro,
      ),
      Plan(
        title: 'Grand Hôtel',
        price: 'Sur mesure',
        duration: '',
        features: ['Solution personnalisée', 'Intégrations API', 'Account manager dédié', 'Formation avancée', 'Maintenance incluse'],
        planId: PlanId.entreprise,
        isRecommended: _currentPlan == PlanId.pro,
        isDisabled: _currentPlan == PlanId.entreprise,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mise à niveau du plan'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
                      child: Text(
                          'Mettez à niveau votre plan pour débloquer plus de fonctionnalités',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: GestoTheme.navyBlue
                          ),
                          textAlign: TextAlign.center
                      ),
                    ),
                    if (_currentPlan != null && _currentPlanExpiryDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          'Plan actuel: ${_currentPlan!.name[0].toUpperCase() + _currentPlan!.name.substring(1)} - Expire le ${_currentPlanExpiryDate!.day}/${_currentPlanExpiryDate!.month}/${_currentPlanExpiryDate!.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                    const SizedBox(height: 20),
                    if (_currentPlan != null && _currentPlan != PlanId.basic && _remainingDays > 0)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Note: En cas de mise à niveau, les jours restants de votre plan actuel seront ajoutés à votre nouveau plan.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 20),
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