import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({Key? key}) : super(key: key);

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  // Exemples de commandes à servir
  final List<Map<String, dynamic>> _ordersToServe = [
    {
      'id': 'CMD-003',
      'room': '305',
      'time': '10:25',
      'status': 'Prêt à servir',
      'items': [
        {'name': 'Petit déjeuner continental', 'quantity': 2},
        {'name': 'Café au lait', 'quantity': 2},
      ],
    },
    {
      'id': 'CMD-005',
      'room': '201',
      'time': '10:40',
      'status': 'Prêt à servir',
      'items': [
        {'name': 'Oeufs bénédictine', 'quantity': 1},
        {'name': 'Thé vert', 'quantity': 1},
      ],
    },
  ];

  // Exemples de tables attribuées
  final List<Map<String, dynamic>> _assignedTables = [
    {
      'number': '12',
      'guests': 4,
      'status': 'Occupée',
      'seated_at': '09:30',
      'orders': [
        {
          'id': 'RES-012',
          'time': '09:45',
          'status': 'Servi',
          'items': [
            {'name': 'Café', 'quantity': 4},
            {'name': 'Croissant', 'quantity': 2},
          ],
        },
        {
          'id': 'RES-015',
          'time': '10:15',
          'status': 'En préparation',
          'items': [
            {'name': 'Omelette', 'quantity': 2},
            {'name': 'Salade', 'quantity': 1},
          ],
        },
      ],
    },
    {
      'number': '8',
      'guests': 2,
      'status': 'Occupée',
      'seated_at': '10:00',
      'orders': [
        {
          'id': 'RES-014',
          'time': '10:10',
          'status': 'En préparation',
          'items': [
            {'name': 'Menu du jour', 'quantity': 2},
            {'name': 'Vin rouge', 'quantity': 1},
          ],
        },
      ],
    },
    {
      'number': '5',
      'guests': 0,
      'status': 'Réservée',
      'reservation_time': '12:30',
      'orders': [],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service de Salle',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: GestoTheme.navyBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gestion du service en salle et room service',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // TabBar pour basculer entre les sections
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: GestoTheme.navyBlue,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[700],
              tabs: const [
                Tab(text: 'Room Service'),
                Tab(text: 'Tables'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // TabBarView avec le contenu des tabs
          Expanded(
            child: TabBarView(
              children: [
                _buildRoomServiceTab(),
                _buildTablesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomServiceTab() {
    if (_ordersToServe.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.room_service,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune commande à servir',
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
      itemCount: _ordersToServe.length,
      itemBuilder: (context, index) {
        final order = _ordersToServe[index];

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
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            order['status'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'À servir: ${order['time']}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ...List.generate(
                  order['items'].length,
                      (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          '${order['items'][i]['quantity']}x',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(order['items'][i]['name']),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Impression du ticket ${order['id']}')),
                        );
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimer'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Commande ${order['id']} marquée comme servie')),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Servie'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GestoTheme.navyBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTablesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher une table...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité non disponible')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle table'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GestoTheme.navyBlue,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _assignedTables.length,
            itemBuilder: (context, index) {
              final table = _assignedTables[index];

              Color statusColor;
              String statusText;

              switch (table['status']) {
                case 'Occupée':
                  statusColor = Colors.red;
                  statusText = 'Occupée';
                  break;
                case 'Réservée':
                  statusColor = Colors.orange;
                  statusText = 'Réservée';
                  break;
                default:
                  statusColor = Colors.green;
                  statusText = 'Libre';
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    // Afficher les détails de la table
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Détails de la table ${table['number']}')),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Table ${table['number']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (table['status'] == 'Occupée') ...[
                          Row(
                            children: [
                              Icon(Icons.people, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${table['guests']} convives',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Depuis ${table['seated_at']}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${table['orders'].length} commande(s)',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Afficher les commandes
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Commandes de la table ${table['number']}')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GestoTheme.navyBlue,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text('Voir commandes'),
                                ),
                              ),
                            ],
                          ),
                        ] else if (table['status'] == 'Réservée') ...[
                          Row(
                            children: [
                              Icon(Icons.event, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Réservée pour ${table['reservation_time']}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Marquer comme libre
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Table ${table['number']} marquée comme libre')),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text('Annuler réservation'),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Ajouter une réservation
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Réserver la table ${table['number']}')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text('Attribuer table'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}