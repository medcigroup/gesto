import 'package:cloud_firestore/cloud_firestore.dart';

enum RoadmapStatus {
  planned,
  inProgress,
  completed,
  cancelled
}

enum RoadmapPriority {
  low,
  medium,
  high
}

class RoadmapItem {
  final String id;
  final String title;
  final String description;
  final RoadmapStatus status;
  final RoadmapPriority priority;
  final DateTime createdAt;
  final DateTime? estimatedDate;
  final DateTime? completedAt;
  final String category;
  final List<String> tags;
  final int votesCount;
  final List<String> voters;

  RoadmapItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.estimatedDate,
    this.completedAt,
    this.category = 'Général',
    this.tags = const [],
    this.votesCount = 0,
    this.voters = const [],
  });

  factory RoadmapItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoadmapItem(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: RoadmapStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RoadmapStatus.planned,
      ),
      priority: RoadmapPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => RoadmapPriority.medium,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      estimatedDate: data['estimatedDate'] != null 
          ? (data['estimatedDate'] as Timestamp).toDate() 
          : null,
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      category: data['category'] ?? 'Général',
      tags: List<String>.from(data['tags'] ?? []),
      votesCount: data['votesCount'] ?? 0,
      voters: List<String>.from(data['voters'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'estimatedDate': estimatedDate != null ? Timestamp.fromDate(estimatedDate!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'category': category,
      'tags': tags,
      'votesCount': votesCount,
      'voters': voters,
    };
  }

  RoadmapItem copyWith({
    String? id,
    String? title,
    String? description,
    RoadmapStatus? status,
    RoadmapPriority? priority,
    DateTime? createdAt,
    DateTime? estimatedDate,
    DateTime? completedAt,
    String? category,
    List<String>? tags,
    int? votesCount,
    List<String>? voters,
  }) {
    return RoadmapItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      estimatedDate: estimatedDate ?? this.estimatedDate,
      completedAt: completedAt ?? this.completedAt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      votesCount: votesCount ?? this.votesCount,
      voters: voters ?? this.voters,
    );
  }
}
