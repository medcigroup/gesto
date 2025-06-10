import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StaffMember {
  final String id;
  final String name;
  final String position;
  final String? photoUrl;

  StaffMember({
    required this.id,
    required this.name,
    required this.position,
    this.photoUrl,
  });

  factory StaffMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return StaffMember(
      id: doc.id,
      name: data['nom'] ?? 'Personnel inconnu',
      position: data['poste'] ?? 'Poste non spécifié',
      photoUrl: data['photoUrl'],
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String assignedTo;
  final String createdBy;
  final DateTime dueDate;
  final DateTime createdAt;
  final String priority;
  final String status;
  final String taskType;
  final Color priorityColor;
  final bool isCompleted;
  StaffMember? assignee;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.createdBy,
    required this.dueDate,
    required this.createdAt,
    required this.priority,
    required this.status,
    required this.taskType,
    required this.priorityColor,
    this.isCompleted = false,
    this.assignee,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Déterminer la couleur de priorité
    Color priorityColor = Colors.green;
    if (data['priority'] == 'high') {
      priorityColor = Colors.red;
    } else if (data['priority'] == 'medium') {
      priorityColor = Colors.orange;
    }

    // Déterminer si la tâche est complétée
    bool isCompleted = data['status'] == 'completed';

    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      createdBy: data['createdBy'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      priority: data['priority'] ?? 'low',
      status: data['status'] ?? 'pending',
      taskType: data['taskType'] ?? '',
      priorityColor: priorityColor,
      isCompleted: isCompleted,
    );
  }
}

class TasksList extends StatefulWidget {
  const TasksList({Key? key}) : super(key: key);

  @override
  State<TasksList> createState() => _TasksListState();
}

class _TasksListState extends State<TasksList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, StaffMember> _staffCache = {};
  bool _isLoading = true;
  String? _errorMessage;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Récupérer l'ID de l'utilisateur actuel
      final String? currentUserId = _auth.currentUser?.uid;

      if (currentUserId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Aucun utilisateur connecté";
          _tasks = [];
        });
        return;
      }

      // Récupérer toutes les tâches créées par l'utilisateur actuel
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('createdBy', isEqualTo: currentUserId)
          .limit(4)
          .get();

      final tasks = tasksSnapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();

      // Récupérer les informations des employés pour chaque tâche
      final Set<String> staffIds = tasks.map((task) => task.assignedTo).toSet();

      // Récupérer les informations des employés en batch
      for (final staffId in staffIds) {
        if (staffId.isNotEmpty && !_staffCache.containsKey(staffId)) {
          try {
            final staffDoc = await _firestore.collection('staff').doc(staffId).get();
            if (staffDoc.exists) {
              _staffCache[staffId] = StaffMember.fromFirestore(staffDoc);
            }
          } catch (e) {
            print('Erreur lors de la récupération de l\'employé $staffId: $e');
          }
        }
      }

      // Associer chaque tâche à son assigné
      for (final task in tasks) {
        if (task.assignedTo.isNotEmpty && _staffCache.containsKey(task.assignedTo)) {
          task.assignee = _staffCache[task.assignedTo];
        }
      }

      // Trier les tâches: non complétées d'abord, puis par priorité
      tasks.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }

        // Pour les tâches non complétées, trier par priorité
        final priorityRank = {
          "high": 0,
          "medium": 1,
          "low": 2,
        };

        return priorityRank[a.priority]!.compareTo(priorityRank[b.priority]!);
      });

      setState(() {
        _isLoading = false;
        _tasks = tasks;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Erreur: $e";
        _tasks = [];
      });
      print('Erreur lors du chargement des tâches: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tâches",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
                ),
              ),
              Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        _loadTasks();
                      }
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      // Implémenter le filtrage des tâches
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(child: Text(_errorMessage!))
          else if (_tasks.isEmpty)
              const Center(child: Text('Aucune tâche trouvée'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tasks.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: task.isCompleted,
                          onChanged: (value) {
                            // Mettre à jour le statut de la tâche dans Firestore
                            _firestore.collection('tasks').doc(task.id).update({
                              'status': value == true ? 'completed' : 'pending',
                            }).then((_) {
                              // Recharger les tâches après la mise à jour
                              _loadTasks();
                            });
                          },
                          activeColor: const Color(0xFF000080), // bleu marine
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.isCompleted
                                      ? (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[500]
                                      : Colors.grey[600])
                                      : (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.grey[800]),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                task.description,
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Type: ${_formatTaskType(task.taskType)}",
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.assignee != null
                                        ? "${task.assignee!.name} (${task.assignee!.position})"
                                        : "Employé inconnu",
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Créé le: ${DateFormat('dd/MM/yyyy à HH:mm').format(task.createdAt)}",
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: task.priorityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatPriority(task.priority),
                                style: TextStyle(
                                  color: task.priorityColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDueTime(task.dueDate, isCompleted: task.isCompleted),
                              style: TextStyle(
                                color: _getDueTimeColor(task.dueDate, context, isCompleted: task.isCompleted),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }

  // Méthode pour formater le niveau de priorité
  String _formatPriority(String priority) {
    switch (priority) {
      case 'high':
        return 'Élevée';
      case 'medium':
        return 'Moyenne';
      case 'low':
        return 'Faible';
      default:
        return 'Normale';
    }
  }

  // Méthode pour formater le type de tâche
  String _formatTaskType(String taskType) {
    switch (taskType) {
      case 'cleaning':
        return 'Nettoyage';
      case 'maintenance':
        return 'Maintenance';
      case 'service':
        return 'Service';
      case 'reception':
        return 'Réception';
      default:
        return taskType;
    }
  }

  // Méthode pour formater le temps restant
  String _formatDueTime(DateTime dueDate, {bool isCompleted = false}) {
    // Si la tâche est complétée, afficher "Complété" indépendamment de la date d'échéance
    if (isCompleted) {
      return "Complété";
    }

    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return "En retard";
    } else if (difference.inHours < 1) {
      return "Prévu dans ${difference.inMinutes} mins";
    } else if (difference.inHours < 24) {
      return "Prévu dans ${difference.inHours} hrs";
    } else {
      return "Prévu dans ${difference.inDays} jours";
    }
  }

  // Méthode pour obtenir la couleur en fonction du temps restant
  Color _getDueTimeColor(DateTime dueDate, BuildContext context, {bool isCompleted = false}) {
    // Si la tâche est complétée, utiliser une couleur verte
    if (isCompleted) {
      return Colors.green;
    }

    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return Colors.red;
    } else if (difference.inHours < 3) {
      return Colors.orange;
    } else {
      return Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[400]!
          : Colors.grey[600]!;
    }
  }
}