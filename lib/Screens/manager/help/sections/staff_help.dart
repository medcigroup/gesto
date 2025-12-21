import 'package:flutter/material.dart';
import '../help_models.dart';

/// ===============================
/// Widgets Modernes pour Gestion du Personnel
/// ===============================

class _DepartmentBadge extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _DepartmentBadge({
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

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmployeeInfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEmployeeStep extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _AddEmployeeStep({
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

class _ScheduleTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String timeRange;

  const _ScheduleTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
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
                        color: color,
                      ),
                    ),
                    Text(
                      timeRange,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
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

class _AccessLevelCard extends StatelessWidget {
  final String role;
  final List<String> permissions;
  final Color color;

  const _AccessLevelCard({
    required this.role,
    required this.permissions,
    required this.color,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...permissions.map((permission) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    permission,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _LicenseLimitWidget extends StatelessWidget {
  final String plan;
  final int limit;
  final Color color;

  const _LicenseLimitWidget({
    required this.plan,
    required this.limit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  'Maximum $limit employés',
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
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

/// ===============================
/// Personnel – Aide (Modernisé)
/// ===============================

HelpCategory getStaffHelp() {
  return HelpCategory(
    title: 'Personnel',
    icon: Icons.groups_rounded,
    sections: [
      /// Section 1 : Gestion de l'équipe
      HelpSection(
        title: 'Gestion de l\'équipe',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le module de gestion du personnel centralise toutes les informations sur vos employés : identité, coordonnées, poste, département, planning, historique.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Départements
            Text(
              'Départements :',
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
                _DepartmentBadge(
                  title: 'Réception et accueil',
                  icon: Icons.desk_rounded,
                  color: Colors.blue,
                ),
                _DepartmentBadge(
                  title: 'Hébergement',
                  icon: Icons.hotel_rounded,
                  color: Colors.green,
                ),
                _DepartmentBadge(
                  title: 'Restauration et bar',
                  icon: Icons.restaurant_rounded,
                  color: Colors.orange,
                ),
                _DepartmentBadge(
                  title: 'Cuisine',
                  icon: Icons.kitchen_rounded,
                  color: Colors.red,
                ),
                _DepartmentBadge(
                  title: 'Maintenance',
                  icon: Icons.build_rounded,
                  color: Colors.purple,
                ),
                _DepartmentBadge(
                  title: 'Spa et bien-être',
                  icon: Icons.spa_rounded,
                  color: Colors.pink,
                ),
                _DepartmentBadge(
                  title: 'Administration',
                  icon: Icons.work_rounded,
                  color: Colors.teal,
                ),
                _DepartmentBadge(
                  title: 'Direction',
                  icon: Icons.emoji_people_rounded,
                  color: Colors.amber.shade700,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Rôles principaux
            Text(
              'Postes types :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _RoleCard(
                  title: 'Réceptionniste',
                  description: 'Accueil, check-in/out, gestion des réservations et paiements',
                  icon: Icons.desk_rounded,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  title: 'Femme de chambre',
                  description: 'Nettoyage et entretien des chambres, préparation pour les arrivées',
                  icon: Icons.cleaning_services_rounded,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  title: 'Serveur/Serveuse',
                  description: 'Service en salle restaurant, prise de commandes, encaissement',
                  icon: Icons.restaurant_rounded,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  title: 'Chef de cuisine',
                  description: 'Gestion de la cuisine, élaboration des plats, contrôle qualité',
                  icon: Icons.kitchen_rounded,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  title: 'Agent de maintenance',
                  description: 'Réparations, entretien technique, gestion des équipements',
                  icon: Icons.build_rounded,
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Informations stockées
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
                        'Informations stockées pour chaque employé :',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _EmployeeInfoChip(
                        icon: Icons.person_rounded,
                        label: 'Données personnelles',
                      ),
                      _EmployeeInfoChip(
                        icon: Icons.email_rounded,
                        label: 'Coordonnées',
                      ),
                      _EmployeeInfoChip(
                        icon: Icons.work_history_rounded,
                        label: 'Informations professionnelles',
                      ),
                      _EmployeeInfoChip(
                        icon: Icons.schedule_rounded,
                        label: 'Horaires et planning',
                      ),
                      _EmployeeInfoChip(
                        icon: Icons.school_rounded,
                        label: 'Compétences et formations',
                      ),
                      _EmployeeInfoChip(
                        icon: Icons.description_rounded,
                        label: 'Documents administratifs',
                      ),
                      _EmployeeInfoChip(
                        icon: Icons.assessment_rounded,
                        label: 'Historique de performance',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Accédez au menu "Personnel" pour voir la liste complète de vos employés',
          'Le tableau affiche : Nom complet, Poste, Département, Email, Téléphone, Statut',
          'Utilisez les filtres pour afficher seulement un département ou un poste spécifique',
          'La barre de recherche permet de trouver rapidement un employé par nom',
          'Cliquez sur un employé pour voir sa fiche complète avec tous les détails',
        ],
      ),

      /// Section 2 : Ajouter un nouvel employé
      HelpSection(
        title: 'Ajouter un nouvel employé',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'L\'ajout d\'un employé crée son compte dans le système et lui donne accès aux fonctionnalités correspondant à son rôle.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Limites de licence
            Text(
              'Limites selon votre licence :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _LicenseLimitWidget(
                    plan: 'Basic',
                    limit: 3,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LicenseLimitWidget(
                    plan: 'Starter',
                    limit: 10,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LicenseLimitWidget(
                    plan: 'Pro',
                    limit: 20,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.all_inclusive_rounded,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Entreprise',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                              Text(
                                'Illimité',
                                style: TextStyle(
                                  color: Colors.amber.shade700,
                                  fontSize: 12,
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

            const SizedBox(height: 32),

            // Niveaux d'accès
            Text(
              'Niveaux d\'accès par poste :',
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
                _AccessLevelCard(
                  role: 'Réceptionniste',
                  color: Colors.blue,
                  permissions: [
                    'Réservations',
                    'Check-in/out',
                    'Paiements',
                  ],
                ),
                _AccessLevelCard(
                  role: 'Femme de chambre',
                  color: Colors.green,
                  permissions: [
                    'Tâches de nettoyage',
                    'Planning quotidien',
                    'Statuts chambres',
                    'Rapports de travail',
                  ],
                ),
                _AccessLevelCard(
                  role: 'Serveur/Serveuse',
                  color: Colors.orange,
                  permissions: [
                    'Restaurant',
                    'Commandes',
                    'Encaissement',
                    'Tables',
                  ],
                ),
                _AccessLevelCard(
                  role: 'Manager',
                  color: Colors.purple,
                  permissions: [
                    'Tous les modules',
                    'Statistiques',
                    'Gestion équipe',
                    'Rapports',
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Étapes d'ajout
            Text(
              'Étapes d\'ajout d\'un employé :',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            Column(
              children: [
                _AddEmployeeStep(
                  stepNumber: 1,
                  title: 'Accéder au formulaire',
                  description: 'Dans la page Personnel, cliquez sur "Ajouter un employé"',
                  icon: Icons.add_circle_rounded,
                  color: Colors.blue,
                ),
                _AddEmployeeStep(
                  stepNumber: 2,
                  title: 'Informations personnelles',
                  description: 'Saisissez le nom, prénom, email professionnel et téléphone',
                  icon: Icons.person_add_rounded,
                  color: Colors.green,
                ),
                _AddEmployeeStep(
                  stepNumber: 3,
                  title: 'Informations professionnelles',
                  description: 'Sélectionnez le poste et le département',
                  icon: Icons.work_rounded,
                  color: Colors.orange,
                ),
                _AddEmployeeStep(
                  stepNumber: 4,
                  title: 'Configuration du compte',
                  description: 'Définissez un mot de passe temporaire et une photo de profil',
                  icon: Icons.security_rounded,
                  color: Colors.purple,
                ),
                _AddEmployeeStep(
                  stepNumber: 5,
                  title: 'Vérification et création',
                  description: 'Vérifiez les informations et cliquez sur "Créer le compte"',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),
                _AddEmployeeStep(
                  stepNumber: 6,
                  title: 'Notification',
                  description: 'L\'employé reçoit un email avec ses identifiants de connexion',
                  icon: Icons.email_rounded,
                  color: Colors.teal,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Note importante
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
                    Icons.lightbulb_rounded,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Processus d\'onboarding complet :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '1. Création du compte\n'
                              '2. Attribution des accès selon le poste\n'
                              '3. Envoi des identifiants par email\n'
                              '4. Formation initiale à l\'utilisation du système',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Dans la page Personnel, cliquez sur "Ajouter un employé"',
          'Remplissez le formulaire complet',
          'Saisissez les informations personnelles',
          'Définissez les informations professionnelles',
          'Configurez le mot de passe temporaire',
          'Ajoutez une photo de profil',
          'Vérifiez toutes les informations',
          'Cliquez sur "Créer le compte employé"',
          'Le système vérifie la limite de votre licence',
          'L\'employé reçoit ses identifiants par email',
        ],
      ),

      /// Section 3 : Gestion des plannings
      HelpSection(
        title: 'Gestion des plannings',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Un planning bien organisé assure un service de qualité et évite les sous-effectifs ou sur-effectifs.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Types de planning
            Text(
              'Types de planning :',
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
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
                            Icons.calendar_view_week_rounded,
                            color: Colors.blue,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Hebdomadaire',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vue de la semaine',
                            style: TextStyle(
                              color: Colors.blue.shade700,
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
                            Icons.calendar_month_rounded,
                            color: Colors.green,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Mensuel',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vue d\'ensemble',
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
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            color: Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Individuel',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Par employé',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Shifts et rotations
            Text(
              'Shifts et rotations :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            Column(
              children: [
                _ScheduleTypeCard(
                  title: 'Matin',
                  description: 'Service du matin, préparation de l\'hôtel',
                  icon: Icons.wb_sunny_rounded,
                  color: Colors.amber,
                  timeRange: '6h - 14h',
                ),
                const SizedBox(height: 12),
                _ScheduleTypeCard(
                  title: 'Après-midi',
                  description: 'Service principal, gestion des arrivées',
                  icon: Icons.light_mode_rounded,
                  color: Colors.orange,
                  timeRange: '14h - 22h',
                ),
                const SizedBox(height: 12),
                _ScheduleTypeCard(
                  title: 'Nuit',
                  description: 'Service de nuit, réception 24h/24',
                  icon: Icons.nightlight_round,
                  color: Colors.indigo,
                  timeRange: '22h - 6h',
                ),
                const SizedBox(height: 12),
                _ScheduleTypeCard(
                  title: 'Journée complète',
                  description: 'Pour les managers et personnel administratif',
                  icon: Icons.schedule_rounded,
                  color: Colors.blue,
                  timeRange: '8h - 20h',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Gestion des congés
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade50,
                    Colors.pink.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.beach_access_rounded,
                    color: Colors.purple.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestion des congés :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.purple.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• L\'employé fait une demande via son interface\n'
                              '• Le manager reçoit une notification\n'
                              '• Approbation ou refus du congé\n'
                              '• Les congés approuvés apparaissent automatiquement dans le planning\n'
                              '• Gestion des soldes de congés',
                          style: TextStyle(
                            color: Colors.purple.shade700,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Exemple de planning
            Container(
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
                  Text(
                    'Exemple de planning hebdomadaire :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/images/schedule_example.png',
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Légende :',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Matin', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 16),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Après-midi', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 16),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Nuit', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Accédez à "Emplois du temps" dans le menu Personnel',
          'Sélectionnez la semaine ou le mois à planifier',
          'Le calendrier s\'affiche avec une ligne par employé',
          'Pour ajouter un shift : Cliquez sur la case jour + employé',
          'Sélectionnez le type de shift',
          'Définissez les horaires exacts',
          'Le shift apparaît immédiatement dans le planning',
          'L\'employé reçoit une notification de son planning',
        ],
      ),
    ],
  );
}