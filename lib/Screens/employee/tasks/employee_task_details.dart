import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'employee_models.dart';
import 'employee_service.dart';

class EmployeeTaskDetailsBottomSheet extends StatelessWidget {
  final EmployeeTask task;
  final Function onStatusChange;

  const EmployeeTaskDetailsBottomSheet({
    Key? key,
    required this.task,
    required this.onStatusChange,
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
                    icon: EmployeeTaskUtils.getPriorityIcon(task.priority),
                    label: EmployeeTaskUtils.translatePriority(task.priority),
                    color: EmployeeTaskUtils.getPriorityColor(task.priority),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInfoChip(
                    icon: EmployeeTaskUtils.getStatusIcon(task.status),
                    label: EmployeeTaskUtils.translateStatus(task.status),
                    color: EmployeeTaskUtils.getStatusColor(task.status),
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
                        DateFormat('dd/MM/yyyy').format(task.dueDate),
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
                        DateFormat('HH:mm').format(task.dueDate),
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
                          EmployeeTaskUtils.translateTaskType(task.taskType),
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
                          DateFormat('dd/MM/yyyy').format(task.createdAt),
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

            // Boutons d'action pour changer le statut
            if (task.status != 'completed')
              SizedBox(
                width: double.infinity,
                child: task.status == 'pending'
                    ? ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onStatusChange(task.id, 'in_progress');
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    'COMMENCER LA TÂCHE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
                    : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onStatusChange(task.id, 'completed');
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'MARQUER COMME TERMINÉ',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (task.status == 'completed')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Cette tâche est terminée',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
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