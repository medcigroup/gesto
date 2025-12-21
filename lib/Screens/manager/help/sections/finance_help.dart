import 'package:flutter/material.dart';
import '../help_models.dart';

/// ===============================
/// Widgets Modernes pour Finances
/// ===============================

class _FinancialKPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool isPositive;

  const _FinancialKPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend = '',
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (trend.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 14,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;

  const _ReportTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contient :',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportStepWidget extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _ReportStepWidget({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numéro d'étape
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Contenu
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChartWidget extends StatelessWidget {
  const _RevenueChartWidget();

  @override
  Widget build(BuildContext context) {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final values = [45000, 52000, 48000, 61000, 68000, 75000, 72000];
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Évolution des revenus (7 derniers jours)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                final value = values[index];
                final height = (value / maxValue) * 150;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 30,
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total hebdomadaire :',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                '425 000 FCFA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodWidget extends StatelessWidget {
  final String method;
  final double percentage;
  final Color color;

  const _PaymentMethodWidget({
    required this.method,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    method,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            color: color,
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// Finances – Aide (Modernisé)
/// ===============================

HelpCategory getFinanceHelp() {
  return HelpCategory(
    title: 'Finances',
    icon: Icons.analytics_rounded,
    sections: [
      /// Section 1 : Tableau de bord financier
      HelpSection(
        title: 'Tableau de bord financier',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le module Finances vous donne une vision complète de la santé financière de votre établissement avec des indicateurs en temps réel.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Grille des indicateurs KPI
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              children: [
                _FinancialKPICard(
                  title: 'Revenus du jour',
                  value: '85 500 FCFA',
                  icon: Icons.today_rounded,
                  color: Colors.green,
                  trend: '+12%',
                  isPositive: true,
                ),
                _FinancialKPICard(
                  title: 'Revenus du mois',
                  value: '2.4M FCFA',
                  icon: Icons.calendar_month_rounded,
                  color: Colors.blue,
                  trend: '+8%',
                  isPositive: true,
                ),
                _FinancialKPICard(
                  title: 'Taux de remplissage',
                  value: '78%',
                  icon: Icons.hotel_rounded,
                  color: Colors.orange,
                  trend: '+5%',
                  isPositive: true,
                ),
                _FinancialKPICard(
                  title: 'ADR moyen',
                  value: '35 000 FCFA',
                  icon: Icons.attach_money_rounded,
                  color: Colors.purple,
                  trend: '+3%',
                  isPositive: true,
                ),
                _FinancialKPICard(
                  title: 'RevPAR',
                  value: '27 300 FCFA',
                  icon: Icons.trending_up_rounded,
                  color: Colors.teal,
                  trend: '+7%',
                  isPositive: true,
                ),
                _FinancialKPICard(
                  title: 'Paiements en attente',
                  value: '120 000 FCFA',
                  icon: Icons.pending_actions_rounded,
                  color: Colors.amber,
                  trend: '',
                  isPositive: true,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Graphique des revenus
            const _RevenueChartWidget(),

            const SizedBox(height: 32),

            // Répartition des modes de paiement
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Répartition par mode de paiement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _PaymentMethodWidget(
                    method: 'Carte bancaire',
                    percentage: 45,
                    color: Colors.blue,
                  ),
                  const _PaymentMethodWidget(
                    method: 'Mobile Money',
                    percentage: 35,
                    color: Colors.green,
                  ),
                  const _PaymentMethodWidget(
                    method: 'Espèces',
                    percentage: 15,
                    color: Colors.orange,
                  ),
                  const _PaymentMethodWidget(
                    method: 'Virement',
                    percentage: 5,
                    color: Colors.purple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Définitions des indicateurs
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Définitions des indicateurs :',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• RevPAR : Revenu moyen par chambre disponible = Revenus totaux / Nombre total de chambres\n'
                        '• ADR : Prix moyen par chambre occupée = Revenus chambres / Nombre de chambres occupées\n'
                        '• Taux de remplissage : Pourcentage de chambres occupées (occupées / total chambres × 100)',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Accédez au menu "Finances" pour ouvrir le tableau de bord',
          'La page d\'accueil affiche les KPIs principaux en grandes cartes visuelles',
          'Consultez le graphique d\'évolution des revenus sur 7, 30 ou 90 jours',
          'Analysez la répartition des revenus par mode de paiement',
          'Visualisez la courbe de trésorerie (entrées vs sorties)',
          'Identifiez les jours/semaines les plus rentables',
          'Comparez les performances avec les périodes précédentes',
        ],
      ),

      /// Section 2 : Génération de rapports financiers
      HelpSection(
        title: 'Génération de rapports financiers',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Les rapports financiers sont des documents de synthèse indispensables pour la gestion, la comptabilité et les déclarations fiscales.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Types de rapports disponibles
            Text(
              'Types de rapports disponibles :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            Column(
              children: [
                _ReportTypeCard(
                  title: 'Rapport journalier (Z de caisse)',
                  description: 'Détail de toutes les transactions de la journée',
                  icon: Icons.summarize_rounded,
                  color: Colors.blue,
                  features: [
                    'Clôture de caisse quotidienne',
                    'Détail par mode de paiement',
                    'Solde de fin de journée',
                    'Relevé des transactions',
                  ],
                ),
                const SizedBox(height: 16),
                _ReportTypeCard(
                  title: 'Rapport hebdomadaire',
                  description: 'Synthèse des 7 derniers jours avec évolution',
                  icon: Icons.weekend_rounded,
                  color: Colors.green,
                  features: [
                    'Comparaison semaine précédente',
                    'Tendances jour par jour',
                    'Analyse des pics d\'activité',
                    'Recommandations hebdomadaires',
                  ],
                ),
                const SizedBox(height: 16),
                _ReportTypeCard(
                  title: 'Rapport mensuel',
                  description: 'Vue complète du mois avec répartition par source',
                  icon: Icons.calendar_month_rounded,
                  color: Colors.purple,
                  features: [
                    'Répartition par catégorie de revenus',
                    'Taux d\'occupation moyen',
                    'Chambres les plus rentables',
                    'Analyse comparative mensuelle',
                  ],
                ),
                const SizedBox(height: 16),
                _ReportTypeCard(
                  title: 'Rapport personnalisé',
                  description: 'Choisissez les dates et données à inclure',
                  icon: Icons.tune_rounded,
                  color: Colors.orange,
                  features: [
                    'Dates de début et fin personnalisées',
                    'Sélection des données à inclure',
                    'Filtres avancés',
                    'Exports multiples (PDF, Excel, CSV)',
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Étapes de génération
            Text(
              'Étapes de génération d\'un rapport :',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            Column(
              children: [
                _ReportStepWidget(
                  stepNumber: 1,
                  title: 'Accéder au générateur',
                  description: 'Dans le module Finances, cliquez sur "Générer un rapport"',
                  icon: Icons.play_arrow_rounded,
                  color: Colors.blue,
                ),
                _ReportStepWidget(
                  stepNumber: 2,
                  title: 'Choisir le type',
                  description: 'Sélectionnez le type de rapport dans la liste',
                  icon: Icons.list_rounded,
                  color: Colors.green,
                ),
                _ReportStepWidget(
                  stepNumber: 3,
                  title: 'Définir la période',
                  description: 'Sélectionnez la période : Aujourd\'hui, Cette semaine, Personnalisée...',
                  icon: Icons.calendar_today_rounded,
                  color: Colors.orange,
                ),
                _ReportStepWidget(
                  stepNumber: 4,
                  title: 'Sélectionner les données',
                  description: 'Cochez les sections à inclure : Revenus, Paiements, Statistiques, Graphiques',
                  icon: Icons.checklist_rounded,
                  color: Colors.purple,
                ),
                _ReportStepWidget(
                  stepNumber: 5,
                  title: 'Choisir le format',
                  description: 'Sélectionnez le format d\'export : PDF, Excel, CSV',
                  icon: Icons.download_rounded,
                  color: Colors.teal,
                ),
                _ReportStepWidget(
                  stepNumber: 6,
                  title: 'Générer et exporter',
                  description: 'Cliquez sur "Générer" et téléchargez ou imprimez le rapport',
                  icon: Icons.file_download_rounded,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Formats d'export
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formats d\'export disponibles :',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.picture_as_pdf_rounded,
                                color: Colors.red,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'PDF',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pour impression et archivage',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.table_chart_rounded,
                                color: Colors.green,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Excel',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pour analyse et traitement',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.table_view_rounded,
                                color: Colors.blue,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'CSV',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pour import dans d\'autres logiciels',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Note d'archivage
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.archive_rounded,
                    color: Colors.amber.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tous les rapports sont automatiquement archivés dans la section "Rapports enregistrés" pour consultation ultérieure.',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Dans le module Finances, cliquez sur "Générer un rapport"',
          'Choisissez le type de rapport souhaité',
          'Sélectionnez la période',
          'Cochez les sections à inclure',
          'Choisissez le format d\'export',
          'Cliquez sur "Générer le rapport"',
          'Le rapport s\'ouvre automatiquement',
          'Imprimez ou téléchargez le rapport',
        ],
      ),
    ],
  );
}