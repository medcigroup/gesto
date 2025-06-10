import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../LicenseFeatures.dart';


class LicenseExpiredDialog extends StatelessWidget {
  final DateTime? expiryDate;
  final LicenseType licenseType;

  const LicenseExpiredDialog({
    Key? key,
    required this.expiryDate,
    required this.licenseType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF3F51B5); // Indigo

    String licenseTypeString = '';
    switch (licenseType) {
      case LicenseType.basic:
        licenseTypeString = 'Basic';
        break;
      case LicenseType.starter:
        licenseTypeString = 'Starter';
        break;
      case LicenseType.pro:
        licenseTypeString = 'Pro';
        break;
      case LicenseType.entreprise:
        licenseTypeString = 'Entreprise';
        break;
    }

    String formattedDate = expiryDate != null
        ? '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
        : 'inconnue';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 28,
          ),
          SizedBox(width: 10),
          Text(
            'Licence expirée',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Votre licence $licenseTypeString a expiré le $formattedDate.',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Certaines fonctionnalités sont désormais limitées. Pour continuer à utiliser toutes les fonctionnalités de Gesto, veuillez renouveler votre licence.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fonctionnalités disponibles :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text('• Tableau de bord (accès limité)'),
                Text('• Gestion des licences'),
                Text('• Paramètres'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text(
            'Fermer',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Renouveler ma licence'),
          onPressed: () {
            Navigator.of(context).pop();
            // Rediriger vers la page de renouvellement de licence
            Navigator.of(context).pushNamed('/renewlicencePage');
          },
        ),
      ],
    );
  }
}

class PremiumFeatureBadge extends StatelessWidget {
  final String featureName;

  const PremiumFeatureBadge({
    Key? key,
    required this.featureName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final licenseManager = Provider.of<LicenseManager>(context, listen: false);
    final requiredLicense = licenseManager.getRequiredLicenseNameForFeature(featureName);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        requiredLicense,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class LicenseInfoWidget extends StatelessWidget {
  const LicenseInfoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final licenseManager = Provider.of<LicenseManager>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpired = licenseManager.isExpired;

    String licenseTypeText = '';
    Color statusColor;

    switch (licenseManager.currentLicenseType) {
      case LicenseType.basic:
        licenseTypeText = 'Basic';
        break;
      case LicenseType.starter:
        licenseTypeText = 'Starter';
        break;
      case LicenseType.pro:
        licenseTypeText = 'Pro';
        break;
      case LicenseType.entreprise:
        licenseTypeText = 'Entreprise';
        break;
    }

    statusColor = isExpired ? Colors.red : Colors.green;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpired ? Icons.error_outline : Icons.verified_outlined,
                color: statusColor,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Licence $licenseTypeText',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  isExpired ? 'Expirée' : 'Active',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Date d\'expiration: ',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
              Text(
                licenseManager.expiryDate != null
                    ? '${licenseManager.expiryDate!.day}/${licenseManager.expiryDate!.month}/${licenseManager.expiryDate!.year}'
                    : 'Non spécifiée',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}