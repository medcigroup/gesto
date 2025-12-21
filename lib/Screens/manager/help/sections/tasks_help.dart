import 'package:flutter/material.dart';
import '../help_models.dart';

/// ===============================
/// Widgets Modernes pour Gestion des Tâches
/// ===============================

class _TaskCategoryBadge extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _TaskCategoryBadge({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityIndicator extends StatelessWidget {
  final String level;
  final String description;
  final Color color;
  final IconData icon;

  const _PriorityIndicator({
    required this.level,
    required this.description,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  level,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskStatusChip extends StatelessWidget {
  final String status;
  final Color color;
  final IconData icon;

  const _TaskStatusChip({
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCreationStep extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _TaskCreationStep({
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
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

class _TaskExampleCard extends StatelessWidget {
  final String title;
  final String category;
  final String priority;
  final Color priorityColor;
  final String assignee;
  final String deadline;
  final String location;

  const _TaskExampleCard({
    required this.title,
    required this.category,
    required this.priority,
    required this.priorityColor,
    required this.assignee,
    required this.deadline,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.category_rounded, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(width: 24),
              Icon(Icons.person_rounded, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                assignee,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                location,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(width: 24),
              Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                deadline,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'À faire',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Créée il y a 2h',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _DashboardStatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
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
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// Tâches – Aide (Modernisé)
/// ===============================

HelpCategory getTasksHelp() {
  return HelpCategory(
    title: 'Tâches',
    icon: Icons.task_alt_rounded,
    sections: [
      /// Section 1 : Système de gestion des tâches
      HelpSection(
        title: 'Système de gestion des tâches',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le module de gestion des tâches permet de coordonner efficacement le travail de votre équipe. Assignez des tâches, suivez leur avancement et assurez-vous que rien n\'est oublié.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Statistiques du tableau de bord
            Text(
              'Tableau de bord des tâches :',
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
                childAspectRatio: 1.3,
              ),
              children: [
                _DashboardStatCard(
                  title: 'À faire',
                  count: 24,
                  color: Colors.blue,
                  icon: Icons.pending_actions_rounded,
                ),
                _DashboardStatCard(
                  title: 'En cours',
                  count: 12,
                  color: Colors.orange,
                  icon: Icons.hourglass_top_rounded,
                ),
                _DashboardStatCard(
                  title: 'Terminées',
                  count: 48,
                  color: Colors.green,
                  icon: Icons.check_circle_rounded,
                ),
                _DashboardStatCard(
                  title: 'Urgentes',
                  count: 5,
                  color: Colors.red,
                  icon: Icons.warning_rounded,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Catégories de tâches
            Text(
              'Catégories de tâches :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _TaskCategoryBadge(
                  title: 'Nettoyage chambres',
                  icon: Icons.cleaning_services_rounded,
                  color: Colors.blue,
                ),
                _TaskCategoryBadge(
                  title: 'Maintenance',
                  icon: Icons.build_rounded,
                  color: Colors.orange,
                ),
                _TaskCategoryBadge(
                  title: 'Service client',
                  icon: Icons.support_agent_rounded,
                  color: Colors.green,
                ),
                _TaskCategoryBadge(
                  title: 'Gestion du linge',
                  icon: Icons.local_laundry_service_rounded,
                  color: Colors.purple,
                ),
                _TaskCategoryBadge(
                  title: 'Contrôle qualité',
                  icon: Icons.verified_rounded,
                  color: Colors.teal,
                ),
                _TaskCategoryBadge(
                  title: 'Accueil et réception',
                  icon: Icons.desk_rounded,
                  color: Colors.indigo,
                ),
                _TaskCategoryBadge(
                  title: 'Cuisine et restaurant',
                  icon: Icons.restaurant_rounded,
                  color: Colors.red,
                ),
                _TaskCategoryBadge(
                  title: 'Gestion des stocks',
                  icon: Icons.inventory_2_rounded,
                  color: Colors.amber.shade700,
                ),
                _TaskCategoryBadge(
                  title: 'Administratif',
                  icon: Icons.work_rounded,
                  color: Colors.grey.shade700,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Priorités
            Text(
              'Niveaux de priorité :',
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
                childAspectRatio: 1.4,
              ),
              children: [
                _PriorityIndicator(
                  level: 'Urgente',
                  description: 'À traiter immédiatement\n(panne ascenseur, fuite d\'eau)',
                  color: Colors.red,
                  icon: Icons.warning_rounded,
                ),
                _PriorityIndicator(
                  level: 'Haute',
                  description: 'À traiter dans les 2-4 heures\n(chambre à préparer pour arrivée proche)',
                  color: Colors.orange,
                  icon: Icons.priority_high_rounded,
                ),
                _PriorityIndicator(
                  level: 'Moyenne',
                  description: 'À traiter dans la journée\n(réassort minibar)',
                  color: Colors.amber,
                  icon: Icons.schedule_rounded,
                ),
                _PriorityIndicator(
                  level: 'Basse',
                  description: 'À traiter quand possible\n(retouche peinture)',
                  color: Colors.green,
                  icon: Icons.low_priority_rounded,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Statuts des tâches
            Text(
              'Statuts des tâches :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _TaskStatusChip(
                  status: 'À faire',
                  color: Colors.blue,
                  icon: Icons.pending_actions_rounded,
                ),
                _TaskStatusChip(
                  status: 'En cours',
                  color: Colors.orange,
                  icon: Icons.hourglass_top_rounded,
                ),
                _TaskStatusChip(
                  status: 'Terminée',
                  color: Colors.green,
                  icon: Icons.check_circle_rounded,
                ),
                _TaskStatusChip(
                  status: 'Annulée',
                  color: Colors.grey,
                  icon: Icons.cancel_rounded,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Exemple de tâche
            Text(
              'Exemple de tâche :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _TaskExampleCard(
              title: 'Nettoyer et préparer la chambre 205 pour 15h',
              category: 'Nettoyage chambres',
              priority: 'Haute',
              priorityColor: Colors.orange,
              assignee: 'Marie Dupont',
              deadline: 'Aujourd\'hui, 15h00',
              location: 'Chambre 205',
            ),

            const SizedBox(height: 24),

            // Notification système
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Le système de notifications alerte automatiquement l\'employé assigné lorsqu\'une nouvelle tâche lui est attribuée.',
                      style: TextStyle(
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Accédez au menu "Tâches" pour voir toutes les tâches actives',
          'Le tableau de bord affiche les statistiques',
          'Utilisez les filtres pour voir seulement certaines tâches',
          'La vue liste affiche toutes les tâches avec leurs informations clés',
          'Les tâches urgentes apparaissent toujours en haut de la liste',
        ],
      ),

      /// Section 2 : Créer et assigner une tâche
      HelpSection(
        title: 'Créer et assigner une tâche',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La création d\'une tâche est simple et rapide. Le formulaire guidé vous assure de capturer toutes les informations nécessaires pour que l\'employé puisse exécuter la tâche correctement.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Informations à renseigner
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
                        'Informations à renseigner :',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 3,
                    ),
                    children: [
                      _InfoItem(icon: Icons.title_rounded, text: 'Titre descriptif'),
                      _InfoItem(icon: Icons.description_rounded, text: 'Description détaillée'),
                      _InfoItem(icon: Icons.category_rounded, text: 'Catégorie'),
                      _InfoItem(icon: Icons.priority_high_rounded, text: 'Niveau de priorité'),
                      _InfoItem(icon: Icons.person_rounded, text: 'Employé assigné'),
                      _InfoItem(icon: Icons.calendar_today_rounded, text: 'Date limite'),
                      _InfoItem(icon: Icons.location_on_rounded, text: 'Localisation'),
                      _InfoItem(icon: Icons.attach_file_rounded, text: 'Pièces jointes'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Étapes de création
            Text(
              'Étapes de création d\'une tâche :',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            Column(
              children: [
                _TaskCreationStep(
                  stepNumber: 1,
                  title: 'Accéder au formulaire',
                  description: 'Cliquez sur le bouton "+" ou "Nouvelle tâche"',
                  icon: Icons.add_circle_rounded,
                  color: Colors.blue,
                ),
                _TaskCreationStep(
                  stepNumber: 2,
                  title: 'Définir le titre et la description',
                  description: 'Saisissez un titre clair et une description précise avec toutes les instructions',
                  icon: Icons.title_rounded,
                  color: Colors.green,
                ),
                _TaskCreationStep(
                  stepNumber: 3,
                  title: 'Choisir la catégorie',
                  description: 'Sélectionnez la catégorie appropriée pour le classement',
                  icon: Icons.category_rounded,
                  color: Colors.orange,
                ),
                _TaskCreationStep(
                  stepNumber: 4,
                  title: 'Définir la priorité',
                  description: 'Sélectionnez le niveau de priorité réaliste selon l\'urgence',
                  icon: Icons.priority_high_rounded,
                  color: Colors.red,
                ),
                _TaskCreationStep(
                  stepNumber: 5,
                  title: 'Assigner à un employé',
                  description: 'Choisissez l\'employé compétent dans la liste déroulante',
                  icon: Icons.person_add_rounded,
                  color: Colors.purple,
                ),
                _TaskCreationStep(
                  stepNumber: 6,
                  title: 'Définir l\'échéance',
                  description: 'Définissez la date et l\'heure limite pour la réalisation',
                  icon: Icons.calendar_today_rounded,
                  color: Colors.teal,
                ),
                _TaskCreationStep(
                  stepNumber: 7,
                  title: 'Ajouter des détails',
                  description: 'Indiquez la localisation précise et ajoutez des photos ou documents',
                  icon: Icons.location_on_rounded,
                  color: Colors.indigo,
                ),
                _TaskCreationStep(
                  stepNumber: 8,
                  title: 'Créer et notifier',
                  description: 'Cliquez sur "Créer la tâche", l\'employé reçoit instantanément une notification',
                  icon: Icons.send_rounded,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Conseils pour une bonne création
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade50,
                    Colors.indigo.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        color: Colors.purple.shade700,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Conseils pour une création efficace :',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.purple.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Soyez précis dans le titre (ex: "Nettoyer chambre 205", "Réparer robinet chambre 310")\n'
                        '• Fournissez des instructions complètes pour éviter les allers-retours\n'
                        '• Assignez la tâche à la personne compétente selon son rôle\n'
                        '• Fixez des échéances réalistes\n'
                        '• Ajoutez des photos pour illustrer le problème\n'
                        '• Ne marquez pas tout en urgent - gardez cette priorité pour les véritables urgences',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Simulateur de formulaire
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  Text(
                    'Exemple de formulaire de création :',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FormField(label: 'Titre de la tâche', hint: 'Ex: Nettoyer chambre 205'),
                  const SizedBox(height: 16),
                  _FormField(
                    label: 'Description détaillée',
                    hint: 'Ex: Chambre checkout à 11h, nettoyage complet, réassort minibar...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _FormField(label: 'Catégorie', hint: 'Sélectionner...'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FormField(label: 'Priorité', hint: 'Sélectionner...'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _FormField(label: 'Assigné à', hint: 'Sélectionner...'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FormField(label: 'Date limite', hint: 'JJ/MM/AAAA HH:MM'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_task_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Créer la tâche'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Cliquez sur le bouton "+" ou "Nouvelle tâche"',
          'Remplissez le formulaire avec toutes les informations nécessaires',
          'Définissez un titre clair et une description précise',
          'Sélectionnez la catégorie et le niveau de priorité',
          'Choisissez l\'employé à assigner',
          'Définissez la date et l\'heure limite',
          'Indiquez la localisation précise',
          'Ajoutez des photos ou documents si nécessaire',
          'Cliquez sur "Créer la tâche"',
          'L\'employé reçoit instantanément une notification',
          'La tâche apparaît dans sa liste de tâches à faire',
        ],
      ),
    ],
  );
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.blue.shade800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final int maxLines;

  const _FormField({
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}