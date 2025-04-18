import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class RoomServiceScreen extends StatefulWidget {
  const RoomServiceScreen({Key? key}) : super(key: key);

  @override
  State<RoomServiceScreen> createState() => _RoomServiceScreenState();
}

class _RoomServiceScreenState extends State<RoomServiceScreen> {
  // Exemple de tâches de service de chambre
  final List<Map<String, dynamic>> _roomServiceTasks = [
    {
      'id': 'TASK-001',
      'room': '205',
      'type': 'Nettoyage',
      'time': '09:00',
      'status': 'En attente',
      'priority': 'Haute',
      'notes': 'Client VIP, ajoutez des serviettes supplémentaires',
    },
    {
      'id': 'TASK-002',
      'room': '312',
      'type': 'Changement draps',
      'time': '10:30',
      'status': 'En attente',
      'priority': 'Normale',
      'notes': '',
    },
    {
      'id': 'TASK-003',
      'room': '118',
      'type': 'Maintenance',
      'time': '11:15',
      'status': 'En cours',
      'priority': 'Haute',
      'notes': 'Problème de climatisation',
    },
    {
      'id': 'TASK-004',
      'room': '201',
      'type': 'Vérification minibar',
      'time': '13:00',
      'status': 'En attente',
      'priority': 'Basse',
      'notes': '',
    },
    {
      'id': 'TASK-005',
      'room': '104',
      'type': 'Nettoyage',
      'time': '14:30',
      'status': 'Terminée',
      'priority': 'Normale',
      'notes': '',
      'completed_at': '15:10',
    },
  ];

  // Filtres
  String _selectedStatus = 'Tous';
  String _selectedPriority = 'Toutes';
  String _selectedType = 'Tous';

  // Fonction pour filtrer les tâches
  List<Map<String, dynamic>> get _filteredTasks {
    return _roomServiceTasks.where((task) {
      // Filtre par statut
      bool statusMatch = _selectedStatus == 'Tous' || task['status'] == _selectedStatus;

      // Filtre par priorité
      bool priorityMatch = _selectedPriority == 'Toutes' || task['priority'] == _selectedPriority;

      // Filtre par type
      bool typeMatch = _selectedType == 'Tous' || task['type'] == _selectedType;

      return statusMatch && priorityMatch && typeMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service de Chambre',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: GestoTheme.navyBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gestion des tâches d\'entretien des chambres',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),

        // Section de filtres
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Statut: $_selectedStatus',
                icon: Icons.filter_list,
                onTap: () {
                  _showFilterDialog(
                    title: 'Filtrer par statut',
                    options: const ['Tous', 'En attente', 'En cours', 'Terminée'],
                    selectedValue: _selectedStatus,
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildFilterChip(
                label: 'Priorité: $_selectedPriority',
                icon: Icons.priority_high,
                onTap: () {
                  _showFilterDialog(
                    title: 'Filtrer par priorité',
                    options: const ['Toutes', 'Haute', 'Normale', 'Basse'],
                    selectedValue: _selectedPriority,
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildFilterChip(
                label: 'Type: $_selectedType',
                icon: Icons.category,
                onTap: () {
                  _showFilterDialog(
                    title: 'Filtrer par type',
                    options: const ['Tous', 'Nettoyage', 'Changement draps', 'Maintenance', 'Vérification minibar'],
                    selectedValue: _selectedType,
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedStatus = 'Tous';
                    _selectedPriority = 'Toutes';
                    _selectedType = 'Tous';
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Réinitialiser'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: GestoTheme.navyBlue),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité non disponible')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle tâche'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GestoTheme.navyBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Liste des tâches
        Expanded(
          child: _filteredTasks.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cleaning_services,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune tâche trouvée',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: _filteredTasks.length,
            itemBuilder: (context, index) {
              final task = _filteredTasks[index];
              return _buildTaskCard(task);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: GestoTheme.navyBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GestoTheme.navyBlue.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: GestoTheme.navyBlue),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: GestoTheme.navyBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog({
    required String title,
    required List<String> options,
    required String selectedValue,
    required Function(String) onChanged,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectedValue,
                  onChanged: (value) {
                    onChanged(value!);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    Color statusColor;
    IconData statusIcon;

    switch (task['status']) {
      case 'Terminée':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'En cours':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'En attente':
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
    }

    Color priorityColor;
    switch (task['priority']) {
      case 'Haute':
        priorityColor = Colors.red[700]!;
        break;
      case 'Normale':
        priorityColor = Colors.amber[700]!;
        break;
      case 'Basse':
      default:
        priorityColor = Colors.green[700]!;
        break;
    }

    IconData typeIcon;
    switch (task['type']) {
      case 'Maintenance':
        typeIcon = Icons.build;
        break;
      case 'Changement draps':
        typeIcon = Icons.hotel;
        break;
      case 'Vérification minibar':
        typeIcon = Icons.liquor;
        break;
      case 'Nettoyage':
      default:
        typeIcon = Icons.cleaning_services;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${task['type']} - Chambre ${task['room']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  task['status'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Priorité ${task['priority']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: priorityColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          task['time'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (task['status'] == 'Terminée' && task['completed_at'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Terminée à ${task['completed_at']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (task['notes'].isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task['notes'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (task['status'] == 'En attente') ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tâche ${task['id']} reportée')),
                      );
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Reporter'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tâche ${task['id']} démarrée')),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Démarrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ] else if (task['status'] == 'En cours') ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Problème signalé pour la tâche ${task['id']}')),
                      );
                    },
                    icon: const Icon(Icons.warning),
                    label: const Text('Signaler problème'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tâche ${task['id']} terminée')),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Terminer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Détails de la tâche ${task['id']}')),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Voir détails'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GestoTheme.navyBlue,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}