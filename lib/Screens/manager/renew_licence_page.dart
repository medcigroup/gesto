import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/LicenceGenerator.dart';
import '../../config/UserModel.dart';
import '../../config/routes.dart';


class RenewLicencePage extends StatefulWidget {
  const RenewLicencePage({Key? key}) : super(key: key);

  @override
  _RenewLicencePageState createState() => _RenewLicencePageState();
}

class _RenewLicencePageState extends State<RenewLicencePage> {
  bool _isProcessingPayment = false;
  Stream<DocumentSnapshot>? _userStream;

  @override
  void initState() {
    super.initState();
    _initializeUserStream();
  }

  // ✅ Initialiser le stream pour écouter les changements en temps réel
  void _initializeUserStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
      print('[RENEW PAGE] 🔄 Stream utilisateur initialisé');
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  String _formatLicenceCode(String? code) {
    if (code == null || code.isEmpty) return 'N/A';

    // Supprimer tous les caractères non alphanumériques
    final cleanCode = code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    // Si le code est trop court, retourner tel quel
    if (cleanCode.length < 16) return cleanCode;

    // Formater par groupe de 4 caractères
    final parts = <String>[];
    for (int i = 0; i < cleanCode.length; i += 4) {
      if (i + 4 <= cleanCode.length) {
        parts.add(cleanCode.substring(i, i + 4));
      } else {
        parts.add(cleanCode.substring(i));
      }
    }

    return parts.join('-');
  }

