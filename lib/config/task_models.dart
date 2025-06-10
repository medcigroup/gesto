
import 'package:flutter/material.dart';

// Modèle pour les employés
class Employee {
  final String id;
  final String name;
  final String role; // 'femme_de_chambre', 'serveur', 'autre'

  Employee({
    required this.id,
    required this.name,
    required this.role,
  });

  // Convertir l'employé en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
    };
  }

  // Créer un employé à partir de JSON
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name'],
      role: json['role'],
    );
  }
}

// Modèle pour les tâches


// Utilitaires pour les traductions
class TaskUtils {
  static String translateStatus(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }

  static String translatePriority(String priority) {
    switch (priority) {
      case 'high':
        return 'Élevée';
      case 'medium':
        return 'Moyenne';
      case 'low':
        return 'Basse';
      default:
        return 'Moyenne';
    }
  }

  static String translateRole(String role) {
    switch (role) {
      case 'Femme_de_chambre':
        return 'Femme de chambre';
      case 'Serveur':
        return 'Serveur';
      case 'Réceptionniste':
        return 'Réceptionniste';
      case 'Chef':
        return 'Chef cuisine';
      case 'manager':
        return 'Manager';
      default:
        return 'Autre';
    }
  }

  static String translateTaskType(String taskType) {
    switch (taskType) {
      case 'chambre':
        return 'Chambre';
      case 'service':
        return 'Service';
      default:
        return 'Autre';
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  static IconData getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.equalizer;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.equalizer;
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'in_progress':
        return Icons.hourglass_bottom;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status; // 'pending', 'in_progress', 'completed'
  final String assignedTo;
  final String taskType; // 'chambre', 'service', 'autre'
  final DateTime createdAt;
  final String priority; // 'high', 'medium', 'low'

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.assignedTo,
    required this.taskType,
    required this.createdAt,
    required this.priority,
  });

  // Convertir la tâche en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'assignedTo': assignedTo,
      'taskType': taskType,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
    };
  }

  // Créer une tâche à partir de JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      status: json['status'],
      assignedTo: json['assignedTo'],
      taskType: json['taskType'],
      createdAt: DateTime.parse(json['createdAt']),
      priority: json['priority'] ?? 'medium',
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    String? assignedTo,
    String? taskType,
    DateTime? createdAt,
    String? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      taskType: taskType ?? this.taskType,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
    );
  }
}