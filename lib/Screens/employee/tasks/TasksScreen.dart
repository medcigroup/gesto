import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'employee_models.dart';
import 'employee_service.dart';
import 'employee_task_card.dart';
import 'employee_task_details.dart';


class EmployeeTaskScreen extends StatefulWidget {
  const EmployeeTaskScreen({Key? key}) : super(key: key);

  @override
  _EmployeeTaskScreenState createState() => _EmployeeTaskScreenState();
}

class _EmployeeTaskScreenState extends State<EmployeeTaskScreen> {
  final EmployeeTaskService _taskService = EmployeeTaskService();
  DateTime _selectedDate = DateTime.now();
  String? _selectedStatusFilter;
  String? _selectedPriorityFilter;
  bool _isLoading = true;
  List<EmployeeTask> _tasks = [];
  Map<String, int> _taskStats = {
    'pending': 0,
    'in_progress': 0,
    'completed': 0,
    'total': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadTasksForDate();
    _loadTaskStats();
  }

  Future<void> _loadTaskStats() async {
    final stats = await _taskService.getTaskStats();
    setState(() {
      _taskStats = stats;
    });
  }

  void _loadTasksForDate() {
    setState(() {
      _isLoading = true;
    });

    _taskService.getTasksForDate(_selectedDate).listen((tasks) {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    });
  }

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _loadTasksForDate();
    }
  }

  List<EmployeeTask> get _filteredTasks {
    return _tasks.where((task) {
      // Filtre par statut
      if (_selectedStatusFilter != null && task.status != _selectedStatusFilter) {
        return false;
      }

      // Filtre par priorité
      if (_selectedPriorityFilter != null && task.priority != _selectedPriorityFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  void _updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _taskService.updateTaskStatus(taskId, newStatus);
      _loadTasksForDate();
      _loadTaskStats();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              newStatus == 'in_progress'
                  ? 'Tâche démarrée avec succès'
                  : 'Tâche marquée comme terminée'
          ),
          backgroundColor: newStatus == 'in_progress' ? Colors.blue : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTaskDetails(EmployeeTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmployeeTaskDetailsBottomSheet(
        task: task,
        onStatusChange: _updateTaskStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Mes Tâches',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques des tâches
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistiques de mes tâches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                      title: 'En attente',
                      count: _taskStats['pending'] ?? 0,
                    ),
                    _buildStatCard(
                      icon: Icons.hourglass_bottom,
                      color: Colors.blue,
                      title: 'En cours',
                      count: _taskStats['in_progress'] ?? 0,
                    ),
                    _buildStatCard(
                      icon: Icons.check_circle,
                      color: Colors.green,
                      title: 'Terminées',
                      count: _taskStats['completed'] ?? 0,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Sélecteur de date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tâches du jour',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filtres
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Statut',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    value: _selectedStatusFilter,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous les statuts')),
                      DropdownMenuItem(value: 'pending', child: Text('En attente')),
                      DropdownMenuItem(value: 'in_progress', child: Text('En cours')),
                      DropdownMenuItem(value: 'completed', child: Text('Terminées')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatusFilter = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Priorité',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    value: _selectedPriorityFilter,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Toutes les priorités')),
                      DropdownMenuItem(value: 'high', child: Text('Haute')),
                      DropdownMenuItem(value: 'medium', child: Text('Normale')),
                      DropdownMenuItem(value: 'low', child: Text('Basse')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPriorityFilter = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Liste des tâches
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune tâche pour cette date',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                final task = _filteredTasks[index];
                return EmployeeTaskCard(
                  task: task,
                  onStatusChange: _updateTaskStatus,
                  onTaskTap: _showTaskDetails,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required int count,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}