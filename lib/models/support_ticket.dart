import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketPriority {
  low,
  medium,
  high,
  urgent
}

enum TicketStatus {
  open,
  inProgress,
  waiting,
  resolved,
  closed
}

enum TicketCategory {
  bug,
  feature,
  question,
  feedback,
  other
}

class SupportTicket {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String subject;
  final String description;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final String? assignedTo;
  final List<String> attachmentUrls;
  final List<TicketMessage> messages;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.subject,
    required this.description,
    required this.category,
    this.priority = TicketPriority.medium,
    this.status = TicketStatus.open,
    required this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.assignedTo,
    this.attachmentUrls = const [],
    this.messages = const [],
  });

  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportTicket(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      category: TicketCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => TicketCategory.other,
      ),
      priority: TicketPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => TicketPriority.medium,
      ),
      status: TicketStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TicketStatus.open,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      closedAt: data['closedAt'] != null 
          ? (data['closedAt'] as Timestamp).toDate() 
          : null,
      assignedTo: data['assignedTo'],
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      messages: (data['messages'] as List<dynamic>?)
              ?.map((m) => TicketMessage.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'subject': subject,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      'assignedTo': assignedTo,
      'attachmentUrls': attachmentUrls,
      'messages': messages.map((m) => m.toMap()).toList(),
    };
  }

  SupportTicket copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? subject,
    String? description,
    TicketCategory? category,
    TicketPriority? priority,
    TicketStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
    String? assignedTo,
    List<String>? attachmentUrls,
    List<TicketMessage>? messages,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      messages: messages ?? this.messages,
    );
  }
}

class TicketMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final bool isAdmin;
  final String message;
  final DateTime timestamp;
  final List<String> attachmentUrls;

  TicketMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.isAdmin,
    required this.message,
    required this.timestamp,
    this.attachmentUrls = const [],
  });

  factory TicketMessage.fromMap(Map<String, dynamic> data) {
    return TicketMessage(
      id: data['id'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderEmail: data['senderEmail'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'isAdmin': isAdmin,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'attachmentUrls': attachmentUrls,
    };
  }
}
