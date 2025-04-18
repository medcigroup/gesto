class MessageModel {
  final String from;
  final String content;
  final String time;
  final bool read;
  final String? id;
  final String? subject;
  final DateTime? dateTime;

  MessageModel({
    required this.from,
    required this.content,
    required this.time,
    required this.read,
    this.id,
    this.subject,
    this.dateTime,
  });

  // Factory constructor pour convertir un Map en MessageModel
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      from: json['from'] ?? '',
      content: json['content'] ?? '',
      time: json['time'] ?? '',
      read: json['read'] ?? false,
      id: json['id'],
      subject: json['subject'],
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'])
          : null,
    );
  }

  // Convertir le MessageModel en Map
  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'content': content,
      'time': time,
      'read': read,
      'id': id,
      'subject': subject,
      'dateTime': dateTime?.toIso8601String(),
    };
  }
}