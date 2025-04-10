import 'package:flutter/material.dart';

class Task {
  final String title;
  final String assignee;
  final DateTime dueDate;
  final String priority;
  final Color priorityColor;
  final bool isCompleted;

  Task({
    required this.title,
    required this.assignee,
    required this.dueDate,
    required this.priority,
    required this.priorityColor,
    this.isCompleted = false,
  });
}

class TasksList extends StatefulWidget {
  const TasksList({Key? key}) : super(key: key);

  @override
  State<TasksList> createState() => _TasksListState();
}

class _TasksListState extends State<TasksList> {
  // Sample data - replace with your actual data
  final List<Task> tasks = [
    Task(
      title: "Nettoyer la chambre 302",
      assignee: "Service d'entretien ménager",
      dueDate: DateTime.now().add(const Duration(hours: 2)),
      priority: "Élevée",
      priorityColor: Colors.red,
    ),
    Task(
      title: "Réapprovisionner le mini-bar de la chambre 205",
      assignee: "Service de chambre",
      dueDate: DateTime.now().add(const Duration(hours: 4)),
      priority: "Moyenne",
      priorityColor: Colors.orange,
    ),
    Task(
      title: "Préparer le paquet de bienvenue pour le client VIP",
      assignee: "Réception",
      dueDate: DateTime.now().add(const Duration(hours: 1)),
      priority: "Élevée",
      priorityColor: Colors.red,
    ),
    Task(
      title: "Réparer la climatisation de la chambre 118",
      assignee: "Maintenance",
      dueDate: DateTime.now().add(const Duration(hours: 3)),
      priority: "Moyenne",
      priorityColor: Colors.orange,
    ),
    Task(
      title: "Maintenance hebdomadaire de la piscine",
      assignee: "Maintenance",
      dueDate: DateTime.now().add(const Duration(hours: 6)),
      priority: "Faible",
      priorityColor: Colors.green,
      isCompleted: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Sort tasks: incomplete first, then by priority
    final sortedTasks = List<Task>.from(tasks)
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }

        // For uncompleted tasks, sort by priority
        final priorityRank = {
          "Élevée": 0,
          "Moyenne": 1,
          "Faible": 2,
        };

        return priorityRank[a.priority]!.compareTo(priorityRank[b.priority]!);
      });

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
                "Taches",
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
                    onPressed:() {}
                  ),
                  IconButton(
                    icon: const Icon(Icons.list),
                    onPressed: () {

                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedTasks.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final task = sortedTasks[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: task.isCompleted,
                      onChanged: (value) {
                        // In a real app, update the task status here
                      },
                      activeColor: const Color(0xFF000080), // navy
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
                          Text(
                            "Assigned to: ${task.assignee}",
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 14,
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
                            task.priority,
                            style: TextStyle(
                              color: task.priorityColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDueTime(task.dueDate),
                          style: TextStyle(
                            color: _getDueTimeColor(task.dueDate, context),
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

  // Helper method to format due time
  String _formatDueTime(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return "en retard";
    } else if (difference.inHours < 1) {
      return "prévu pour ${difference.inMinutes} mins";
    } else if (difference.inHours < 24) {
      return "prévu pour ${difference.inHours} hrs";
    } else {
      return "prévu pour ${difference.inDays} Jours";
    }
  }

  // Helper method to get color based on due time
  Color _getDueTimeColor(DateTime dueDate, BuildContext context) {
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