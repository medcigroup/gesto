import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../config/LicenceGenerator.dart';
import '../config/UserModel.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../widgets/side_menu.dart';
import 'ActivateLicencePage.dart';

class RenewLicencePage extends StatefulWidget {
  const RenewLicencePage({Key? key}) : super(key: key);

  @override
  _RenewLicencePageState createState() => _RenewLicencePageState();
}

class _RenewLicencePageState extends State<RenewLicencePage> {
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        setState(() {
          _userModel = UserModel.fromJson(snapshot.data() as Map<String, dynamic>);
          _isLoading = false;
        });
      }
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

  Future<void> _renewLicence() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Déterminer la durée en fonction du plan actuel
      int durationDays = 30; // Par défaut, 1 an

      if (_userModel?.plan == 'basic') {
        durationDays = 30;
      } else if (_userModel?.plan == 'Starter') {
        durationDays = 30;
      } else if (_userModel?.plan == 'Pro') {
        durationDays = 30;
      } else if (_userModel?.plan == 'entreprise') {
        durationDays = 365;
      }

      // Générer une nouvelle licence
      final licenceData = await LicenceGenerator.generateUniqueLicence(
          durationDays,
          _userModel?.plan ?? 'gratuit'
      );

      // Récupérer l'utilisateur actuel
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Mettre à jour les informations de licence dans Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'licence': licenceData['code'],
        'licenceGenerationDate': licenceData['generationDate'],
        'licenceExpiryDate': licenceData['expiryDate'],
        // Ne pas mettre à jour le type de licence/plan ici car on renouvelle avec le même type
      });

      // Recharger les données utilisateur
      await _loadUserData();

      // Afficher un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre licence a été renouvelée avec succès'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Afficher une erreur en cas d'échec
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du renouvellement: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Méthode pour mettre à niveau la licence (à appeler après la sélection d'un nouveau plan)
  Future<void> _upgradeLicence(String newPlan) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Déterminer la durée en fonction du nouveau plan
      int durationDays = 30; // Par défaut, 1 an

      if (newPlan == 'basic') {
        durationDays = 30;
      } else if (newPlan == 'Starter') {
      } else if (newPlan == 'Pro') {
        durationDays = 30;
      } else if (newPlan == 'entreprise') {
        durationDays = 365;
      }

      // Générer une nouvelle licence
      final licenceData = await LicenceGenerator.generateUniqueLicence(
          durationDays,
          newPlan
      );

      // Récupérer l'utilisateur actuel
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Mettre à jour les informations de licence et le plan dans Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'licence': licenceData['code'],
        'licenceGenerationDate': licenceData['generationDate'],
        'licenceExpiryDate': licenceData['expiryDate'],
        'plan': newPlan, // Mettre à jour le plan car c'est une mise à niveau
      });

      // Recharger les données utilisateur
      await _loadUserData();

      // Afficher un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre licence a été mise à niveau avec succès'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Afficher une erreur en cas d'échec
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à niveau: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    final formattedText = _formatLicenceCode(text);
    Clipboard.setData(ClipboardData(text: formattedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code de licence copié'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool get _isLicenceExpired {
    if (_userModel?.licenceExpiryDate == null) return false;
    return _userModel!.licenceExpiryDate!.toDate().isBefore(DateTime.now());
  }

  int get _daysUntilExpiry {
    if (_userModel?.licenceExpiryDate == null) return 0;
    final now = DateTime.now();
    final expiry = _userModel!.licenceExpiryDate!.toDate();
    return expiry.difference(now).inDays;
  }

  Color get _expiryColor {
    if (_isLicenceExpired) return Colors.red;
    if (_daysUntilExpiry <= 30) return Colors.orange;
    return Colors.green;
  }

  bool get _canRenewLicence {
    // Vérifie si la licence n'est pas gratuite
    return _userModel?.plan != null && _userModel!.plan.toLowerCase() != 'gratuit';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Renouveler la licence'),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      drawer: const SideMenu(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
                                      _userModel?.plan ?? 'N/A',
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
                            value: _formatDate(_userModel?.licenceGenerationDate),
                            icon: Icons.calendar_today,
                          ),
                          const SizedBox(height: 24),
                          _buildInfoRow(
                            context,
                            title: 'Date d\'expiration',
                            value: _formatDate(_userModel?.licenceExpiryDate),
                            icon: Icons.event_busy,
                            valueColor: _expiryColor,
                          ),
                          if (!_isLicenceExpired && _userModel?.licenceExpiryDate != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 48, top: 8),
                              child: Text(
                                _daysUntilExpiry > 0
                                    ? 'Expire dans $_daysUntilExpiry jours'
                                    : 'Expire aujourd\'hui',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _expiryColor,
                                ),
                              ),
                            ),
                          if (_isLicenceExpired)
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
                          _buildLicenceCodeRow(context),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Boutons d'action
                  Column(
                    children: [
                      // Bouton "Renouveler ma licence" - visible seulement si non gratuite
                      if (_canRenewLicence)
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
                                    Icon(Icons.key,color: Colors.white,),
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
                            const SizedBox(width: 16), // Espace entre les boutons
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Afficher une boîte de dialogue de confirmation
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Renouveler la licence'),
                                      content: Text('Êtes-vous sûr de vouloir renouveler votre licence ${_userModel?.plan} pour un mois supplémentaire ?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _renewLicence(); // Appeler la méthode de renouvellement
                                          },
                                          child: Text('Renouveler ma licence'),
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.refresh,color: Colors.white),
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

                      // Espace entre les boutons si les deux sont visibles
                      if (_canRenewLicence)
                        const SizedBox(height: 16),

                      // Bouton "Mettre à niveau ma licence" - toujours visible
                      ElevatedButton(
                        onPressed: () async {
                          // Option 1: Naviguer vers la page de choix de plan et attendre le résultat
                          final result = await Navigator.pushNamed(
                            context,
                            AppRoutes.chooseplanUpgrade,
                            arguments: _userModel?.plan, // Passer le plan actuel pour référence
                          );

                          // Si un nouveau plan a été sélectionné
                          if (result != null && result is String && result != _userModel?.plan) {
                            _upgradeLicence(result); // Mettre à niveau avec le nouveau plan
                          }

                          // Option 2 (alternative) : Utiliser une boîte de dialogue simple
                          /*
                          // Liste des plans disponibles
                          final plans = ['Standard', 'Premium', 'Pro', 'Business'];
                          // Retirer le plan actuel de la liste
                          plans.remove(_userModel?.plan);

                          // Afficher une boîte de dialogue de sélection
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Choisir un nouveau plan'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: plans.map((plan) =>
                                  ListTile(
                                    title: Text(plan),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _upgradeLicence(plan);
                                    },
                                  )
                                ).toList(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Annuler'),
                                ),
                              ],
                            ),
                          );
                          */
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: _canRenewLicence ? theme.primaryColor : Colors.white,
                          backgroundColor: _canRenewLicence ? Colors.white : theme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: _canRenewLicence
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
  }

  Widget _buildLicenceCodeRow(BuildContext context) {
    final formattedLicence = _formatLicenceCode(_userModel?.licence);

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
                      onPressed: () => _copyToClipboard(_userModel?.licence ?? ''),
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

  Widget _buildInfoRow(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
        Color? valueColor,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  fontWeight: FontWeight.w500,
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