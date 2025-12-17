import 'package:flutter/material.dart';

class PricingCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final int monthlyPrice;
  final int? annualPrice;
  final int? savings;
  final List<String> features;
  final String currency;

  const PricingCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.monthlyPrice,
    this.annualPrice,
    this.savings,
    required this.features,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name.toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            Text('Mensuel: $monthlyPrice $currency',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (annualPrice != null && savings != null)
              Text('Annuel: $annualPrice $currency (Économisez $savings $currency)',
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...features.map((f) => Row(
              children: [
                const Icon(Icons.check, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text(f)),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
