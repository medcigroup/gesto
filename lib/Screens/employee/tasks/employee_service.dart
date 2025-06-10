import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'employee_models.dart';

class EmployeeTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir l'ID de l'employé connecté
  String? get currentEmployeeId => _auth.currentUser?.uid;

  // Référence à la collection des tâches
  CollectionReference get tasksCollection => _firestore.collection('tasks');

  // Obtenir les tâches assignées à l'employé connecté
  Stream<List<EmployeeTask>> getTasksForCurrentEmployee() {
    if (currentEmployeeId == null) {
      return Stream.value([]);
    }

    return tasksCollection
        .where('assignedTo', isEqualTo: currentEmployeeId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Convertir Timestamp en DateTime
        final timestamp = data['dueDate'] as Timestamp?;
        final DateTime dueDate = timestamp != null
            ? timestamp.toDate()
            : DateTime.now();

        final createdTimestamp = data['createdAt'] as Timestamp?;
        final DateTime createdAt = createdTimestamp != null
            ? createdTimestamp.toDate()
            : DateTime.now();

        return EmployeeTask(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          dueDate: dueDate,
          status: data['status'] ?? 'pending',
          taskType: data['taskType'] ?? 'autre',
          priority: data['priority'] ?? 'medium',
          createdAt: createdAt,
          createdBy: data['createdBy'] ?? '',
        );
      }).toList();
    });
  }

  // Mettre à jour le statut d'une tâche
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await tasksCollection.doc(taskId).update({
      'status': newStatus,
    });
  }

  // Obtenir les tâches pour une date spécifique
  Stream<List<EmployeeTask>> getTasksForDate(DateTime date) {
    if (currentEmployeeId == null) {
      return Stream.value([]);
    }

    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return tasksCollection
        .where('assignedTo', isEqualTo: currentEmployeeId)
        .where('dueDate', isGreaterThanOrEqualTo: startOfDay)
        .where('dueDate', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Convertir Timestamp en DateTime
        final timestamp = data['dueDate'] as Timestamp?;
        final DateTime dueDate = timestamp != null
            ? timestamp.toDate()
            : DateTime.now();

        final createdTimestamp = data['createdAt'] as Timestamp?;
        final DateTime createdAt = createdTimestamp != null
            ? createdTimestamp.toDate()
            : DateTime.now();

        return EmployeeTask(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          dueDate: dueDate,
          status: data['status'] ?? 'pending',
          taskType: data['taskType'] ?? 'autre',
          priority: data['priority'] ?? 'medium',
          createdAt: createdAt,
          createdBy: data['createdBy'] ?? '',
        );
      }).toList();
    });
  }

  // Obtenir les statistiques des tâches pour l'employé
  Future<Map<String, int>> getTaskStats() async {
    if (currentEmployeeId == null) {
      return {
        'pending': 0,
        'in_progress': 0,
        'completed': 0,
        'total': 0,
      };
    }

    final pendingSnapshot = await tasksCollection
        .where('assignedTo', isEqualTo: currentEmployeeId)
        .where('status', isEqualTo: 'pending')
        .get();

    final inProgressSnapshot = await tasksCollection
        .where('assignedTo', isEqualTo: currentEmployeeId)
        .where('status', isEqualTo: 'in_progress')
        .get();

    final completedSnapshot = await tasksCollection
        .where('assignedTo', isEqualTo: currentEmployeeId)
        .where('status', isEqualTo: 'completed')
        .get();

    final totalSnapshot = await tasksCollection
        .where('assignedTo', isEqualTo: currentEmployeeId)
        .get();

    return {
      'pending': pendingSnapshot.docs.length,
      'in_progress': inProgressSnapshot.docs.length,
      'completed': completedSnapshot.docs.length,
      'total': totalSnapshot.docs.length,
    };
  }
}