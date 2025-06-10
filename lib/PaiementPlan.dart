import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:gesto/widgets/LoadingOverlay.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../config/routes.dart';
import '../../../../../config/theme.dart';
import 'config/LicenceGenerator.dart';

enum PlanId { basic, starter, pro, entreprise }

enum PaymentMethod { cinetpay, stripe }

class Plan {
  final String title;
  final String price;
  final String? oldPrice;
  final String duration;
  final List<String> features;
  final PlanId planId;
  final bool isRecommended;
  final bool isFree; // Ajouté pour différencier les plans gratuits et payants

  Plan({
    required this.title,
    required this.price,
    required this.duration,
    required this.features,
    required this.planId,
    required this.isRecommended,
    this.oldPrice,
    this.isFree = false, // Par défaut, considéré comme payant
  });
}

class paiementplan extends StatefulWidget {
  const paiementplan({Key? key}) : super(key: key);

  @override
  State<paiementplan> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<paiementplan> {
  bool _isLoading = false;
  PlanId? _selectedPlan;
  String? _currentTransactionId;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> _selectPlan(Plan plan, {PaymentMethod? paymentMethod}) async {
    setState(() {
      _isLoading = true;
      _selectedPlan = plan.planId;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté. Veuillez vous connecter pour choisir un plan.');
      }

      if (plan.isFree) {
        // Processus pour un plan gratuit
        await _processFreeSubscription(plan.planId);
      } else {
        // Processus pour un plan payant selon la méthode choisie
        if (paymentMethod == PaymentMethod.stripe) {
          await _processPaymentWithStripe(plan.planId.name);
        } else {
          // Par défaut ou si cinetpay explicitement choisi
          await _processPaymentWithCinetPay(plan.planId.name);
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
        title: const Text('Choisir le mode de paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.phone_android, color: GestoTheme.green),
              title: const Text('Mobile Money (CinetPay)'),
              onTap: () {
                Navigator.pop(context);
                _selectPlan(plan, paymentMethod: PaymentMethod.cinetpay);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.credit_card, color: Colors.blue),
              title: const Text('Carte bancaire (Stripe)'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (plan.oldPrice != null)
                  Text(
                    plan.oldPrice!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                const SizedBox(width: 5),
                Text(
                  plan.price,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (plan.duration.isNotEmpty)
              Text(plan.duration, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: plan.features.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.check, color: Colors.green, size: 18),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                              plan.features[index],
                              style: const TextStyle(fontSize: 14)
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bouton de choix de plan
            plan.isFree
                ? ElevatedButton(
              onPressed: () => _selectPlan(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.green : Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                  isSelected ? 'Plan actuel' : 'Choisir ce plan',
                  style: const TextStyle(color: Colors.white)
              ),
            )
                : ElevatedButton(
              onPressed: () => _showPaymentMethodDialog(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.green : Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                  isSelected ? 'Plan actuel' : 'Choisir ce plan',
                  style: const TextStyle(color: Colors.white)
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = [
      Plan(
        title: 'Basic (Essai Gratuit 30J)',
        price: '0 FCFA',
        oldPrice: '20000 FCFA',
        duration: '30 jours',
        features: [
          '14 chambres max',
          'Limite nombre employé : 3',
          'Support de base',
          'Rapports hebdo'
        ],
        planId: PlanId.basic,
        isRecommended: false,
        isFree: true, // Plan gratuit
      ),
      Plan(
        title: 'Starter',
        price: '30 000 FCFA',
        duration: 'par mois',
        features: [
          'Module de réservation',
          '20 chambres max',
          'Limite nombre employé : 10',
          'Support standard',
          'Rapports journaliers'
        ],
        planId: PlanId.starter,
        isRecommended: true,
        isFree: false, // Plan payant
      ),
      Plan(
        title: 'Pro',
        price: '50 000 FCFA',
        duration: 'par mois',
        features: [
          'Module de réservation',
          'Chambres illimitées',
          'Limite nombre employé : 20',
          'Gestion resto',
          'Tables resto illimitées',
          'Support 24/7',
          'Analyses temps réel',
          'Marketing tools',
        ],
        planId: PlanId.pro,
        isRecommended: false,
        isFree: false, // Plan payant
      ),
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
                      child: Text(
                          'Sélectionnez la formule qui correspond à vos besoins',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: GestoTheme.navyBlue
                          ),
                          textAlign: TextAlign.center
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
                      padding: const EdgeInsets.all(15),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[100],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Moyens de paiement acceptés',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPaymentMethodIcon(Icons.phone_android, 'Mobile Money'),
                              const SizedBox(width: 20),
                              _buildPaymentMethodIcon(Icons.credit_card, 'Carte Bancaire'),
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

  Widget _buildPaymentMethodIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: GestoTheme.green),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}