import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:gesto/widgets/LoadingOverlay.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../config/routes.dart';
import '../../../../../config/AppConstants.dart';
import 'config/LicenceGenerator.dart';

enum PlanId { basic, starter, pro, entreprise }

enum PaymentMethod { cinetpay, stripe }

class Plan {
  final String title;
  final String? subtitle;
  final int? priceMonthly;
  final String currency;
  final String description;
  final List<String> features;
  final String planId;
  final Color color;
  final bool isPopular;
  final String buttonText;
  final String? badge;
  final bool isFree;

  Plan({
    required this.title,
    this.subtitle,
    this.priceMonthly,
    required this.currency,
    required this.description,
    required this.features,
    required this.planId,
    required this.color,
    this.isPopular = false,
    required this.buttonText,
    this.badge,
    this.isFree = false,
  });

  factory Plan.fromAppConstants(Map<String, dynamic> planData) {
    return Plan(
      title: planData['name'] as String,
      subtitle: planData['subtitle'] as String?,
      priceMonthly: planData['priceMonthly'] as int?,
      currency: planData['currency'] as String,
      description: planData['description'] as String,
      features: List<String>.from(planData['features'] as List),
      planId: planData['planId'] as String,
      color: planData['color'] as Color,
      isPopular: planData['isPopular'] as bool? ?? false,
      buttonText: planData['buttonText'] as String,
      badge: planData['badge'] as String?,
      isFree: planData['priceMonthly'] == null || (planData['priceMonthly'] as int?) == 0 || (planData['badge'] as String?)?.contains('GRATUIT') == true,
    );
  }

  PlanId get planIdEnum {
    switch (planId.toLowerCase()) {
      case 'basic':
        return PlanId.basic;
      case 'starter':
        return PlanId.starter;
      case 'pro':
        return PlanId.pro;
      case 'entreprise':
        return PlanId.entreprise;
      default:
        return PlanId.basic;
    }
  }

  String get formattedPrice {
    if (priceMonthly == null) {
      return 'Sur devis';
    }
    return '${priceMonthly!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
  }
}

class paiementplan extends StatefulWidget {
  const paiementplan({Key? key}) : super(key: key);

