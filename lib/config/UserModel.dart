import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final Timestamp? createdAt;
  final String email;
  final String employeeCount;
  final String establishmentAddress;
  final String establishmentName;
  final String establishmentType;
  final String fullName;
  final String phone;
  final String plan;
  final Timestamp? planExpiryDate;
  final Timestamp? licenceGenerationDate; // Remplacement de planStartDate
  final String userRole;
  final Timestamp? licenceExpiryDate;
  String licence;

  UserModel({
    this.createdAt,
    required this.email,
    required this.employeeCount,
    required this.establishmentAddress,
    required this.establishmentName,
    required this.establishmentType,
    required this.fullName,
    required this.phone,
    required this.plan,
    this.planExpiryDate,
    this.licenceGenerationDate, // Remplacement de planStartDate
    required this.userRole,
    this.licenceExpiryDate,
    this.licence = '',

  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      createdAt: json['createdAt'] as Timestamp?,
      email: json['email'] as String,
      employeeCount: json['employeeCount'] as String,
      establishmentAddress: json['establishmentAddress'] as String,
      establishmentName: json['establishmentName'] as String,
      establishmentType: json['establishmentType'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      plan: json['licenceType'] as String,
      planExpiryDate: json['planExpiryDate'] as Timestamp?,
      licenceGenerationDate: json['licenceGenerationDate'] as Timestamp?, // Remplacement de planStartDate
      userRole: json['userRole'] as String,
      licence: json['licence'] as String,
      licenceExpiryDate: json['licenceExpiryDate'] as Timestamp?,
    );
  }
}