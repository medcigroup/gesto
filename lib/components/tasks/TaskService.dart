import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/getConnectedUserAdminId.dart';
import '../../config/task_models.dart';

// Classe pour gérer les données des tâches et employés (utilisant Firebase)
class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Future to hold the admin ID
  late Future<String?> _adminIdFuture;

  // Constructor that initializes the admin ID
  TaskService() {
    _adminIdFuture = getConnectedUserAdminId();
  }

  // Référence à la collection du personnel
  CollectionReference get staffCollection => _firestore.collection('staff');

  // Référence à la collection des tâches
  CollectionReference get tasksCollection => _firestore.collection('tasks');

  // Récupérer tout le personnel associé à l'admin connecté
  Stream<List<Employee>> getStaffForCurrentAdmin() {
    return _adminIdFuture.asStream().asyncExpand((adminId) {
      if (adminId == null) {
        return Stream.value([]);
      }

      return staffCollection
          .where('idadmin', isEqualTo: adminId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Concaténer le nom et le prénom pour former le nom complet
          final String nom = data['nom'] ?? '';
          final String prenom = data['prenom'] ?? '';
          final String fullName = '$prenom $nom'.trim();

          return Employee(
            id: doc.id,
            name: fullName.isNotEmpty ? fullName : 'Sans nom',
            role: data['poste'] ?? 'autre',
          );
        }).toList();
      });
    });
  }

  // Method to get the current admin ID (can be used elsewhere in the class)
  Future<String?> getCurrentAdminId() {
    return _adminIdFuture;
  }

  // Ajouter une tâche
  Future<void> addTask(Task task) async {
    final String? adminId = await _adminIdFuture;
    if (adminId == null) return;

    await tasksCollection.add({
      'title': task.title,
      'description': task.description,
      'dueDate': task.dueDate,
      'status': task.status,
      'assignedTo': task.assignedTo,
      'taskType': task.taskType,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': adminId,
      'priority': task.priority,
    });
  }

  // Mettre à jour une tâche
  Future<void> updateTask(Task updatedTask) async {
    await tasksCollection.doc(updatedTask.id).update({
      'title': updatedTask.title,
      'description': updatedTask.description,
      'dueDate': updatedTask.dueDate,
      'status': updatedTask.status,
      'assignedTo': updatedTask.assignedTo,
      'taskType': updatedTask.taskType,
      'priority': updatedTask.priority,
    });
  }

  // Supprimer une tâche
  Future<void> deleteTask(String taskId) async {
    await tasksCollection.doc(taskId).delete();
  }

  // Marquer une tâche comme terminée
  Future<void> markTaskAsCompleted(Task task) async {
    await tasksCollection.doc(task.id).update({
      'status': 'completed',
    });
  }

  // Obtenir les tâches créées par l'admin courant
  Stream<List<Task>> getTasksForCurrentAdmin() {
    return _adminIdFuture.asStream().asyncExpand((adminId) {
      if (adminId == null) {
        return Stream.value([]);
      }

      return tasksCollection
          .where('createdBy', isEqualTo: adminId)
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

          return Task(
            id: doc.id,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            dueDate: dueDate,
            status: data['status'] ?? 'pending',
            assignedTo: data['assignedTo'] ?? '',
            taskType: data['taskType'] ?? 'autre',
            createdAt: createdAt,
            priority: data['priority'] ?? 'medium',
          );
        }).toList();
      });
    });
  }

  // Obtenir les tâches par employé
  Stream<List<Task>> getTasksByEmployee(String employeeId) {
    return _adminIdFuture.asStream().asyncExpand((adminId) {
      if (adminId == null) {
        return Stream.value([]);
      }

      return tasksCollection
          .where('createdBy', isEqualTo: adminId)
          .where('assignedTo', isEqualTo: employeeId)
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

          return Task(
            id: doc.id,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            dueDate: dueDate,
            status: data['status'] ?? 'pending',
            assignedTo: data['assignedTo'] ?? '',
            taskType: data['taskType'] ?? 'autre',
            createdAt: createdAt,
            priority: data['priority'] ?? 'medium',
          );
        }).toList();
      });
    });
  }
}