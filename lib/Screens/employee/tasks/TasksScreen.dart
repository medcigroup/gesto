import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import 'TaskCard.dart';
import 'TaskModel.dart';


class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  DateTime _selectedDate = DateTime.now();

  // Exemple de tâches pour l'employé (à remplacer par des données réelles)
  final List<TaskModel> _tasks = [
    TaskModel(
      title: 'Nettoyage chambre 102',
      status: 'En attente',
      priority: 'Haute',
      dueTime: '10:00',
    ),
    TaskModel(
      title: 'Changement draps chambre 204',
      status: 'En attente',
      priority: 'Normale',
      dueTime: '11:30',
    ),
    TaskModel(
      title: 'Vérification minibar chambre 305',
      status: 'Terminée',
      priority: 'Basse',
      dueTime: '09:15',
    ),
    TaskModel(
      title: 'Maintenance climatisation chambre 118',
      status: 'En cours',
      priority: 'Haute',
      dueTime: '14:00',
    ),
  ];

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tâches du jour',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: GestoTheme.navyBlue,
              ),
            ),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: GestoTheme.navyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // En-tête des filtres
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              DropdownButton<String>(
                value: 'Toutes',
                underline: Container(),
                icon: const Icon(Icons.filter_list),
                items: const [
                  DropdownMenuItem(value: 'Toutes', child: Text('Toutes')),
                  DropdownMenuItem(value: 'En attente', child: Text('En attente')),
                  DropdownMenuItem(value: 'En cours', child: Text('En cours')),
                  DropdownMenuItem(value: 'Terminées', child: Text('Terminées')),
                ],
                onChanged: (String? newValue) {
                  // Filtre à implémenter
                },
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: 'Toutes priorités',
                underline: Container(),
                icon: const Icon(Icons.priority_high),
                items: const [
                  DropdownMenuItem(value: 'Toutes priorités', child: Text('Toutes priorités')),
                  DropdownMenuItem(value: 'Haute', child: Text('Haute')),
                  DropdownMenuItem(value: 'Normale', child: Text('Normale')),
                  DropdownMenuItem(value: 'Basse', child: Text('Basse')),
                ],
                onChanged: (String? newValue) {
                  // Filtre à implémenter
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: GestoTheme.navyBlue,
                tooltip: 'Ajouter une tâche',
                onPressed: () {
                  // Ajouter une tâche
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonction d\'ajout de tâche non disponible')),
                  );
                },
              ),
            ],
          ),
        ),

        const Divider(),
        const SizedBox(height: 8),

        // Liste des tâches
        Expanded(
          child: _tasks.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune tâche pour aujourd\'hui',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              return TaskCard(task: _tasks[index]);
            },
          ),
        ),
      ],
    );
  }
}