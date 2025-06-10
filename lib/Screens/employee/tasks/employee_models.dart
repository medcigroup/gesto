import 'package:flutter/material.dart';

// Modèle pour les tâches côté employé
class EmployeeTask {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  String status; // 'pending', 'in_progress', 'completed'
  final String taskType; // 'chambre', 'service', 'autre'
  final String priority; // 'high', 'medium', 'low'
  final DateTime createdAt;
  final String createdBy; // ID de l'admin qui a créé la tâche

  EmployeeTask({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.taskType,
    required this.priority,
    required this.createdAt,
    required this.createdBy,
  });

  // Créer une copie de la tâche avec des modifications
  EmployeeTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    String? taskType,
    String? priority,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return EmployeeTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      taskType: taskType ?? this.taskType,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Convertir un Map en EmployeeTask
  factory EmployeeTask.fromJson(Map<String, dynamic> json) {
    return EmployeeTask(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      status: json['status'],
      taskType: json['taskType'],
      priority: json['priority'],
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
    );
  }

  // Convertir EmployeeTask en Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'taskType': taskType,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}

// Utilitaires pour les tâches employé
class EmployeeTaskUtils {
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

  static String getStatusCode(String frenchStatus) {
    switch (frenchStatus) {
      case 'En attente':
        return 'pending';
      case 'En cours':
        return 'in_progress';
      case 'Terminé':
        return 'completed';
      default:
        return 'pending';
    }
  }

  static String translatePriority(String priority) {
    switch (priority) {
      case 'high':
        return 'Haute';
      case 'medium':
        return 'Normale';
      case 'low':
        return 'Basse';
      default:
        return 'Normale';
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