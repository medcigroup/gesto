import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gesto/config/routes.dart';

class LicenseService {
  // Constantes de limites par type de licence
  static const Map<String, int> _licenceLimits = {
    'basic': 2,
    'starter': 5,
    'pro': 20,
  };

  // Vérifie si l'utilisateur peut créer un nouvel employé
  static Future<Map<String, dynamic>> canCreateEmployee(String userId) async {
    try {
      // Récupérer les infos de l'utilisateur
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return {
          'canCreate': false,
          'message': 'Profil utilisateur introuvable.',
          'licenceType': null,
          'currentCount': 0,
          'limit': 0
        };
      }

      // Récupérer le type de licence et le code entreprise
      final licenceType = userDoc.data()?['licenceType'] as String? ?? 'basic';
      final entrepriseCode = userDoc.data()?['entrepriseCode'] as String?;

      if (entrepriseCode == null || entrepriseCode.isEmpty) {
        return {
          'canCreate': false,
          'message': 'Code entreprise non configuré.',
          'licenceType': licenceType,
          'currentCount': 0,
          'limit': _getLicenceLimit(licenceType)
        };
      }

      // Compter le nombre d'employés actuels
      final querySnapshot = await FirebaseFirestore.instance
          .collection('staff')
          .where('entrepriseCode', isEqualTo: entrepriseCode)
          .get();

      final currentEmployeeCount = querySnapshot.docs.length;
      final licenceLimit = _getLicenceLimit(licenceType);

      // Vérifier si la limite est atteinte
      if (currentEmployeeCount >= licenceLimit) {
        return {
          'canCreate': false,
          'message': 'Limite de votre licence $licenceType atteinte ($licenceLimit employés maximum).',
          'licenceType': licenceType,
          'currentCount': currentEmployeeCount,
          'limit': licenceLimit
        };
      }

      // Peut créer un nouvel employé
      return {
        'canCreate': true,
        'message': 'Vous pouvez créer un nouvel employé.',
        'licenceType': licenceType,
        'currentCount': currentEmployeeCount,
        'limit': licenceLimit,
        'remaining': licenceLimit - currentEmployeeCount
      };
    } catch (e) {
      return {
        'canCreate': false,
        'message': 'Erreur lors de la vérification de licence: ${e.toString()}',
        'licenceType': null,
        'currentCount': 0,
        'limit': 0
      };
    }
  }

  // Récupère la limite d'employés selon le type de licence
  static int _getLicenceLimit(String licenceType) {
    return _licenceLimits[licenceType.toLowerCase()] ?? 2; // Par défaut: basic
  }

  // Affiche un dialogue d'information sur la limite de licence
  static void showLicenceInfoDialog(BuildContext context, Map<String, dynamic> licenceInfo) {
    final theme = Theme.of(context);
    final licenceType = licenceInfo['licenceType'] ?? 'basic';
    final currentCount = licenceInfo['currentCount'] ?? 0;
    final limit = licenceInfo['limit'] ?? 2;
    final canCreate = licenceInfo['canCreate'] ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          canCreate ? 'Informations licence' : 'Limite de licence atteinte',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: canCreate ? theme.colorScheme.primary : Colors.redAccent,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              licenceInfo['message'],
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildLicenceProgressBar(
              context: context,
              currentCount: currentCount,
              limit: limit,
              licenceType: licenceType,
            ),
            const SizedBox(height: 24),
            if (!canCreate) ...[
              Text(
                'Pour ajouter plus d\'employés, veuillez mettre à niveau votre licence.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
          if (!canCreate)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implémentez la navigation vers la page de mise à niveau
                Navigator.pushNamed(context, AppRoutes.chooseplanUpgrade);
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
              child: Text('Mettre à niveau'),
            ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 4,
      ),
    );
  }

  // Crée une barre de progression pour visualiser la limite de licence
  static Widget _buildLicenceProgressBar({
    required BuildContext context,
    required int currentCount,
    required int limit,
    required String licenceType,
  }) {
    final theme = Theme.of(context);
    final progress = currentCount / limit;
    final isNearLimit = progress >= 0.8;
    final isAtLimit = currentCount >= limit;

    // Couleur basée sur l'état
    Color progressColor = theme.colorScheme.primary;
    if (isAtLimit) {
      progressColor = Colors.red;
    } else if (isNearLimit) {
      progressColor = Colors.orange;
    }

    // Texte du type de licence
    String licenceText = 'Licence ${licenceType.toUpperCase()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              licenceText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$currentCount / $limit employés',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }
}