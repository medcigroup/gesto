import 'package:flutter/material.dart';
import '../help_models.dart';

/// ===============================
/// Widgets Modernes pour Tableau de bord
/// ===============================

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _KPICard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
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
                      change,
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String description;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final String status;
  final Color statusColor;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceChart extends StatelessWidget {
  final String title;
  final List<double> data;
  final Color color;
  final bool isRevenue;

  const _PerformanceChart({
    required this.title,
    required this.data,
    required this.color,
    this.isRevenue = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '7 derniers jours',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                final value = data[index];
                final height = (value / maxValue) * 100;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: isRevenue ? '${value.toInt()} FCFA' : '${value.toInt()}%',
                        child: Container(
                          width: 30,
                          height: height,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color,
                                color.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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
                'Performance moyenne :',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                isRevenue ? '${(data.reduce((a, b) => a + b) / data.length).toInt()} FCFA/jour' : '${(data.reduce((a, b) => a + b) / data.length).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatisticTip extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _StatisticTip({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
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
}

class _HeaderWidget extends StatelessWidget {
  const _HeaderWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade600,
            Colors.indigo.shade600,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour, Directeur',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aperçu de votre activité en temps réel',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 8),
              Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Activité normale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// Tableau de bord – Aide (Modernisé)
/// ===============================

HelpCategory getDashboardHelp() {
  return HelpCategory(
    title: 'Tableau de bord',
    icon: Icons.dashboard_rounded,
    sections: [
      /// Section 1 : Comprendre le tableau de bord
      HelpSection(
        title: 'Comprendre le tableau de bord',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeaderWidget(),
            const SizedBox(height: 24),

            Text(
              'Le tableau de bord est votre centre de contrôle principal. Il vous donne une vision complète de l\'activité de votre établissement en temps réel.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Indicateurs principaux
            Text(
              'Indicateurs clés de performance (KPI) :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              children: [
                _KPICard(
                  title: 'Taux d\'occupation',
                  value: '78%',
                  change: '+12%',
                  isPositive: true,
                  icon: Icons.hotel_rounded,
                  color: Colors.blue,
                  subtitle: '12 chambres sur 16 occupées',
                ),
                _KPICard(
                  title: 'Revenus du jour',
                  value: '85 500 FCFA',
                  change: '+8%',
                  isPositive: true,
                  icon: Icons.attach_money_rounded,
                  color: Colors.green,
                  subtitle: 'Depuis minuit',
                ),
                _KPICard(
                  title: 'RevPAR',
                  value: '27 300 FCFA',
                  change: '+5%',
                  isPositive: true,
                  icon: Icons.trending_up_rounded,
                  color: Colors.purple,
                  subtitle: 'Revenu par chambre disponible',
                ),
                _KPICard(
                  title: 'ADR moyen',
                  value: '35 000 FCFA',
                  change: '+3%',
                  isPositive: true,
                  icon: Icons.currency_exchange_rounded,
                  color: Colors.orange,
                  subtitle: 'Prix moyen par chambre occupée',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Graphiques de performance
            Text(
              'Graphiques de performance :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            Column(
              children: [
                _PerformanceChart(
                  title: 'Évolution du taux d\'occupation',
                  data: [65, 70, 68, 75, 78, 82, 78],
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _PerformanceChart(
                  title: 'Évolution des revenus',
                  data: [45000, 52000, 48000, 61000, 68000, 75000, 72000],
                  color: Colors.green,
                  isRevenue: true,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Activités récentes
            Text(
              'Activités récentes :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.list_rounded, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Réservations récentes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Voir tout',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ActivityItem(
                    icon: Icons.hotel_rounded,
                    iconColor: Colors.green,
                    title: 'Chambre 205 - Check-in',
                    subtitle: 'M. Dupont - 2 personnes - 3 nuits',
                    time: '10:30',
                    status: 'Confirmée',
                    statusColor: Colors.green,
                  ),
                  const _ActivityItem(
                    icon: Icons.hotel_rounded,
                    iconColor: Colors.orange,
                    title: 'Chambre 312 - Réservation',
                    subtitle: 'Mme Martin - Suite - 2 nuits',
                    time: '09:45',
                    status: 'En attente',
                    statusColor: Colors.orange,
                  ),
                  const _ActivityItem(
                    icon: Icons.hotel_rounded,
                    iconColor: Colors.red,
                    title: 'Chambre 108 - Annulation',
                    subtitle: 'M. Johnson - 1 nuit',
                    time: 'Hier',
                    status: 'Annulée',
                    statusColor: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.task_alt_rounded, color: Colors.purple.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Tâches en cours',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Voir tout',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ActivityItem(
                    icon: Icons.cleaning_services_rounded,
                    iconColor: Colors.blue,
                    title: 'Nettoyer chambre 205',
                    subtitle: 'Assignée à Marie Dupont',
                    time: 'À faire',
                    status: 'Haute priorité',
                    statusColor: Colors.red,
                  ),
                  const _ActivityItem(
                    icon: Icons.build_rounded,
                    iconColor: Colors.orange,
                    title: 'Réparer robinet 310',
                    subtitle: 'Assignée à Jean Martin',
                    time: 'En cours',
                    status: 'Moyenne priorité',
                    statusColor: Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Consultez le taux d\'occupation en temps réel',
          'Visualisez les revenus du jour',
          'Analysez les graphiques de performance',
          'Suivez les réservations récentes',
          'Consultez les tâches en cours',
        ],
      ),

      /// Section 2 : Actions rapides
      HelpSection(
        title: 'Actions rapides depuis le tableau de bord',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Les boutons d\'actions rapides vous permettent d\'accéder instantanément aux fonctions les plus utilisées, sans naviguer dans les menus.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              children: [
                _QuickActionButton(
                  label: 'Nouvelle réservation',
                  icon: Icons.book_online_rounded,
                  color: Colors.blue,
                  description: 'Assistant en 4 étapes\n(dates, chambre, client, paiement)',
                ),
                _QuickActionButton(
                  label: 'Enregistrement',
                  icon: Icons.login_rounded,
                  color: Colors.green,
                  description: 'Check-in pour nouveaux clients\nIdéal pour les walk-in',
                ),
                _QuickActionButton(
                  label: 'Départ',
                  icon: Icons.logout_rounded,
                  color: Colors.orange,
                  description: 'Traitement des check-out\nLibération des chambres',
                ),
                _QuickActionButton(
                  label: 'Nouvelle tâche',
                  icon: Icons.add_task_rounded,
                  color: Colors.purple,
                  description: 'Créer et assigner rapidement\nNettoyage, maintenance, service',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Exemple de workflow
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade50,
                    Colors.indigo.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timeline_rounded, color: Colors.blue.shade700, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Workflow optimisé :',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(Icons.person_add_rounded, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text('Client arrive', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Icon(Icons.arrow_forward_rounded, color: Colors.grey.shade400),
                      Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(Icons.login_rounded, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text('Enregistrement', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Icon(Icons.arrow_forward_rounded, color: Colors.grey.shade400),
                      Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(Icons.task_alt_rounded, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text('Tâches', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Icon(Icons.arrow_forward_rounded, color: Colors.grey.shade400),
                      Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(Icons.logout_rounded, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text('Départ', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Nouvelle réservation : Ouvre directement le formulaire de création de réservation',
          'Enregistrement : Lance le processus de check-in pour accueillir un nouveau client',
          'Départ : Accédez à la liste des chambres occupées pour traiter les check-out',
          'Nouvelle tâche : Créez et assignez rapidement une tâche à un membre du personnel',
        ],
      ),

      /// Section 3 : Interpréter les statistiques
      HelpSection(
        title: 'Interpréter les statistiques',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comprendre vos statistiques vous aide à prendre de meilleures décisions stratégiques. Voici comment interpréter les principaux indicateurs :',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Conseils d'interprétation
            Column(
              children: [
                _StatisticTip(
                  title: 'Taux d\'occupation optimal',
                  content: 'Visez entre 70% et 90% en haute saison. Un taux trop élevé peut indiquer un manque de chambres disponibles, un taux trop bas peut suggérer un problème de marketing ou de prix.',
                  icon: Icons.sports_score,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _StatisticTip(
                  title: 'Revenus par chambre (RevPAR)',
                  content: 'Divisez le revenu total par le nombre de chambres disponibles. Cet indicateur mesure votre efficacité commerciale et votre capacité à maximiser vos revenus.',
                  icon: Icons.analytics_rounded,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _StatisticTip(
                  title: 'Tendances hebdomadaires',
                  content: 'Identifiez les jours de forte et faible affluence pour ajuster vos prix et votre personnel. Les week-ends sont généralement plus chargés.',
                  icon: Icons.timeline_rounded,
                  color: Colors.purple,
                ),
                const SizedBox(height: 16),
                _StatisticTip(
                  title: 'ADR (Average Daily Rate)',
                  content: 'Le prix moyen par chambre occupée. Comparez-le avec la concurrence pour ajuster votre stratégie tarifaire.',
                  icon: Icons.currency_exchange_rounded,
                  color: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Échelle de performance
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Échelle de performance :',
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
                        child: Column(
                          children: [
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '< 50%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                            Text(
                              'Faible',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 30,
                              color: Colors.orange.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '50-70%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            Text(
                              'Moyen',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 40,
                              color: Colors.green.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '70-90%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              'Bon',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '> 90%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade800,
                              ),
                            ),
                            Text(
                              'Excellent',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
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
                  Text(
                    'Votre performance actuelle : 78% (Bon)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Checklist de vérification
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.checklist_rounded, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      Text(
                        'Checklist d\'analyse quotidienne :',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _ChecklistItem(text: 'Vérifier les tendances de variation (+12%, +15%)'),
                      _ChecklistItem(text: 'Comparer les performances quotidiennes'),
                      _ChecklistItem(text: 'Analyser les patterns hebdomadaires'),
                      _ChecklistItem(text: 'Planifier les promotions en fonction des données'),
                      _ChecklistItem(text: 'Ajuster les tarifs dynamiquement'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Graphique comparatif
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparaison mensuelle :',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Mois dernier',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '66%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Ce mois-ci',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '78%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Objectif',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.green.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '85%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('+18% par rapport au mois dernier'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Vérifiez les tendances de variation (+12%, +15%) qui indiquent la croissance ou la baisse',
          'Comparez vos performances quotidiennes, hebdomadaires et mensuelles',
          'Identifiez des patterns pour planifier efficacement',
          'Utilisez ces données pour planifier les promotions',
          'Ajustez vos tarifs dynamiquement en fonction des tendances',
        ],
      ),
    ],
  );
}

class _ChecklistItem extends StatelessWidget {
  final String text;

  const _ChecklistItem({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              text,
              style: TextStyle(
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}