  @override
  State<paiementplan> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<paiementplan> {
  bool _isLoading = false;
  String? _selectedPlanId;
  String? _currentTransactionId;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> _selectPlan(Plan plan, {PaymentMethod? paymentMethod}) async {
    setState(() {
      _isLoading = true;
      _selectedPlanId = plan.planId;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté. Veuillez vous connecter pour choisir un plan.');
      }

      if (plan.isFree) {
        // Processus pour un plan gratuit
        await _processFreeSubscription(plan.planIdEnum);
      } else {
        // Processus pour un plan payant selon la méthode choisie
        if (paymentMethod == PaymentMethod.stripe) {
          await _processPaymentWithStripe(plan.planId);
        } else {
          // Par défaut ou si cinetpay explicitement choisi
          await _processPaymentWithCinetPay(plan.planId);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processFreeSubscription(PlanId planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Définir la durée de validité en jours et le type de licence en fonction du plan
    int durationDays = 30; // Durée par défaut
    String licenceType = planId.name; // Type de licence par défaut
    if (planId == PlanId.entreprise) {
      durationDays = 365;
    }

    // Générer la licence avec les dates et le type
    final licenceData = await LicenceGenerator.generateUniqueLicence(durationDays, licenceType, 'month');

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

    if (planId == PlanId.entreprise) {
      Navigator.pushReplacementNamed(context, AppRoutes.thankYou);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  Future<void> _processPaymentWithCinetPay(String planId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("L'utilisateur doit être connecté.");
      }

      // Récupère le token d'ID de l'utilisateur
      String? idToken = await user.getIdToken();

      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('initializePayment');

      // Inclure le token dans les données
      final result = await callable.call({
        'planId': planId,
        'idToken': idToken, // Passe l'ID token dans les données
      });

      if (result.data is! Map) {
        throw Exception("Réponse inattendue du serveur.");
      }

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true && data['paymentUrl'] != null) {
        _currentTransactionId = data['transactionId'];
        await _launchPaymentUrl(data['paymentUrl']);
        if (mounted) {
          _showPaymentConfirmationDialog(isStripe: false);
        }
      } else {
        throw Exception("Erreur lors de l'initialisation du paiement. Détails : ${data['message'] ?? 'Aucune description'}");
      }
    } catch (e) {
      print('❌ Erreur pendant le paiement CinetPay : $e');
      rethrow;
    }
  }

  Future<void> _processPaymentWithStripe(String planId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("L'utilisateur doit être connecté.");
      }

      // Récupération du token d'ID de l'utilisateur
      String? idToken = await user.getIdToken();

      // Appel de la Cloud Function pour initialiser le paiement Stripe
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('initializeStripePayment');

      final result = await callable.call({
        'planId': planId,
        'idToken': idToken,
      });

      if (result.data is! Map) {
        throw Exception("Réponse inattendue du serveur.");
      }

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true && data['paymentUrl'] != null) {
        _currentTransactionId = data['transactionId'];
        await _launchPaymentUrl(data['paymentUrl']);
        if (mounted) {
          _showPaymentConfirmationDialog(isStripe: true);
        }
      } else {
        throw Exception("Erreur lors de l'initialisation du paiement. Détails : ${data['message'] ?? 'Aucune description'}");
      }
    } catch (e) {
      print('❌ Erreur pendant le paiement Stripe : $e');
      rethrow;
    }
  }

  Future<void> _launchPaymentUrl(String paymentUrl) async {
    if (await canLaunch(paymentUrl)) {
      await launch(paymentUrl);
    } else {
      throw Exception('Impossible d\'ouvrir l\'URL de paiement');
    }
  }

  void _showErrorDialog(String errorMessage) {
    // Affiche un dialog d'erreur si l'utilisateur rencontre un problème
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Erreur de paiement'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentConfirmationDialog({required bool isStripe}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Paiement en cours ${isStripe ? 'via Stripe' : 'via CinetPay'}'),
        content: const Text(
            'Une fenêtre de paiement a été ouverte. Une fois votre paiement effectué, '
                'cliquez sur "J\'ai payé" pour vérifier le statut de votre transaction.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              isStripe ? _checkStripePaymentStatus() : _checkPaymentStatus();
            },
            child: const Text('J\'ai payé'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPaymentStatus() async {
    if (_currentTransactionId == null) return;

    setState(() => _isLoading = true);

    try {
      // Appeler la Cloud Function pour vérifier le statut du paiement
      final result = await _functions.httpsCallable('checkPaymentStatus').call({
        'transactionId': _currentTransactionId,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        if (data['status'] == 'completed') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement confirmé! Votre abonnement a été activé.'),
              backgroundColor: Colors.green,
            ),
          );

          // Rediriger vers le tableau de bord ou la page de remerciement
          if (data['planId'] == 'entreprise') {
            Navigator.pushReplacementNamed(context, AppRoutes.thankYou);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          }
        } else if (data['status'] == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Votre paiement est en cours de traitement. Veuillez réessayer dans quelques instants.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le paiement a échoué ou a été annulé. Veuillez réessayer.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkStripePaymentStatus() async {
    if (_currentTransactionId == null) return;

    setState(() => _isLoading = true);

    try {
      // Appeler la Cloud Function pour vérifier le statut du paiement
      final result = await _functions.httpsCallable('checkStripePaymentStatus').call({
        'transactionId': _currentTransactionId,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        if (data['status'] == 'completed') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement Stripe confirmé! Votre abonnement a été activé.'),
              backgroundColor: Colors.green,
            ),
          );

          // Rediriger vers le tableau de bord ou la page de remerciement
          if (data['planId'] == 'entreprise') {
            Navigator.pushReplacementNamed(context, AppRoutes.thankYou);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          }
        } else if (data['status'] == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Votre paiement Stripe est en cours de traitement. Veuillez réessayer dans quelques instants.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le paiement Stripe a échoué ou a été annulé. Veuillez réessayer.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Timestamp _getExpiryDate(PlanId planId) {
    final durations = {
      PlanId.basic: 30,
      PlanId.starter: 30,
      PlanId.pro: 30,
      PlanId.entreprise: 365,
    };
    final now = DateTime.now();
    return Timestamp.fromDate(now.add(Duration(days: durations[planId]!)));
  }

  void _showPaymentMethodDialog(Plan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
        title: Text(
          'Choisir le mode de paiement',
          style: AppConstants.getHeadlineFont(color: AppConstants.darkColor).copyWith(fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaymentMethodTile(
              icon: Icons.phone_android,
              color: AppConstants.secondaryColor,
              title: 'Mobile Money (CinetPay)',
              subtitle: 'Orange Money, MTN, Moov, Wave',
              onTap: () {
                Navigator.pop(context);
                _selectPlan(plan, paymentMethod: PaymentMethod.cinetpay);
              },
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodTile(
              icon: Icons.credit_card,
              color: AppConstants.blueAccent,
              title: 'Carte bancaire (Stripe)',
              subtitle: 'Visa, Mastercard, American Express',
              onTap: () {
                Navigator.pop(context);
                _selectPlan(plan, paymentMethod: PaymentMethod.stripe);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppConstants.getBodyFont(color: AppConstants.darkColor).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppConstants.getBodyFont(color: Colors.grey[600]).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Plan plan) {
    final isSelected = _selectedPlanId == plan.planId;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius)),
      elevation: 5,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          color: plan.isPopular ? plan.color.withValues(alpha: 0.1) : Colors.white,
          border: plan.isPopular ? Border.all(color: plan.color, width: 2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (plan.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: plan.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  plan.badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              plan.title,
              style: AppConstants.getHeadlineFont(color: AppConstants.darkColor).copyWith(fontSize: 24),
            ),
            if (plan.subtitle != null && plan.subtitle!.isNotEmpty)
              Text(
                plan.subtitle!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 10),
            Text(
              plan.formattedPrice,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: plan.color,
              ),
            ),
            if (plan.priceMonthly != null)
              Text(
                'par mois',
                style: AppConstants.getBodyFont(color: Colors.grey),
              ),
            const SizedBox(height: 5),
            Text(
              plan.description,
              style: AppConstants.getBodyFont(),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 30),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: plan.features.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle, color: plan.color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            plan.features[index],
                            style: AppConstants.getBodyFont().copyWith(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Bouton de choix de plan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: plan.isFree
                    ? () => _selectPlan(plan)
                    : () => _showPaymentMethodDialog(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? AppConstants.secondaryColor : plan.color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                  ),
                  elevation: isSelected ? 0 : 2,
                ),
                child: Text(
                  isSelected ? 'Plan actuel' : plan.buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser les plans depuis AppConstants, en excluant le plan "Grand Hôtel"
    final plans = AppConstants.pricingPlans
        .where((plan) => plan['planId'] != 'entreprise')
        .map((planData) => Plan.fromAppConstants(planData))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.pricingSectionTitle,
          style: AppConstants.getHeadlineFont(color: Colors.white).copyWith(fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Text(
                            AppConstants.pricingSectionSubtitle,
                            style: AppConstants.getHeadlineFont(color: AppConstants.darkColor).copyWith(fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sélectionnez la formule qui correspond à vos besoins',
                            style: AppConstants.getBodyFont(color: Colors.grey[600]).copyWith(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Layout responsive pour les cartes de plans
                    Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive layout based on screen width
                          if (constraints.maxWidth > 1200) {
                            // Pour les grands écrans, afficher tous les plans en ligne
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: plans.map((plan) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: SizedBox(
                                  width: 280, // Légèrement réduit pour tenir les plans
                                  height: MediaQuery.of(context).size.height * 0.7,
                                  child: _buildPlanCard(context, plan),
                                ),
                              )).toList(),
                            );
                          } else if (constraints.maxWidth > 800) {
                            // Pour les écrans moyens, afficher 2 plans par ligne
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: SizedBox(
                                        width: 300,
                                        height: MediaQuery.of(context).size.height * 0.7,
                                        child: _buildPlanCard(context, plans[0]),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: SizedBox(
                                        width: 300,
                                        height: MediaQuery.of(context).size.height * 0.7,
                                        child: _buildPlanCard(context, plans[1]),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: SizedBox(
                                        width: 300,
                                        height: MediaQuery.of(context).size.height * 0.7,
                                        child: _buildPlanCard(context, plans[2]),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          } else {
                            // Pour les petits écrans, empiler verticalement
                            return Column(
                              children: plans.map((plan) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: SizedBox(
                                  width: 300,
                                  height: MediaQuery.of(context).size.height * 0.6,
                                  child: _buildPlanCard(context, plan),
                                ),
                              )).toList(),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Information sur les modes de paiement
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 600),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                        gradient: LinearGradient(
                          colors: [
                            AppConstants.primaryColor.withValues(alpha: 0.1),
                            AppConstants.secondaryColor.withValues(alpha: 0.1),
                          ],
                        ),
                        border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Moyens de paiement acceptés',
                            style: AppConstants.getHeadlineFont(color: AppConstants.darkColor).copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPaymentMethodIcon(Icons.phone_android, 'Mobile Money', AppConstants.secondaryColor),
                              const SizedBox(width: 30),
                              _buildPaymentMethodIcon(Icons.credit_card, 'Carte Bancaire', AppConstants.blueAccent),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentMethodIcon(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppConstants.getBodyFont(color: AppConstants.darkColor).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}