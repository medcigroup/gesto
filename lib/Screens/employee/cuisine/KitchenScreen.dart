import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({Key? key}) : super(key: key);

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Exemples de commandes en attente
  final List<Map<String, dynamic>> _pendingOrders = [
    {
      'id': 'CMD-001',
      'room': '204',
      'time': '10:15',
      'items': [
        {'name': 'Café américain', 'quantity': 2, 'notes': 'Sans sucre'},
        {'name': 'Croissant', 'quantity': 3, 'notes': ''},
      ],
      'status': 'En attente',
    },
    {
      'id': 'CMD-002',
      'room': '118',
      'time': '10:30',
      'items': [
        {'name': 'Omelette', 'quantity': 1, 'notes': 'Sans oignon'},
        {'name': 'Jus d\'orange', 'quantity': 1, 'notes': 'Frais'},
        {'name': 'Toast', 'quantity': 2, 'notes': ''},
      ],
      'status': 'En attente',
    },
  ];

  // Exemples de commandes en cours
  final List<Map<String, dynamic>> _inProgressOrders = [
    {
      'id': 'CMD-003',
      'room': '305',
      'time': '10:05',
      'items': [
        {'name': 'Petit déjeuner continental', 'quantity': 2, 'notes': ''},
        {'name': 'Café au lait', 'quantity': 2, 'notes': 'Extra chaud'},
      ],
      'status': 'En cours',
    },
  ];

  // Exemples de commandes terminées
  final List<Map<String, dynamic>> _completedOrders = [
    {
      'id': 'CMD-004',
      'room': '102',
      'time': '09:45',
      'items': [
        {'name': 'Pancakes', 'quantity': 1, 'notes': 'Avec sirop d\'érable'},
        {'name': 'Café', 'quantity': 1, 'notes': ''},
      ],
      'status': 'Terminée',
      'completedAt': '10:05',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuisine',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: GestoTheme.navyBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gestion des commandes et préparations culinaires',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),

        // Tabs pour les différents statuts de commande
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: GestoTheme.navyBlue,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[700],
            tabs: const [
              Tab(text: 'En attente'),
              Tab(text: 'En cours'),
              Tab(text: 'Terminées'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Contenu des tabs
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(_pendingOrders, canMarkAsInProgress: true),
              _buildOrdersList(_inProgressOrders, canMarkAsCompleted: true),
              _buildOrdersList(_completedOrders),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, {
    bool canMarkAsInProgress = false,
    bool canMarkAsCompleted = false,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune commande',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: GestoTheme.navyBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Chambre ${order['room']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Commande ${order['id']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      order['time'],
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ...List.generate(
                  order['items'].length,
                      (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: GestoTheme.navyBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${order['items'][i]['quantity']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: GestoTheme.navyBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['items'][i]['name'],
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (order['items'][i]['notes'].isNotEmpty)
                                Text(
                                  'Note: ${order['items'][i]['notes']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (order['status'] == 'Terminée')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Terminée à ${order['completedAt']}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Boutons d'action selon le statut
                if (canMarkAsInProgress || canMarkAsCompleted)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (canMarkAsInProgress)
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Commande ${order['id']} en préparation')),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Commencer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      if (canMarkAsCompleted) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Commande ${order['id']} terminée')),
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Terminer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}