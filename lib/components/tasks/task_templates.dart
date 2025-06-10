import 'package:flutter/material.dart';

import '../../config/task_models.dart';


/// Classe représentant un modèle de tâche prédéfini
class TaskTemplate {
  final String title;
  final String description;
  final String taskType;
  final String priority;
  final Duration defaultDuration; // Durée par défaut avant échéance
  final IconData icon;
  final String role; // Rôle associé au modèle (serveur, femme de chambre, etc.)

  TaskTemplate({
    required this.title,
    required this.description,
    required this.taskType,
    required this.priority,
    required this.defaultDuration,
    required this.icon,
    required this.role,
  });

  /// Convertit le modèle en tâche réelle
  Task toTask({required String assignedTo}) {
    return Task(
      id: '', // L'ID sera généré par Firestore
      title: title,
      description: description,
      dueDate: DateTime.now().add(defaultDuration),
      status: 'pending',
      assignedTo: assignedTo,
      taskType: taskType,
      createdAt: DateTime.now(),
      priority: priority,
    );
  }
}

/// Classe gestionnaire des modèles de tâches
class TaskTemplateManager {
  /// Modèles pour les serveurs de restaurant
  static final List<TaskTemplate> _serverTemplates = [
    TaskTemplate(
      title: 'Mise en place salle',
      description: 'Préparer la salle pour le service: nappes, couverts, verres, etc.',
      taskType: 'service',
      priority: 'high',
      defaultDuration: const Duration(hours: 1),
      icon: Icons.restaurant,
      role: 'serveur',
    ),
    TaskTemplate(
      title: 'Vérification des réservations',
      description: 'Contrôler la liste des réservations et préparer le plan de salle',
      taskType: 'service',
      priority: 'medium',
      defaultDuration: const Duration(hours: 1),
      icon: Icons.book_online,
      role: 'serveur',
    ),
    TaskTemplate(
      title: 'Briefing menu du jour',
      description: 'Revoir avec l\'équipe les plats du jour, allergènes et suggestions',
      taskType: 'service',
      priority: 'high',
      defaultDuration: const Duration(minutes: 30),
      icon: Icons.menu_book,
      role: 'serveur',
    ),
    TaskTemplate(
      title: 'Nettoyage fin de service',
      description: 'Nettoyer et ranger la salle après le service',
      taskType: 'service',
      priority: 'medium',
      defaultDuration: const Duration(hours: 1),
      icon: Icons.cleaning_services,
      role: 'serveur',
    ),
    // Ajoutez ces templates à la liste _serverTemplates existante

// Service en chambre
    TaskTemplate(
      title: 'Livraison petit-déjeuner',
      description: 'Préparer et livrer les plateaux de petit-déjeuner en chambre selon les commandes',
      taskType: 'service',
      priority: 'high',
      defaultDuration: const Duration(minutes: 20),
      icon: Icons.breakfast_dining,
      role: 'serveur',
    ),
    TaskTemplate(
      title: 'Room service repas',
      description: 'Livrer un repas commandé en chambre, installation et présentation soignée',
      taskType: 'service',
      priority: 'high',
      defaultDuration: const Duration(minutes: 25),
      icon: Icons.room_service,
      role: 'serveur',
    ),
    TaskTemplate(
      title: 'Room service boissons',
      description: 'Préparer et livrer des boissons commandées en chambre',
      taskType: 'service',
      priority: 'medium',
      defaultDuration: const Duration(minutes: 15),
      icon: Icons.local_bar,
      role: 'serveur',
    ),
    TaskTemplate(
      title: 'Collecte vaisselle',
      description: 'Collecter les plateaux et la vaisselle utilisés devant les chambres ou sur appel client',
      taskType: 'service',
      priority: 'medium',
      defaultDuration: const Duration(minutes: 30),
      icon: Icons.cleaning_services,
      role: 'serveur',
    ),

// Services spéciaux
    TaskTemplate(
      title: 'Plateau VIP/événement spécial',
      description: 'Préparer et livrer un plateau spécial pour occasion particulière (anniversaire, lune de miel, etc.)',
      taskType: 'service',
      priority: 'high',
      defaultDuration: const Duration(minutes: 30),
      icon: Icons.celebration,
      role: 'serveur',
    ),
    TaskTemplate(
      title: 'Service champagne/vin',
      description: 'Service de champagne ou vin en chambre avec présentation et dégustation',
      taskType: 'service',
      priority: 'medium',
      defaultDuration: const Duration(minutes: 20),
      icon: Icons.wine_bar,
      role: 'serveur',
    ),

// Préparation
    TaskTemplate(
      title: 'Préparation chariots room service',
      description: 'Vérifier et réapprovisionner les chariots de service en chambre (linge, vaisselle, accessoires)',
      taskType: 'service',
      priority: 'medium',
      defaultDuration: const Duration(minutes: 45),
      icon: Icons.shopping_cart,
      role: 'serveur',
    ),
    TaskTemplate(
      title: 'Vérification minibar',
      description: 'Contrôler et réapprovisionner les minibars des chambres selon la liste standard',
      taskType: 'service',
      priority: 'low',
      defaultDuration: const Duration(hours: 2),
      icon: Icons.kitchen,
      role: 'serveur',
    ),

// Autres services
    TaskTemplate(
      title: 'Service petit-déjeuner buffet',
      description: 'Assurer le service et le réapprovisionnement du buffet petit-déjeuner',
      taskType: 'service',
      priority: 'high',
      defaultDuration: const Duration(hours: 3),
      icon: Icons.egg_alt,
      role: 'serveur',
    ),
    TaskTemplate(
      title: 'Préparation salle banquet',
      description: 'Installer et préparer une salle pour un événement ou banquet spécifique',
      taskType: 'service',
      priority: 'high',
      defaultDuration: const Duration(hours: 2),
      icon: Icons.event,
      role: 'serveur',
    ),
    TaskTemplate(
      title: 'Service pause café',
      description: 'Préparer et servir une pause café pour un événement ou une réunion',
      taskType: 'service',
      priority: 'medium',
      defaultDuration: const Duration(minutes: 45),
      icon: Icons.coffee,
      role: 'serveur',
    ),
    TaskTemplate(
      title: 'Assistance repas enfant',
      description: 'Préparer et livrer un repas spécial pour enfant avec attention particulière',
      taskType: 'service',
      priority: 'medium',
      defaultDuration: const Duration(minutes: 20),
      icon: Icons.child_care,
      role: 'serveur',
    ),
  ];

