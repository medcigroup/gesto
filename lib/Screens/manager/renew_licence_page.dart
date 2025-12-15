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
      builder: (context) => AlertDialog(
        title: Text('Sélectionner une méthode de paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.credit_card),
              title: Text('Payer par carte bancaire'),
              subtitle: Text('Via Stripe'),
              onTap: () => Navigator.pop(context, 'stripe'),
            ),
            ListTile(
              leading: Icon(Icons.phone_android),
              title: Text('Payer par Mobile Money'),
              subtitle: Text('Via CinetPay'),
              onTap: () => Navigator.pop(context, 'cinetpay'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
        ],
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
      builder: (context) => AlertDialog(
        title: Text('Sélectionner une méthode de paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.credit_card),
              title: Text('Payer par carte bancaire'),
              subtitle: Text('Via Stripe'),
              onTap: () => Navigator.pop(context, 'stripe'),
            ),
            ListTile(
              leading: Icon(Icons.phone_android),
              title: Text('Payer par Mobile Money'),
              subtitle: Text('Via CinetPay'),
              onTap: () => Navigator.pop(context, 'cinetpay'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
        ],
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
          child: Text('Utilisateur non connecté'),
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
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print('[RENEW PAGE] ❌ Erreur stream: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Text('Erreur lors du chargement des données'),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Text('Données utilisateur introuvables'),
            ),
          );
        }

        // ✅ Convertir les données en UserModel
        final userModel = UserModel.fromJson(
            snapshot.data!.data() as Map<String, dynamic>
        );

        print('[RENEW PAGE] 📊 Données mises à jour: ${userModel.plan}, expiré: ${_isLicenceExpired(userModel)}');

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.primaryColor.withOpacity(0.1), Colors.white],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations de licence',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.verified_user,
                                      color: theme.primaryColor,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Type de licence',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          userModel.plan ?? 'N/A',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 40),
                              _buildInfoRow(
                                context,
                                title: 'Date de génération',
                                value: _formatDate(userModel.licenceGenerationDate),
                                icon: Icons.calendar_today,
                              ),
                              const SizedBox(height: 24),
                              _buildInfoRow(
                                context,
                                title: 'Date d\'expiration',
                                value: _formatDate(userModel.licenceExpiryDate),
                                icon: Icons.event_busy,
                                valueColor: _expiryColor(userModel),
                              ),
                              if (!_isLicenceExpired(userModel) && userModel.licenceExpiryDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 48, top: 8),
                                  child: Text(
                                    _daysUntilExpiry(userModel) > 0
                                        ? 'Expire dans ${_daysUntilExpiry(userModel)} jours'
                                        : 'Expire aujourd\'hui',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _expiryColor(userModel),
                                    ),
                                  ),
                                ),
                              if (_isLicenceExpired(userModel))
                                Padding(
                                  padding: const EdgeInsets.only(left: 48, top: 8),
                                  child: Text(
                                    'Licence expirée',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              _buildLicenceCodeRow(context, userModel),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Boutons d'action
                      Column(
                        children: [
                          // Bouton "Activer" et "Renouveler" côte à côte si licence non gratuite
                          if (_canRenewLicence(userModel))
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, AppRoutes.activatelicence);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                      minimumSize: const Size(double.infinity, 56),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.key, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text(
                                          'Activer une licence',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isProcessingPayment ? null : () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Renouveler la licence'),
                                          content: Text(
                                              'Êtes-vous sûr de vouloir renouveler votre licence ${userModel.plan} pour ${userModel.plan == "entreprise" ? "une année" : "un mois"} supplémentaire?'
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text('Annuler'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _showPaymentMethodSelector(userModel);
                                              },
                                              child: Text('Confirmer'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: theme.primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: theme.primaryColor,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                      minimumSize: const Size(double.infinity, 56),
                                    ),
                                    child: _isProcessingPayment
                                        ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        )
                                    )
                                        : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.refresh, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text(
                                          'Renouveler ma licence',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          if (_canRenewLicence(userModel))
                            const SizedBox(height: 16),

                          // Bouton "Mettre à niveau"
                          ElevatedButton(
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
                            style: ElevatedButton.styleFrom(
                              foregroundColor: _canRenewLicence(userModel) ? theme.primaryColor : Colors.white,
                              backgroundColor: _canRenewLicence(userModel) ? Colors.white : theme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: _canRenewLicence(userModel)
                                    ? BorderSide(color: theme.primaryColor, width: 2)
                                    : BorderSide.none,
                              ),
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 56),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upgrade),
                                const SizedBox(width: 12),
                                const Text(
                                  'Mettre à niveau ma licence',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
      },
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