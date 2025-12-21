import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'LicenseFeatures.dart';
import 'config/AuthService.dart';
import 'debug_user_info.dart';
import 'debug_license_checker.dart';

/// Page de diagnostic complète pour identifier les problèmes d'affichage des pages
class DiagnosticCompletePage extends StatefulWidget {
  const DiagnosticCompletePage({Key? key}) : super(key: key);

  @override
  State<DiagnosticCompletePage> createState() => _DiagnosticCompletePageState();
}

class _DiagnosticCompletePageState extends State<DiagnosticCompletePage> {
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final role = await authService.getCurrentUserRole();
      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement rôle: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final licenseManager = Provider.of<LicenseManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Diagnostic Complet'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Résumé rapide
                _buildQuickSummary(licenseManager),

                const SizedBox(height: 24),

                // Pages attendues vs réelles
                _buildExpectedPages(licenseManager),

                const SizedBox(height: 24),

                // Boutons d'accès aux autres diagnostics
                _buildNavigationButtons(context, licenseManager),

                const SizedBox(height: 24),

                // Diagnostic détaillé
                _buildDetailedDiagnostic(licenseManager),
              ],
            ),
    );
  }

  Widget _buildQuickSummary(LicenseManager licenseManager) {
    return Card(
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé rapide',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildSummaryRow('Type de licence', licenseManager.currentLicenseType.name.toUpperCase()),
            _buildSummaryRow('Rôle utilisateur', _userRole?.toUpperCase() ?? 'CHARGEMENT...'),
            _buildSummaryRow(
              'Statut licence',
              licenseManager.isExpired ? '❌ EXPIRÉE' : '✅ Active',
            ),
            _buildSummaryRow(
              'Date d\'expiration',
              licenseManager.expiryDate?.toString() ?? 'Aucune',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExpectedPages(LicenseManager licenseManager) {
    // Pages qui devraient être visibles selon la licence
    final expectedPages = LicenseFeatures.pageAccess[licenseManager.currentLicenseType] ?? [];

    // Pages spécifiques à vérifier pour Pro + Manager
    final problematicPages = ['Restaurant', 'Tâches', 'Emplois du temps', 'Réservations'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pages attendues pour votre configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Licence: ${licenseManager.currentLicenseType.name.toUpperCase()} | Rôle: ${_userRole?.toUpperCase() ?? "N/A"}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const Divider(height: 24),

            // Vérifier chaque page problématique
            ...problematicPages.map((page) {
              final shouldBeVisible = expectedPages.contains(page) && !licenseManager.isExpired;
              final canAccess = licenseManager.canAccessPage(page);
              final isBlocked = shouldBeVisible && !canAccess;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isBlocked ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isBlocked ? Colors.red : Colors.green,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isBlocked ? Icons.error : Icons.check_circle,
                      color: isBlocked ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            page,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shouldBeVisible
                                ? (canAccess ? 'OK - Accessible' : '❌ BLOQUÉE (devrait être visible)')
                                : 'Non incluse dans cette licence',
                            style: TextStyle(
                              fontSize: 12,
                              color: isBlocked ? Colors.red.shade700 : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 16),
            Text(
              'Total pages attendues: ${expectedPages.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, LicenseManager licenseManager) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugUserInfo(),
                ),
              );
            },
            icon: const Icon(Icons.person),
            label: const Text('Voir données Firestore complètes'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LicenseDebugChecker(licenseManager: licenseManager),
                ),
              );
            },
            icon: const Icon(Icons.list),
            label: const Text('Voir toutes les pages et leur accessibilité'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedDiagnostic(LicenseManager licenseManager) {
    final List<Map<String, dynamic>> checks = [];

    // Vérification 1: Licence valide
    checks.add({
      'title': 'Licence configurée',
      'status': licenseManager.currentLicenseType != LicenseType.basic ||
                licenseManager.currentLicenseType == LicenseType.pro,
      'message': licenseManager.currentLicenseType == LicenseType.pro
          ? '✅ Licence Pro détectée'
          : '⚠️ Licence: ${licenseManager.currentLicenseType.name}',
    });

    // Vérification 2: Non expirée
    checks.add({
      'title': 'Licence active',
      'status': !licenseManager.isExpired,
      'message': licenseManager.isExpired
          ? '❌ Licence expirée - Seules 4 pages essentielles sont accessibles'
          : '✅ Licence active',
    });

    // Vérification 3: Rôle
    final isAdmin = _userRole?.toLowerCase() == 'superadmin';
    checks.add({
      'title': 'Rôle utilisateur',
      'status': _userRole != null,
      'message': _userRole != null
          ? (isAdmin
              ? '✅ SuperAdmin - Accès complet'
              : '✅ Rôle: $_userRole (accès selon licence)')
          : '❌ Rôle non défini',
    });

    // Vérification 4: Pages Pro accessibles
    final restaurantOk = licenseManager.canAccessPage('Restaurant');
    checks.add({
      'title': 'Restaurant (Pro+)',
      'status': restaurantOk,
      'message': restaurantOk
          ? '✅ Restaurant accessible'
          : '❌ Restaurant bloqué (devrait être accessible avec Pro)',
    });

    final reservationsOk = licenseManager.canAccessPage('Réservations');
    checks.add({
      'title': 'Réservations (Starter+)',
      'status': reservationsOk,
      'message': reservationsOk
          ? '✅ Réservations accessibles'
          : '❌ Réservations bloquées',
    });

    final tachesOk = licenseManager.canAccessPage('Tâches');
    checks.add({
      'title': 'Tâches (Starter+)',
      'status': tachesOk,
      'message': tachesOk
          ? '✅ Tâches accessibles'
          : '❌ Tâches bloquées',
    });

    final emploiOk = licenseManager.canAccessPage('Emplois du temps');
    checks.add({
      'title': 'Emplois du temps (Starter+)',
      'status': emploiOk,
      'message': emploiOk
          ? '✅ Emplois du temps accessibles'
          : '❌ Emplois du temps bloqués',
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vérifications détaillées',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...checks.map((check) => _buildCheckItem(
              check['title'],
              check['status'],
              check['message'],
            )),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Solution suggérée
            _buildSolution(licenseManager),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String title, bool status, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolution(LicenseManager licenseManager) {
    if (!licenseManager.isExpired &&
        licenseManager.currentLicenseType == LicenseType.pro &&
        !licenseManager.canAccessPage('Restaurant')) {
      // Problème identifié: Licence Pro mais pages non accessibles
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text(
                  'Solution suggérée',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Problème détecté: Vous avez une licence Pro mais certaines pages ne sont pas accessibles.\n\n'
              'Causes possibles:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('1. Le champ "licenceType" dans Firestore n\'est pas exactement "pro" (vérifier la casse)'),
            const Text('2. Le Provider LicenseManager n\'a pas été rechargé'),
            const Text('3. Cache de l\'application non actualisé'),
            const SizedBox(height: 12),
            const Text(
              'Actions à faire:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await licenseManager.loadLicenseInfo();
                setState(() {});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Licence rechargée ! Vérifiez à nouveau.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Recharger la licence depuis Firestore'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tout semble correct ! Si le problème persiste, vérifiez les données Firestore.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