  // Fonction pour afficher le dialogue de sélection de méthode de paiement
  Future<void> _showPaymentMethodSelector(UserModel userModel) async {
    final selectedMethod = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.payment_rounded, color: Colors.blue.shade700, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Choisir une méthode de paiement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Option Stripe
              InkWell(
                onTap: () => Navigator.pop(context, 'stripe'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.credit_card_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Carte bancaire',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Paiement sécurisé via Stripe',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Option CinetPay
              InkWell(
                onTap: () => Navigator.pop(context, 'cinetpay'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.phone_android_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mobile Money',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Paiement via CinetPay',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedMethod != null) {
      if (selectedMethod == 'stripe') {
        await _processStripePayment('renew', userModel);
      } else if (selectedMethod == 'cinetpay') {
        await _processCinetPayPayment('renew', userModel);
      }
    }
  }

  // Fonction pour traiter le paiement via Stripe
  Future<void> _processStripePayment(String action, UserModel userModel, [String? newPlan]) async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Appeler la fonction d'initialisation du paiement Stripe
      final callable = FirebaseFunctions.instance.httpsCallable('initializeStripePayment');
      final result = await callable.call({
        'planId': action == 'upgrade' ? newPlan : userModel.plan,
      });

      if (result.data['success'] == true) {
        final paymentUrl = result.data['paymentUrl'];
        final transactionId = result.data['transactionId'];

        // Ouvrir l'URL de paiement
        if (await canLaunch(paymentUrl)) {
          await launch(paymentUrl);

          // Afficher une notification à l'utilisateur
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Redirection vers la page de paiement...'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.blue,
            ),
          );

          // Attendre quelques secondes avant de vérifier le statut
          await Future.delayed(const Duration(seconds: 5));

          // Définir un intervalle pour vérifier le statut
          bool paymentCompleted = false;
          int attempts = 0;

          while (!paymentCompleted && attempts < 10) {
            attempts++;

            try {
              final checkStatus = FirebaseFunctions.instance.httpsCallable('checkStripePaymentStatus');
              final statusResult = await checkStatus.call({
                'transactionId': transactionId
              });

              if (statusResult.data['status'] == 'completed') {
                paymentCompleted = true;

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(action == 'renew'
                          ? 'Votre licence a été renouvelée avec succès'
                          : 'Votre licence a été mise à niveau avec succès'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                    ),
                  );
                }

                break;
              }

              // Attendre avant de vérifier à nouveau
              await Future.delayed(const Duration(seconds: 3));
            } catch (e) {
              print('Erreur lors de la vérification du statut: $e');
            }
          }

          if (!paymentCompleted && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Veuillez vérifier votre email pour confirmer le statut de votre paiement'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 8),
              ),
            );
          }
        } else {
          throw Exception('Impossible d\'ouvrir l\'URL de paiement');
        }
      } else {
        throw Exception(result.data['message'] ?? 'Échec de l\'initialisation du paiement');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du paiement: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  // Fonction pour traiter le paiement via CinetPay
  Future<void> _processCinetPayPayment(String action, UserModel userModel, [String? newPlan]) async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Appeler la fonction d'initialisation du paiement CinetPay
      final callable = FirebaseFunctions.instance.httpsCallable('initializePayment');
      final result = await callable.call({
        'planId': action == 'upgrade' ? newPlan : userModel.plan,
      });

      if (result.data['success'] == true) {
        final paymentUrl = result.data['paymentUrl'];
        final transactionId = result.data['transactionId'];

        // Ouvrir l'URL de paiement
        if (await canLaunch(paymentUrl)) {
          await launch(paymentUrl);

          // Afficher une notification à l'utilisateur
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Redirection vers la page de paiement Mobile Money...'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.blue,
            ),
          );

          // Attendre quelques secondes avant de vérifier le statut
          await Future.delayed(const Duration(seconds: 5));

          // Définir un intervalle pour vérifier le statut
          bool paymentCompleted = false;
          int attempts = 0;

          while (!paymentCompleted && attempts < 10) {
            attempts++;

            try {
              final checkStatus = FirebaseFunctions.instance.httpsCallable('checkPaymentStatus');
              final statusResult = await checkStatus.call({
                'transactionId': transactionId
              });

              if (statusResult.data['status'] == 'completed') {
                paymentCompleted = true;

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(action == 'renew'
                          ? 'Votre licence a été renouvelée avec succès'
                          : 'Votre licence a été mise à niveau avec succès'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                    ),
                  );
                }

                break;
              }

              // Attendre avant de vérifier à nouveau
              await Future.delayed(const Duration(seconds: 3));
            } catch (e) {
              print('Erreur lors de la vérification du statut: $e');
            }
          }

          if (!paymentCompleted && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Veuillez vérifier votre téléphone pour confirmer le paiement Mobile Money'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 8),
              ),
            );
          }
        } else {
          throw Exception('Impossible d\'ouvrir l\'URL de paiement');
        }
      } else {
        throw Exception(result.data['message'] ?? 'Échec de l\'initialisation du paiement');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du paiement: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  // Fonction pour afficher le dialogue de sélection de méthode de paiement pour la mise à niveau
  Future<void> _showUpgradePaymentMethodSelector(String newPlan, UserModel userModel) async {
    final selectedMethod = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.payment_rounded, color: Colors.purple.shade700, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Choisir une méthode de paiement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Option Stripe
              InkWell(
                onTap: () => Navigator.pop(context, 'stripe'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.credit_card_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Carte bancaire',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Paiement sécurisé via Stripe',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Option CinetPay
              InkWell(
                onTap: () => Navigator.pop(context, 'cinetpay'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.phone_android_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mobile Money',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Paiement via CinetPay',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedMethod != null) {
      if (selectedMethod == 'stripe') {
        await _processStripePayment('upgrade', userModel, newPlan);
      } else if (selectedMethod == 'cinetpay') {
        await _processCinetPayPayment('upgrade', userModel, newPlan);
      }
    }
  }

  // Méthode pour mettre à niveau la licence (à appeler après la sélection d'un nouveau plan)
  Future<void> _upgradeLicence(String newPlan) async {
    try {
      // Déterminer la durée en fonction du nouveau plan
      int durationDays = 30; // Par défaut, 1 mois
      String durationType = 'month';

      if (newPlan == 'basic') {
        durationDays = 30;
      } else if (newPlan == 'Starter') {
        durationDays = 30;
      } else if (newPlan == 'Pro') {
        durationDays = 30;
      } else if (newPlan == 'entreprise') {
        durationDays = 365;
        durationType = 'year';
      }

      // Générer une nouvelle licence
      final licenceData = await LicenceGenerator.generateUniqueLicence(
          durationDays,
          newPlan,
          durationType
      );

      // Récupérer l'utilisateur actuel
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Mettre à jour les informations de licence et le plan dans Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'licence': licenceData['code'],
        'licenceGenerationDate': licenceData['generationDate'],
        'licenceExpiryDate': licenceData['expiryDate'],
        'plan': newPlan,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre licence a été mise à niveau avec succès'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à niveau: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code de licence copié'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _isLicenceExpired(UserModel? userModel) {
    if (userModel?.licenceExpiryDate == null) return false;
    return userModel!.licenceExpiryDate!.toDate().isBefore(DateTime.now());
  }

  int _daysUntilExpiry(UserModel? userModel) {
    if (userModel?.licenceExpiryDate == null) return 0;
    final now = DateTime.now();
    final expiry = userModel!.licenceExpiryDate!.toDate();
    return expiry.difference(now).inDays;
  }

  Color _expiryColor(UserModel? userModel) {
    if (_isLicenceExpired(userModel)) return Colors.red;
    if (_daysUntilExpiry(userModel) <= 30) return Colors.orange;
    return Colors.green;
  }

  bool _canRenewLicence(UserModel? userModel) {
    return userModel?.plan != null && userModel!.plan.toLowerCase() != 'gratuit';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Utilisateur non connecté',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Utiliser StreamBuilder pour écouter les changements en temps réel
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        // États de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 3),
                  const SizedBox(height: 24),
                  Text(
                    'Chargement...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          print('[RENEW PAGE] ❌ Erreur stream: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur lors du chargement des données',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Données utilisateur introuvables',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }

        // ✅ Convertir les données en UserModel
        final userModel = UserModel.fromJson(
            snapshot.data!.data() as Map<String, dynamic>
        );

        print('[RENEW PAGE] 📊 Données mises à jour: ${userModel.plan}, expiré: ${_isLicenceExpired(userModel)}');

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: theme.primaryColor,
            title: Text(
              'Ma Licence',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor.withOpacity(0.05),
                  Colors.purple.withOpacity(0.05),
                  Colors.blue.withOpacity(0.05),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Carte de licence principale avec design moderne
                      _buildLicenceCard(context, userModel, theme),
                      const SizedBox(height: 24),
                      
                      // Informations détaillées
                      _buildDetailsCard(context, userModel, theme),
                      const SizedBox(height: 32),

                      // Boutons d'action
                      _buildActionButtons(context, userModel, theme),
                      const SizedBox(height: 24),
                      
                      // Section d'aide
                      _buildHelpSection(context, theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLicenceCard(BuildContext context, UserModel userModel, ThemeData theme) {
    final isExpired = _isLicenceExpired(userModel);
    final daysLeft = _daysUntilExpiry(userModel);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isExpired
              ? [Colors.red.shade400, Colors.red.shade600]
              : [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isExpired ? Colors.red : theme.primaryColor).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Motif de fond décoratif
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'LICENCE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'EXPIRÉE',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (daysLeft <= 30)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text(
                              '$daysLeft jours',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Plan ${userModel.plan ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  userModel.licence != null 
                      ? _formatLicenceCode(userModel.licence)
                      : 'Aucune licence',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activation',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(userModel.licenceGenerationDate),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Expiration',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(userModel.licenceExpiryDate),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, UserModel userModel, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails de la licence',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          
          _buildDetailRow(
            icon: Icons.key_rounded,
            label: 'Code de licence',
            value: userModel.licence ?? 'N/A',
            showCopy: true,
            context: context,
          ),
          const Divider(height: 32),
          
          _buildDetailRow(
            icon: Icons.business_center,
            label: 'Type de plan',
            value: userModel.plan ?? 'Gratuit',
          ),
          const Divider(height: 32),
          
          _buildStatusIndicator(userModel),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool showCopy = false,
    BuildContext? context,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.grey[700], size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        if (showCopy && context != null)
          IconButton(
            icon: Icon(Icons.copy_rounded, size: 20),
            color: Colors.grey[600],
            onPressed: () => _copyToClipboard(value),
          ),
      ],
    );
  }

  Widget _buildStatusIndicator(UserModel userModel) {
    final isExpired = _isLicenceExpired(userModel);
    final daysLeft = _daysUntilExpiry(userModel);
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isExpired) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
      statusText = 'Licence expirée';
    } else if (daysLeft <= 7) {
      statusColor = Colors.red.shade400;
      statusIcon = Icons.warning_rounded;
      statusText = 'Expire dans $daysLeft jours';
    } else if (daysLeft <= 30) {
      statusColor = Colors.orange;
      statusIcon = Icons.watch_later_rounded;
      statusText = 'Expire dans $daysLeft jours';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Active ($daysLeft jours restants)';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserModel userModel, ThemeData theme) {
    return Column(
      children: [
        if (_canRenewLicence(userModel)) ...[
          // Bouton Renouveler
          _buildModernButton(
            context: context,
            label: 'Renouveler ma licence',
            icon: Icons.refresh_rounded,
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
            ),
            onPressed: _isProcessingPayment ? null : () {
              showDialog(
                context: context,
                builder: (context) => _buildModernDialog(
                  context: context,
                  title: 'Renouveler la licence',
                  content: 'Êtes-vous sûr de vouloir renouveler votre licence ${userModel.plan} pour ${userModel.plan == "entreprise" ? "une année" : "un mois"} supplémentaire?',
                  icon: Icons.refresh_rounded,
                  iconColor: theme.primaryColor,
                  onConfirm: () {
                    Navigator.pop(context);
                    _showPaymentMethodSelector(userModel);
                  },
                ),
              );
            },
            isLoading: _isProcessingPayment,
          ),
          const SizedBox(height: 16),
          
          // Bouton Mettre à niveau
          _buildModernButton(
            context: context,
            label: 'Mettre à niveau',
            icon: Icons.arrow_upward_rounded,
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
            ),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.chooseplanUpgrade,
                arguments: userModel.plan,
              );

              if (result != null && result is String && result != userModel.plan) {
                _showUpgradePaymentMethodSelector(result, userModel);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Bouton Activer licence
          _buildModernButton(
            context: context,
            label: 'Activer une licence',
            icon: Icons.vpn_key_rounded,
            isOutlined: true,
            color: Colors.green,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.activatelicence);
            },
          ),
        ] else ...[
          // Bouton Mettre à niveau (pour plan gratuit)
          _buildModernButton(
            context: context,
            label: 'Mettre à niveau ma licence',
            icon: Icons.arrow_upward_rounded,
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
            ),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.chooseplanUpgrade,
                arguments: userModel.plan,
              );

              if (result != null && result is String && result != userModel.plan) {
                _showUpgradePaymentMethodSelector(result, userModel);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildModernButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    Gradient? gradient,
    Color? color,
    bool isOutlined = false,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: !isOutlined ? gradient : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: !isOutlined ? [
          BoxShadow(
            color: (color ?? Colors.blue).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: isOutlined ? (color ?? Theme.of(context).primaryColor) : Colors.white,
          backgroundColor: isOutlined ? Colors.transparent : Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isOutlined 
                ? BorderSide(color: color ?? Theme.of(context).primaryColor, width: 2)
                : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Besoin d\'aide ?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Contactez notre support pour toute question',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDialog({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onConfirm,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text('Confirmer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenceCodeRow(BuildContext context, UserModel userModel) {
    final formattedLicence = _formatLicenceCode(userModel.licence);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.vpn_key,
          size: 24,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Code de licence',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: formattedLicence.split('-').map((block) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              block,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: Colors.grey[800],
                                fontFamily: 'Courier',
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      color: Theme.of(context).primaryColor,
                      onPressed: () => _copyToClipboard(userModel.licence ?? ''),
                      tooltip: 'Copier le code',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}