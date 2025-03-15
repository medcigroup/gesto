class AppConstants {
  // Liste des départements
  static const List<String> departements = [
    'Tous',
    'Accueil',
    'Service',
    'Chambres',
    'Maintenance',
    'Administration'
  ];

  // Liste des postes
  static const List<String> postes = [
    'Réceptionniste', 'Concierge', 'Manager',
    'Femme de chambre', 'Serveur', 'Chef',
    'Technicien', 'Agent d\'entretien', 'Directeur'
  ];

  // Liste des permissions disponibles
  static const List<String> availablePermissions = [
    'Gestion des réservations',
    'Facturation',
    'Gestion des stocks',
    'Administration du personnel',
    'Gestion des chambres',
    'Accès au coffre',
    'Gestion des événements',
    'Gestion des problèmes techniques',
  ];
}