import 'package:cloud_firestore/cloud_firestore.dart'; // Importez cloud_firestore

class UserModel {
  final String createdAt;
  final String email;
  final String employeeCount;
  final String establishmentAddress;
  final String establishmentName;
  final String establishmentType;
  final String fullName;
  final String phone;
  final String plan;
  final String planExpiryDate;
  final String planStartDate;
  final String userRole;

  UserModel({
    required this.createdAt,
    required this.email,
    required this.employeeCount,
    required this.establishmentAddress,
    required this.establishmentName,
    required this.establishmentType,
    required this.fullName,
    required this.phone,
    required this.plan,
    required this.planExpiryDate,
    required this.planStartDate,
    required this.userRole,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      createdAt: (json['createdAt'] as Timestamp).toDate().toIso8601String(), // Conversion de Timestamp
      email: json['email'] as String,
      employeeCount: json['employeeCount'] as String,
      establishmentAddress: json['establishmentAddress'] as String,
      establishmentName: json['establishmentName'] as String,
      establishmentType: json['establishmentType'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      plan: json['plan'] as String,
      planExpiryDate: (json['planExpiryDate'] as Timestamp).toDate().toIso8601String(), // Conversion de Timestamp
      planStartDate: (json['planStartDate'] as Timestamp).toDate().toIso8601String(), // Conversion de Timestamp
      userRole: json['userRole'] as String,
    );
  }
}