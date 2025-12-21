import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Widget pour afficher toutes les informations utilisateur depuis Firestore
class DebugUserInfo extends StatelessWidget {
  const DebugUserInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debug - Info Utilisateur')),
        body: const Center(child: Text('Aucun utilisateur connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Info Utilisateur'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Document utilisateur introuvable dans Firestore'),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations Firebase Auth
                _buildSection(
                  context,
                  'Firebase Authentication',
                  [
                    _buildInfoRow('UID', currentUser.uid),
                    _buildInfoRow('Email', currentUser.email ?? 'N/A'),
                    _buildInfoRow('Email vérifié', currentUser.emailVerified ? '✅ Oui' : '❌ Non'),
                  ],
                ),

                const SizedBox(height: 24),

                // Informations de licence
                _buildSection(
                  context,
                  'Licence',
                  [
                    _buildInfoRow(
                      'Type de licence',
                      userData['licenceType']?.toString() ?? '❌ NON DÉFINI',
                      highlight: userData['licenceType'] == null,
                    ),
                    _buildInfoRow(
                      'Date d\'expiration',
                      _formatTimestamp(userData['licenceExpiryDate']),
                    ),
                    _buildInfoRow(
                      'Statut',
                      _getLicenseStatus(userData['licenceExpiryDate']),
                      highlight: _isExpired(userData['licenceExpiryDate']),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Informations de rôle
                _buildSection(
                  context,
                  'Rôle & Permissions',
                  [
                    _buildInfoRow(
                      'Rôle',
                      userData['role']?.toString() ?? '❌ NON DÉFINI',
                      highlight: userData['role'] == null,
                    ),
                    _buildInfoRow('Nom', userData['name']?.toString() ?? 'N/A'),
                    _buildInfoRow('Prénom', userData['prenom']?.toString() ?? 'N/A'),
                  ],
                ),

                const SizedBox(height: 24),

                // Toutes les données brutes
                _buildSection(
                  context,
                  'Données Firestore complètes (RAW)',
                  [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        _formatJson(userData),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Diagnostic des problèmes
                _buildDiagnostic(context, userData),

                const SizedBox(height: 24),

                // Bouton pour corriger
                if (userData['licenceType'] == null || userData['role'] == null)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _fixUserData(context, currentUser.uid),
                      icon: const Icon(Icons.build),
                      label: const Text('Corriger les données manquantes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: highlight ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnostic(BuildContext context, Map<String, dynamic> userData) {
    final List<String> issues = [];
    final List<String> warnings = [];

    // Vérifier la licence
    if (userData['licenceType'] == null) {
      issues.add('❌ CRITIQUE: Type de licence non défini');
    } else {
      final licenceType = userData['licenceType'].toString().toLowerCase();
      if (!['basic', 'starter', 'pro', 'entreprise'].contains(licenceType)) {
        warnings.add('⚠️ Type de licence invalide: "$licenceType"');
      }
    }

    // Vérifier le rôle
    if (userData['role'] == null) {
      issues.add('❌ CRITIQUE: Rôle non défini');
    } else {
      final role = userData['role'].toString().toLowerCase();
      if (!['superadmin', 'manager', 'receptionist', 'employee', 'kitchen'].contains(role)) {
        warnings.add('⚠️ Rôle invalide: "$role"');
      }
    }

    // Vérifier l'expiration
    if (_isExpired(userData['licenceExpiryDate'])) {
      warnings.add('⚠️ Licence expirée - accès limité aux pages essentielles');
    }

    if (issues.isEmpty && warnings.isEmpty) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tout est OK !',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configuration correcte. Si vous ne voyez pas certaines pages, vérifiez le DashboardManager.',
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: issues.isNotEmpty ? Colors.red.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  issues.isNotEmpty ? Icons.error : Icons.warning,
                  color: issues.isNotEmpty ? Colors.red : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Text(
                  issues.isNotEmpty ? 'Problèmes détectés' : 'Avertissements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: issues.isNotEmpty ? Colors.red : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...issues.map((issue) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(issue, style: const TextStyle(color: Colors.red)),
                )),
            ...warnings.map((warning) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(warning, style: const TextStyle(color: Colors.orange)),
                )),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Aucune';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute}';
    }
    return timestamp.toString();
  }

  String _getLicenseStatus(dynamic timestamp) {
    if (timestamp == null) return '✅ Pas d\'expiration';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      if (now.isAfter(date)) {
        return '❌ EXPIRÉE';
      } else {
        final daysLeft = date.difference(now).inDays;
        return '✅ Active ($daysLeft jours restants)';
      }
    }
    return 'Inconnu';
  }

  bool _isExpired(dynamic timestamp) {
    if (timestamp == null) return false;
    if (timestamp is Timestamp) {
      return DateTime.now().isAfter(timestamp.toDate());
    }
    return false;
  }

  String _formatJson(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    data.forEach((key, value) {
      if (value is Timestamp) {
        buffer.writeln('$key: ${value.toDate()}');
      } else {
        buffer.writeln('$key: $value');
      }
    });
    return buffer.toString();
  }

  Future<void> _fixUserData(BuildContext context, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Corriger les données'),
        content: const Text(
          'Voulez-vous définir les valeurs par défaut ?\n\n'
          '• Licence: pro\n'
          '• Rôle: manager\n'
          '• Expiration: +1 an',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Corriger'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'licenceType': 'pro',
        'role': 'manager',
        'licenceExpiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 365)),
        ),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Données corrigées ! Redémarrez l\'application.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
