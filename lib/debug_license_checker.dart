import 'package:flutter/material.dart';
import 'LicenseFeatures.dart';

/// Widget de debug pour vérifier l'état de la licence et les pages accessibles
class LicenseDebugChecker extends StatelessWidget {
  final LicenseManager licenseManager;

  const LicenseDebugChecker({Key? key, required this.licenseManager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Toutes les pages de l'application
    final allPages = [
      'Tableau de bord',
      'Réservations',
      'Enregistrement',
      'Passages',
      'Départ',
      'Chambres',
      'Paiements',
      'Restaurant',
      'Boutique d\'options',
      'Tâches',
      'Emplois du temps',
      'Personnel',
      'Administration',
      'Finances',
      'Licences',
      'Support',
      'Support Admin',
      'Roadmap Admin',
      'Paramètres',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Licence & Accès'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations de licence
            Card(
              color: licenseManager.isExpired ? Colors.red.shade50 : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations de licence',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Type de licence', licenseManager.currentLicenseType.name.toUpperCase()),
                    _buildInfoRow(
                      'Date d\'expiration',
                      licenseManager.expiryDate?.toString() ?? 'Aucune',
                    ),
                    _buildInfoRow(
                      'Statut',
                      licenseManager.isExpired ? '❌ EXPIRÉE' : '✅ Active',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Liste des pages et leur accessibilité
            Text(
              'Pages et accessibilité',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            ...allPages.map((page) {
              final isAccessible = licenseManager.canAccessPage(page);
              final isPremium = licenseManager.isFeaturePremium(page);

              return Card(
                color: isAccessible ? Colors.green.shade50 : Colors.red.shade50,
                child: ListTile(
                  leading: Icon(
                    isAccessible ? Icons.check_circle : Icons.cancel,
                    color: isAccessible ? Colors.green : Colors.red,
                  ),
                  title: Text(page),
                  subtitle: Text(
                    isAccessible
                        ? 'Accessible'
                        : (isPremium ? 'Premium - Mise à niveau requise' : 'Non accessible'),
                  ),
                  trailing: isPremium
                      ? const Icon(Icons.star, color: Colors.amber)
                      : null,
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Détails par type de licence
            Text(
              'Pages disponibles par licence',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            ...LicenseType.values.map((licenseType) {
              final pages = LicenseFeatures.pageAccess[licenseType] ?? [];
              final isCurrent = licenseType == licenseManager.currentLicenseType;

              return Card(
                color: isCurrent ? Colors.blue.shade50 : null,
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Text(
                        licenseType.name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        const Chip(
                          label: Text('Actuelle', style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.blue,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text('${pages.length} pages disponibles'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: pages.map((page) {
                          return Chip(
                            label: Text(page, style: const TextStyle(fontSize: 11)),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
