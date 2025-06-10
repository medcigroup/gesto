import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'employee_models.dart';
import 'employee_service.dart';

class EmployeeTaskCard extends StatelessWidget {
  final EmployeeTask task;
  final Function onStatusChange;
  final Function onTaskTap;

  const EmployeeTaskCard({
    Key? key,
    required this.task,
    required this.onStatusChange,
    required this.onTaskTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = task.dueDate.isBefore(DateTime.now()) && task.status != 'completed';
    final Color priorityColor = EmployeeTaskUtils.getPriorityColor(task.priority);
    final IconData priorityIcon = EmployeeTaskUtils.getPriorityIcon(task.priority);
    final Color statusColor = EmployeeTaskUtils.getStatusColor(task.status);
    final IconData statusIcon = EmployeeTaskUtils.getStatusIcon(task.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onTaskTap(task),
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
                        EmployeeTaskUtils.translatePriority(task.priority),
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
                          EmployeeTaskUtils.translateStatus(task.status),
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
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? Colors.red : Colors.black87,
                    ),
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
                                DateFormat('dd/MM/yyyy').format(task.dueDate),
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
                              DateFormat('HH:mm').format(task.dueDate),
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
                          EmployeeTaskUtils.translateTaskType(task.taskType),
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

            // Boutons d'action pour changer le statut
            if (task.status != 'completed')
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (task.status == 'pending')
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.play_arrow, color: Colors.blue),
                          label: const Text('Commencer', style: TextStyle(color: Colors.blue)),
                          onPressed: () => onStatusChange(task.id, 'in_progress'),
                        ),
                      ),
                    if (task.status == 'in_progress')
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          label: const Text('Terminer', style: TextStyle(color: Colors.green)),
                          onPressed: () => onStatusChange(task.id, 'completed'),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}