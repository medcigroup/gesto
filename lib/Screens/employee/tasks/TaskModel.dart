class TaskModel {
  final String title;
  final String status;  // 'En attente', 'En cours', 'Terminée'
  final String priority; // 'Haute', 'Normale', 'Basse'
  final String dueTime;
  final String? description;
  final String? assignee;
  final String? location;

  TaskModel({
    required this.title,
    required this.status,
    required this.priority,
    required this.dueTime,
    this.description,
    this.assignee,
    this.location,
  });

  // Factory constructor pour convertir un Map en TaskModel
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      title: json['title'] ?? '',
      status: json['status'] ?? 'En attente',
      priority: json['priority'] ?? 'Normale',
      dueTime: json['dueTime'] ?? '',
      description: json['description'],
      assignee: json['assignee'],
      location: json['location'],
    );
  }

  // Convertir le TaskModel en Map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'status': status,
      'priority': priority,
      'dueTime': dueTime,
      'description': description,
      'assignee': assignee,
      'location': location,
    };
  }
}