  /// Modèles pour les femmes de chambre
  static final List<TaskTemplate> _housekeepingTemplates = [
    TaskTemplate(
      title: 'Nettoyage chambre standard',
      description: 'Nettoyer et préparer une chambre standard (lit, salle de bain, poussière)',
      taskType: 'chambre',
      priority: 'high',
      defaultDuration: const Duration(minutes: 30),
      icon: Icons.hotel,
      role: 'femme_chambre',
    ),
    TaskTemplate(
      title: 'Nettoyage suite',
      description: 'Nettoyer et préparer une suite (lit, salle de bain, salon, minibar)',
      taskType: 'chambre',
      priority: 'high',
      defaultDuration: const Duration(minutes: 45),
      icon: Icons.hotel,
      role: 'femme_chambre',
    ),
    TaskTemplate(
      title: 'Service couverture',
      description: 'Préparer le lit pour la nuit, déposer les chocolats et le programme du lendemain',
      taskType: 'chambre',
      priority: 'medium',
      defaultDuration: const Duration(minutes: 10),
      icon: Icons.bedroom_child,
      role: 'femme_chambre',
    ),
    TaskTemplate(
      title: 'Changement linge de bain',
      description: 'Remplacer les serviettes et produits d\'accueil dans la salle de bain',
      taskType: 'chambre',
      priority: 'medium',
      defaultDuration: const Duration(minutes: 15),
      icon: Icons.bathroom,
      role: 'femme_chambre',
    ),
    TaskTemplate(
      title: 'Inspection qualité',
      description: 'Vérifier un étage de chambres pour s\'assurer du respect des standards de qualité',
      taskType: 'chambre',
      priority: 'low',
      defaultDuration: const Duration(hours: 1),
      icon: Icons.checklist,
      role: 'femme_chambre',
    ),
  ];

  /// Modèles pour les réceptionnistes
  static final List<TaskTemplate> _receptionTemplates = [
    TaskTemplate(
      title: 'Check-in client',
      description: 'Accueillir et enregistrer l\'arrivée d\'un client avec ses bagages',
      taskType: 'autre',
      priority: 'high',
      defaultDuration: const Duration(minutes: 15),
      icon: Icons.login,
      role: 'receptionniste',
    ),
    TaskTemplate(
      title: 'Check-out client',
      description: 'Finaliser le séjour d\'un client et procéder à la facturation',
      taskType: 'autre',
      priority: 'high',
      defaultDuration: const Duration(minutes: 15),
      icon: Icons.logout,
      role: 'receptionniste',
    ),
    TaskTemplate(
      title: 'Gestion réclamation',
      description: 'Traiter une réclamation client et apporter une solution',
      taskType: 'autre',
      priority: 'high',
      defaultDuration: const Duration(hours: 1),
      icon: Icons.report_problem,
      role: 'receptionniste',
    ),
    TaskTemplate(
      title: 'Préparation arrivées du jour',
      description: 'Vérifier les arrivées prévues et préparer les dossiers clients',
      taskType: 'autre',
      priority: 'medium',
      defaultDuration: const Duration(hours: 1),
      icon: Icons.upcoming,
      role: 'receptionniste',
    ),
  ];

  /// Modèles pour le personnel de maintenance
  static final List<TaskTemplate> _maintenanceTemplates = [
    TaskTemplate(
      title: 'Réparation plomberie',
      description: 'Réparer un problème de plomberie signalé par un client ou le personnel',
      taskType: 'autre',
      priority: 'high',
      defaultDuration: const Duration(hours: 2),
      icon: Icons.plumbing,
      role: 'maintenance',
    ),
    TaskTemplate(
      title: 'Problème électrique',
      description: 'Intervenir sur un problème électrique dans une zone de l\'hôtel',
      taskType: 'autre',
      priority: 'high',
      defaultDuration: const Duration(hours: 2),
      icon: Icons.electrical_services,
      role: 'maintenance',
    ),
    TaskTemplate(
      title: 'Vérification chauffage/climatisation',
      description: 'Contrôler le système de chauffage ou de climatisation dans une chambre',
      taskType: 'autre',
      priority: 'medium',
      defaultDuration: const Duration(hours: 1),
      icon: Icons.thermostat,
      role: 'maintenance',
    ),
  ];

