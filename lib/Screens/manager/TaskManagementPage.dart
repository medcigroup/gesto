import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/tasks/TaskService.dart';
import '../../components/tasks/task_templates.dart';
import '../../config/task_models.dart';


// Page principale de gestion des tâches
class TaskManagementPage extends StatefulWidget {
  const TaskManagementPage({Key? key}) : super(key: key);

  @override
  _TaskManagementPageState createState() => _TaskManagementPageState();
}

class _TaskManagementPageState extends State<TaskManagementPage> {
  final TaskService _taskService = TaskService();

  List<Employee> _employees = [];
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _selectedEmployeeId;
  String? _selectedStatusFilter;
  String? _selectedPriorityFilter;
  String _searchQuery = '';
  bool _showEmployeeFilter = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // S'abonner au flux de données du personnel
    _taskService.getStaffForCurrentAdmin().listen((employees) {
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    });

    // S'abonner au flux de données des tâches
    _taskService.getTasksForCurrentAdmin().listen((tasks) {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    });
  }

  List<Task> get _filteredTasks {
    return _tasks.where((task) {
      // Filtre par statut
      if (_selectedStatusFilter != null && task.status != _selectedStatusFilter) {
        return false;
      }

      // Filtre par priorité
      if (_selectedPriorityFilter != null && task.priority != _selectedPriorityFilter) {
        return false;
      }

      // Filtre par employé
      if (_selectedEmployeeId != null && task.assignedTo != _selectedEmployeeId) {
        return false;
      }

      // Filtre par recherche
      if (_searchQuery.isNotEmpty &&
          !task.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !task.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showTaskBottomSheet({Task? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskFormBottomSheet(
        employees: _employees,
        task: task,
        taskService: _taskService,
      ),
    );
  }

  void _showTaskDetails(Task task) {
    final employee = _employees.firstWhere(
          (e) => e.id == task.assignedTo,
      orElse: () => Employee(id: '0', name: 'Non assigné', role: 'autre'),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailsBottomSheet(
        task: task,
        employee: employee,
        taskService: _taskService,
        onEdit: () {
          Navigator.pop(context);
          _showTaskBottomSheet(task: task);
        },
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
          'Gestion des Tâches',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showEmployeeFilter ? Icons.person : Icons.person_outline,
              color: _showEmployeeFilter ? Colors.blue : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showEmployeeFilter = !_showEmployeeFilter;
                if (!_showEmployeeFilter) {
                  _selectedEmployeeId = null;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.grey),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher une tâche',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
          ),

          // Filtres actifs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                if (_selectedStatusFilter != null)
                  _buildFilterChip(
                    label: TaskUtils.translateStatus(_selectedStatusFilter!),
                    color: TaskUtils.getStatusColor(_selectedStatusFilter!),
                    onTap: () {
                      setState(() {
                        _selectedStatusFilter = null;
                      });
                    },
                  ),
                if (_selectedPriorityFilter != null)
                  _buildFilterChip(
                    label: TaskUtils.translatePriority(_selectedPriorityFilter!),
                    color: TaskUtils.getPriorityColor(_selectedPriorityFilter!),
                    onTap: () {
                      setState(() {
                        _selectedPriorityFilter = null;
                      });
                    },
                  ),
                if (_selectedEmployeeId != null)
                  _buildFilterChip(
                    label: _employees
                        .firstWhere(
                          (e) => e.id == _selectedEmployeeId,
                      orElse: () => Employee(id: '0', name: 'Inconnu', role: 'autre'),
                    )
                        .name,
                    color: Colors.blue,
                    onTap: () {
                      setState(() {
                        _selectedEmployeeId = null;
                      });
                    },
                  ),
              ],
            ),
          ),

          // Filtre par employé si activé
          if (_showEmployeeFilter)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: const Text('Filtrer par employé'),
                      value: _selectedEmployeeId,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tous les employés'),
                        ),
                        ..._employees.map((employee) {
                          return DropdownMenuItem<String>(
                            value: employee.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  radius: 14,
                                  child: Text(
                                    employee.name.isNotEmpty
                                        ? employee.name.substring(0, 1).toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${employee.name} (${TaskUtils.translateRole(employee.role)})',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedEmployeeId = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),

          // Table des tâches
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune tâche trouvée',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
                : _buildTasksTable(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
        onPressed: () {
          _showTaskBottomSheet();
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.close,
                size: 14,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksTable() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        final employee = _employees.firstWhere(
              (e) => e.id == task.assignedTo,
          orElse: () => Employee(id: '0', name: 'Non assigné', role: 'autre'),
        );
        return _buildTaskCard(task, employee);
      },
    );
  }

  Widget _buildTaskCard(Task task, Employee employee) {
    final bool isOverdue = task.dueDate.isBefore(DateTime.now()) && task.status != 'completed';
    final Color priorityColor = TaskUtils.getPriorityColor(task.priority);
    final IconData priorityIcon = TaskUtils.getPriorityIcon(task.priority);
    final Color statusColor = TaskUtils.getStatusColor(task.status);
    final IconData statusIcon = TaskUtils.getStatusIcon(task.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // En-tête de la carte avec priorité
            Container(
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(priorityIcon, color: priorityColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        TaskUtils.translatePriority(task.priority),
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          TaskUtils.translateStatus(task.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isOverdue ? Colors.red : Colors.black87,
                          ),
                        ),
                      ),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                          const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                          if (task.status != 'completed')
                            const PopupMenuItem(value: 'complete', child: Text('Marquer comme terminé')),
                        ],
                        onSelected: (value) async {
                          switch (value) {
                            case 'edit':
                              _showTaskBottomSheet(task: task);
                              break;
                            case 'delete':
                              _showDeleteConfirmation(task);
                              break;
                            case 'complete':
                              await _taskService.markTaskAsCompleted(task);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tâche marquée comme terminée'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        radius: 16,
                        child: Text(
                          employee.name.isNotEmpty
                              ? employee.name.substring(0, 1).toUpperCase()
                              : "?",
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        employee.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${TaskUtils.translateRole(employee.role)})',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: isOverdue ? Colors.red : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isOverdue ? Colors.red : Colors.grey[600],
                                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${task.dueDate.hour}:${task.dueDate.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          TaskUtils.translateTaskType(task.taskType),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la tâche "${task.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              _taskService.deleteTask(task.id).then((_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tâche supprimée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              }).catchError((error) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${error.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtres',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Statut',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterOption(
                        label: 'Tous',
                        isSelected: _selectedStatusFilter == null,
                        onTap: () {
                          this.setState(() {
                            _selectedStatusFilter = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      _buildFilterOption(
                        label: 'En attente',
                        color: TaskUtils.getStatusColor('pending'),
                        isSelected: _selectedStatusFilter == 'pending',
                        onTap: () {
                          this.setState(() {
                            _selectedStatusFilter = 'pending';
                          });
                          Navigator.pop(context);
                        },
                      ),
                      _buildFilterOption(
                        label: 'En cours',
                        color: TaskUtils.getStatusColor('in_progress'),
                        isSelected: _selectedStatusFilter == 'in_progress',
                        onTap: () {
                          this.setState(() {
                            _selectedStatusFilter = 'in_progress';
                          });
                          Navigator.pop(context);
                        },
                      ),
                      _buildFilterOption(
                        label: 'Terminé',
                        color: TaskUtils.getStatusColor('completed'),
                        isSelected: _selectedStatusFilter == 'completed',
                        onTap: () {
                          this.setState(() {
                            _selectedStatusFilter = 'completed';
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Priorité',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterOption(
                        label: 'Toutes',
                        isSelected: _selectedPriorityFilter == null,
                        onTap: () {
                          this.setState(() {
                            _selectedPriorityFilter = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      _buildFilterOption(
                        label: 'Élevée',
                        color: TaskUtils.getPriorityColor('high'),
                        isSelected: _selectedPriorityFilter == 'high',
                        onTap: () {
                          this.setState(() {
                            _selectedPriorityFilter = 'high';
                          });
                          Navigator.pop(context);
                        },
                      ),
                      _buildFilterOption(
                        label: 'Moyenne',
                        color: TaskUtils.getPriorityColor('medium'),
                        isSelected: _selectedPriorityFilter == 'medium',
                        onTap: () {
                          this.setState(() {
                            _selectedPriorityFilter = 'medium';
                          });
                          Navigator.pop(context);
                        },
                      ),
                      _buildFilterOption(
                        label: 'Basse',
                        color: TaskUtils.getPriorityColor('low'),
                        isSelected: _selectedPriorityFilter == 'low',
                        onTap: () {
                          this.setState(() {
                            _selectedPriorityFilter = 'low';
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        this.setState(() {
                          _selectedStatusFilter = null;
                          _selectedPriorityFilter = null;
                          _selectedEmployeeId = null;
                          _showEmployeeFilter = false;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Réinitialiser tous les filtres'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption({
    required String label,
    Color color = Colors.grey,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// BottomSheet pour le formulaire de tâche
// Voici la modification de la classe TaskFormBottomSheet pour intégrer les templates

class TaskFormBottomSheet extends StatefulWidget {
  final List<Employee> employees;
  final Task? task; // Si task est null, c'est un formulaire de création, sinon c'est une modification
  final TaskService taskService;

  const TaskFormBottomSheet({
    Key? key,
    required this.employees,
    this.task,
    required this.taskService,
  }) : super(key: key);

  @override
  _TaskFormBottomSheetState createState() => _TaskFormBottomSheetState();
}

class _TaskFormBottomSheetState extends State<TaskFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late String _selectedEmployeeId;
  late String _taskType;
  late DateTime _dueDate;
  late String _priority;
  late String _status;
  bool _showTemplateSelector = false;

  @override
  void initState() {
    super.initState();

    if (widget.task != null) {
      // Mode édition
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedEmployeeId = widget.task!.assignedTo;
      _taskType = widget.task!.taskType;
      _dueDate = widget.task!.dueDate;
      _priority = widget.task!.priority;
      _status = widget.task!.status;
    } else {
      // Mode création
      _selectedEmployeeId = widget.employees.isNotEmpty ? widget.employees.first.id : '';
      _taskType = 'autre';
      _dueDate = DateTime.now().add(const Duration(days: 1));
      _priority = 'medium';
      _status = 'pending';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyTemplate(TaskTemplate template) {
    setState(() {
      _titleController.text = template.title;
      _descriptionController.text = template.description;
      _taskType = template.taskType;
      _priority = template.priority;
      _dueDate = DateTime.now().add(template.defaultDuration);
      _showTemplateSelector = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.task != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditMode ? 'Modifier la tâche' : 'Nouvelle tâche',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Bouton pour afficher/masquer les modèles prédéfinis
              if (!isEditMode) // Seulement en mode création
                OutlinedButton.icon(
                  icon: Icon(
                    _showTemplateSelector ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.blue,
                  ),
                  label: Text(
                    _showTemplateSelector ? 'Masquer les modèles' : 'Utiliser un modèle prédéfini',
                    style: const TextStyle(color: Colors.blue),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  onPressed: () {
                    setState(() {
                      _showTemplateSelector = !_showTemplateSelector;
                    });
                  },
                ),

              // Sélecteur de modèles
              if (_showTemplateSelector && !isEditMode)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TaskTemplateSelector(
                    onTemplateSelected: _applyTemplate,
                    initialRole: _getRoleForEmployee(_selectedEmployeeId),
                  ),
                ),

              if (_showTemplateSelector && !isEditMode)
                const Divider(height: 32),

              // Titre
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type de tâche et priorité
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Type de tâche',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _taskType,
                      items: const [
                        DropdownMenuItem(value: 'chambre', child: Text('Service de chambre')),
                        DropdownMenuItem(value: 'service', child: Text('Service restaurant')),
                        DropdownMenuItem(value: 'autre', child: Text('Autre')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _taskType = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Priorité',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _priority,
                      items: [
                        DropdownMenuItem(
                          value: 'high',
                          child: Row(
                            children: [
                              Icon(TaskUtils.getPriorityIcon('high'),
                                  color: TaskUtils.getPriorityColor('high'),
                                  size: 18),
                              const SizedBox(width: 8),
                              const Text('Élevée'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Row(
                            children: [
                              Icon(TaskUtils.getPriorityIcon('medium'),
                                  color: TaskUtils.getPriorityColor('medium'),
                                  size: 18),
                              const SizedBox(width: 8),
                              const Text('Moyenne'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'low',
                          child: Row(
                            children: [
                              Icon(TaskUtils.getPriorityIcon('low'),
                                  color: TaskUtils.getPriorityColor('low'),
                                  size: 18),
                              const SizedBox(width: 8),
                              const Text('Basse'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _priority = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status (seulement en mode édition)
              if (isEditMode)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _status,
                      items: [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Row(
                            children: [
                              Icon(TaskUtils.getStatusIcon('pending'),
                                  color: TaskUtils.getStatusColor('pending'),
                                  size: 18),
                              const SizedBox(width: 8),
                              const Text('En attente'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Row(
                            children: [
                              Icon(TaskUtils.getStatusIcon('in_progress'),
                                  color: TaskUtils.getStatusColor('in_progress'),
                                  size: 18),
                              const SizedBox(width: 8),
                              const Text('En cours'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Row(
                            children: [
                              Icon(TaskUtils.getStatusIcon('completed'),
                                  color: TaskUtils.getStatusColor('completed'),
                                  size: 18),
                              const SizedBox(width: 8),
                              const Text('Terminé'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Employé assigné
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Employé assigné',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: widget.employees.any((e) => e.id == _selectedEmployeeId)
                    ? _selectedEmployeeId
                    : (widget.employees.isNotEmpty ? widget.employees.first.id : null),
                items: widget.employees.map((employee) {
                  return DropdownMenuItem<String>(
                    value: employee.id,
                    child: Text('${employee.name} (${TaskUtils.translateRole(employee.role)})'),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un employé';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedEmployeeId = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date d'échéance
              Card(
                elevation: 0,
                color: Colors.blue.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Échéance',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('dd/MM/yyyy à HH:mm').format(_dueDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.edit_calendar),
                            label: const Text('Modifier'),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _dueDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );

                              if (date != null) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(_dueDate),
                                );

                                if (time != null) {
                                  setState(() {
                                    _dueDate = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Boutons d'action
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _saveTask,
                  child: Text(
                    isEditMode ? 'METTRE À JOUR' : 'CRÉER LA TÂCHE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthode utilitaire pour obtenir le rôle d'un employé à partir de son ID
  String? _getRoleForEmployee(String employeeId) {
    final employee = widget.employees.firstWhere(
          (e) => e.id == employeeId,
      orElse: () => Employee(id: '0', name: 'Non assigné', role: 'autre'),
    );

    // Convertir le rôle en format compatible avec les templates
    switch (employee.role) {
      case 'serveur':
        return 'serveur';
      case 'femme_chambre':
        return 'femme_chambre';
      case 'receptionniste':
        return 'receptionniste';
      case 'maintenance':
        return 'maintenance';
      case 'concierge':
        return 'concierge';
      default:
        return null;
    }
  }

  void _saveTask() {
    // Code existant inchangé...
    if (_formKey.currentState!.validate()) {
      if (widget.task != null) {
        // Mode édition
        final updatedTask = Task(
          id: widget.task!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          dueDate: _dueDate,
          status: _status,
          assignedTo: _selectedEmployeeId,
          taskType: _taskType,
          createdAt: widget.task!.createdAt,
          priority: _priority,
        );

        widget.taskService.updateTask(updatedTask).then((_) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tâche mise à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }).catchError((error) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        });
      } else {
        // Mode création
        final newTask = Task(
          id: '', // L'ID sera généré par Firestore
          title: _titleController.text,
          description: _descriptionController.text,
          dueDate: _dueDate,
          status: 'pending',
          assignedTo: _selectedEmployeeId,
          taskType: _taskType,
          createdAt: DateTime.now(),
          priority: _priority,
        );

        widget.taskService.addTask(newTask).then((_) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tâche ajoutée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }).catchError((error) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    }
  }
}

// BottomSheet pour les détails de tâche
class TaskDetailsBottomSheet extends StatelessWidget {
  final Task task;
  final Employee employee;
  final TaskService taskService;
  final VoidCallback onEdit;

  const TaskDetailsBottomSheet({
    Key? key,
    required this.task,
    required this.employee,
    required this.taskService,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = task.dueDate.isBefore(DateTime.now()) && task.status != 'completed';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Info de priorité et statut
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon: TaskUtils.getPriorityIcon(task.priority),
                    label: TaskUtils.translatePriority(task.priority),
                    color: TaskUtils.getPriorityColor(task.priority),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInfoChip(
                    icon: TaskUtils.getStatusIcon(task.status),
                    label: TaskUtils.translateStatus(task.status),
                    color: TaskUtils.getStatusColor(task.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                task.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Info employé
            const Text(
              'Assigné à',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Text(
                      employee.name.isNotEmpty
                          ? employee.name.substring(0, 1).toUpperCase()
                          : "?",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          TaskUtils.translateRole(employee.role),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Date et heure
            const Text(
              'Échéance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                        style: TextStyle(
                          fontSize: 15,
                          color: isOverdue ? Colors.red : Colors.grey[800],
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${task.dueDate.hour}:${task.dueDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  if (isOverdue && task.status != 'completed')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Cette tâche est en retard!',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Informations additionnelles
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Type de tâche',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          TaskUtils.translateTaskType(task.taskType),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date de création',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
                          style: TextStyle(
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Boutons d'action
            Row(
              children: [
                if (task.status != 'completed')
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        taskService.markTaskAsCompleted(task).then((_) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tâche marquée comme terminée'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        });
                      },
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text(
                        'MARQUER TERMINÉ',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (task.status != 'completed')
                  const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'MODIFIER',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// Écran principal de l'application
class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestionnaire de Tâches',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      home: const TaskManagementPage(),
    );
  }
}

// Point d'entrée principal de l'application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ici, normalement, on initialiserait Firebase:
  // await Firebase.initializeApp();
  runApp(const TaskManagerApp());
}