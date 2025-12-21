// Script d'initialisation de la Roadmap
// Exécutez ce script une fois pour créer des exemples de roadmap items

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> initializeRoadmap() async {
  final firestore = FirebaseFirestore.instance;
  
  // Éléments de roadmap à créer
  final roadmapItems = [
    {
      'title': 'Intégration Google Calendar',
      'description': 'Synchronisation automatique des réservations avec Google Calendar pour une meilleure gestion des disponibilités.',
      'status': 'inProgress',
      'priority': 'high',
      'category': 'Intégrations',
      'tags': ['calendrier', 'google', 'synchronisation'],
      'estimatedDate': DateTime(2025, 2, 1),
      'createdAt': DateTime.now(),
      'votesCount': 0,
      'voters': [],
    },
    {
      'title': 'Application mobile native',
      'description': 'Développement d\'une application mobile native iOS et Android pour accéder à Gesto en déplacement.',
      'status': 'planned',
      'priority': 'high',
      'category': 'Applications',
      'tags': ['mobile', 'ios', 'android'],
      'estimatedDate': DateTime(2025, 4, 1),
      'createdAt': DateTime.now(),
      'votesCount': 0,
      'voters': [],
    },
    {
      'title': 'Mode hors ligne',
      'description': 'Possibilité de continuer à utiliser Gesto sans connexion internet, avec synchronisation automatique.',
      'status': 'planned',
      'priority': 'medium',
      'category': 'Fonctionnalités',
      'tags': ['offline', 'sync', 'performance'],
      'estimatedDate': DateTime(2025, 3, 15),
      'createdAt': DateTime.now(),
      'votesCount': 0,
      'voters': [],
    },
    {
      'title': 'Rapports analytics avancés',
      'description': 'Tableaux de bord avec analyses détaillées des performances, revenus, et tendances.',
      'status': 'inProgress',
      'priority': 'medium',
      'category': 'Analytics',
      'tags': ['rapports', 'statistiques', 'analytics'],
      'estimatedDate': DateTime(2025, 1, 20),
      'createdAt': DateTime.now(),
      'votesCount': 0,
      'voters': [],
    },
    {
      'title': 'Multi-propriétés',
      'description': 'Gérer plusieurs établissements depuis un seul compte avec bascule rapide.',
      'status': 'planned',
      'priority': 'high',
      'category': 'Fonctionnalités',
      'tags': ['multi-sites', 'entreprise', 'gestion'],
      'estimatedDate': DateTime(2025, 5, 1),
      'createdAt': DateTime.now(),
      'votesCount': 0,
      'voters': [],
    },
    {
      'title': 'Intégration Stripe Connect',
      'description': 'Paiements directs dans l\'application avec gestion complète des transactions.',
      'status': 'completed',
      'priority': 'high',
      'category': 'Paiements',
      'tags': ['stripe', 'paiement', 'transaction'],
      'completedAt': DateTime(2024, 12, 10),
      'createdAt': DateTime(2024, 11, 1),
      'votesCount': 0,
      'voters': [],
    },
    {
      'title': 'Chatbot IA pour support',
      'description': 'Assistant IA pour répondre aux questions fréquentes et guider les utilisateurs.',
      'status': 'planned',
      'priority': 'low',
      'category': 'Support',
      'tags': ['ia', 'chatbot', 'support'],
      'estimatedDate': DateTime(2025, 6, 1),
      'createdAt': DateTime.now(),
      'votesCount': 0,
      'voters': [],
    },
    {
      'title': 'API publique',
      'description': 'API REST pour intégrer Gesto avec d\'autres systèmes et outils.',
      'status': 'planned',
      'priority': 'medium',
      'category': 'Développeurs',
      'tags': ['api', 'intégration', 'développeurs'],
      'estimatedDate': DateTime(2025, 7, 1),
      'createdAt': DateTime.now(),
      'votesCount': 0,
      'voters': [],
    },
    {
      'title': 'Thèmes personnalisables',
      'description': 'Personnalisation complète des couleurs et du branding de l\'interface.',
      'status': 'inProgress',
      'priority': 'low',
      'category': 'Interface',
      'tags': ['design', 'thème', 'personnalisation'],
      'estimatedDate': DateTime(2025, 2, 15),
      'createdAt': DateTime.now(),
      'votesCount': 0,
      'voters': [],
    },
    {
      'title': 'Notifications SMS',
      'description': 'Envoi de SMS aux clients pour confirmer réservations et rappels.',
      'status': 'planned',
      'priority': 'medium',
      'category': 'Communications',
      'tags': ['sms', 'notifications', 'communication'],
      'estimatedDate': DateTime(2025, 3, 1),
      'createdAt': DateTime.now(),
      'votesCount': 0,
      'voters': [],
    },
  ];

  // Créer les documents
  for (var item in roadmapItems) {
    try {
      await firestore.collection('roadmap').add({
        'title': item['title'],
        'description': item['description'],
        'status': item['status'],
        'priority': item['priority'],
        'category': item['category'],
        'tags': item['tags'],
        'createdAt': Timestamp.fromDate(item['createdAt'] as DateTime),
        'estimatedDate': item['estimatedDate'] != null 
            ? Timestamp.fromDate(item['estimatedDate'] as DateTime)
            : null,
        'completedAt': item['completedAt'] != null 
            ? Timestamp.fromDate(item['completedAt'] as DateTime)
            : null,
        'votesCount': item['votesCount'],
        'voters': item['voters'],
      });
      
      print('✅ Roadmap item créé: ${item['title']}');
    } catch (e) {
      print('❌ Erreur création roadmap item ${item['title']}: $e');
    }
  }
  
  print('🎉 Initialisation de la roadmap terminée !');
}

// Pour exécuter ce script:
// 1. Créez un bouton temporaire dans votre interface admin
// 2. Appelez cette fonction au clic
// 3. Vérifiez dans Firebase Console que les données sont créées
// 4. Supprimez le bouton une fois l'initialisation faite

/*
EXEMPLE D'UTILISATION DANS UN BOUTON:

ElevatedButton(
  onPressed: () async {
    await initializeRoadmap();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Roadmap initialisée !')),
    );
  },
  child: Text('Initialiser la Roadmap'),
)
*/