  /// Modèles pour les concierges
  static final List<TaskTemplate> _conciergeTemplates = [
    TaskTemplate(
      title: 'Réservation restaurant',
      description: 'Effectuer une réservation de restaurant pour un client',
      taskType: 'autre',
      priority: 'medium',
      defaultDuration: const Duration(hours: 1),
      icon: Icons.restaurant_menu,
      role: 'concierge',
    ),
    TaskTemplate(
      title: 'Organisation transport',
      description: 'Organiser un transport (taxi, location) pour un client',
      taskType: 'autre',
      priority: 'medium',
      defaultDuration: const Duration(hours: 1),
      icon: Icons.airport_shuttle,
      role: 'concierge',
    ),
    TaskTemplate(
      title: 'Information touristique',
      description: 'Préparer un itinéraire ou des informations touristiques personnalisées',
      taskType: 'autre',
      priority: 'low',
      defaultDuration: const Duration(hours: 2),
      icon: Icons.map,
      role: 'concierge',
    ),
  ];

  /// Récupérer tous les modèles disponibles
  static List<TaskTemplate> getAllTemplates() {
    return [
      ..._serverTemplates,
      ..._housekeepingTemplates,
      ..._receptionTemplates,
      ..._maintenanceTemplates,
      ..._conciergeTemplates,
    ];
  }

  /// Récupérer les modèles par rôle
  static List<TaskTemplate> getTemplatesByRole(String role) {
    switch (role) {
      case 'serveur':
        return _serverTemplates;
      case 'femme_chambre':
        return _housekeepingTemplates;
      case 'receptionniste':
        return _receptionTemplates;
      case 'maintenance':
        return _maintenanceTemplates;
      case 'concierge':
        return _conciergeTemplates;
      default:
        return [];
    }
  }

  /// Récupérer les modèles par type de tâche
  static List<TaskTemplate> getTemplatesByTaskType(String taskType) {
    return getAllTemplates().where((template) => template.taskType == taskType).toList();
  }

  /// Récupérer les modèles par priorité
  static List<TaskTemplate> getTemplatesByPriority(String priority) {
    return getAllTemplates().where((template) => template.priority == priority).toList();
  }

  /// Trouver un modèle par titre
  static TaskTemplate? findTemplateByTitle(String title) {
    try {
      return getAllTemplates().firstWhere((template) => template.title == title);
    } catch (e) {
      return null;
    }
  }
}

/// Widget pour sélectionner un modèle de tâche
class TaskTemplateSelector extends StatefulWidget {
  final Function(TaskTemplate) onTemplateSelected;
  final String? initialRole;

  const TaskTemplateSelector({
    Key? key,
    required this.onTemplateSelected,
    this.initialRole,
  }) : super(key: key);

  @override
  TaskTemplateSelectorState createState() => TaskTemplateSelectorState();
}

class TaskTemplateSelectorState extends State<TaskTemplateSelector> {
  String? _selectedRole;
  List<TaskTemplate> _filteredTemplates = [];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _updateFilteredTemplates();
  }

  void _updateFilteredTemplates() {
    if (_selectedRole != null) {
      _filteredTemplates = TaskTemplateManager.getTemplatesByRole(_selectedRole!);
    } else {
      _filteredTemplates = TaskTemplateManager.getAllTemplates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modèles de tâches',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),

        // Sélection du rôle
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Filtrer par rôle',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          value: _selectedRole,
          items: const [
            DropdownMenuItem(value: null, child: Text('Tous les rôles')),
            DropdownMenuItem(value: 'serveur', child: Text('Serveur')),
            DropdownMenuItem(value: 'femme_chambre', child: Text('Femme de chambre')),
            DropdownMenuItem(value: 'receptionniste', child: Text('Réceptionniste')),
            DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
            DropdownMenuItem(value: 'concierge', child: Text('Concierge')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedRole = value;
              _updateFilteredTemplates();
            });
          },
        ),
        const SizedBox(height: 16),

        // Liste des modèles
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: _filteredTemplates.isEmpty
              ? Center(
            child: Text(
              'Aucun modèle disponible pour ce rôle',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
              : ListView.builder(
            itemCount: _filteredTemplates.length,
            itemBuilder: (context, index) {
              final template = _filteredTemplates[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getPriorityColor(template.priority).withOpacity(0.2),
                  child: Icon(
                    template.icon,
                    color: _getPriorityColor(template.priority),
                    size: 20,
                  ),
                ),
                title: Text(template.title),
                subtitle: Text(
                  template.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.add_circle_outline, color: Colors.blue),
                onTap: () {
                  widget.onTemplateSelected(template);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}