import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';
import 'TaskModel.dart';


class TaskCard extends StatelessWidget {
  final TaskModel task;
  final Function()? onTap;

  const TaskCard({
    Key? key,
    required this.task,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (task.status) {
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
    switch (task.priority) {
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

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(task.dueTime, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Priorité ${task.priority}',
                    style: TextStyle(color: priorityColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: onTap ?? () {
          // Navigation vers les détails de la tâche
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Détails de la tâche: ${task.title}')),
          );
        },
      ),
    );
  }
}