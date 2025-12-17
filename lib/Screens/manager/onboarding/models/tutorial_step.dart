import 'dart:ui';
import 'package:flutter/material.dart';

class TutorialStep {
  final String id;
  final String title;
  final String description;
  final String? icon;
  final Widget? targetWidget;
  final GlobalKey? targetKey;
  final TutorialPosition position;
  final Color? color;
  final List<String>? actions;
  final int? pageIndex; // Index de la page à afficher

  TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    this.icon,
    this.targetWidget,
    this.targetKey,
    this.position = TutorialPosition.bottom,
    this.color,
    this.actions,
    this.pageIndex,
  });
}

enum TutorialPosition {
  top,
  bottom,
  left,
  right,
  center
}


class UserTutorialProgress {
  final String userId;
  final String tutorialId;
  final List<String> completedSteps;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime lastUpdated;

  UserTutorialProgress({
    required this.userId,
    required this.tutorialId,
    this.completedSteps = const [],
    this.isCompleted = false,
    this.completedAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tutorialId': tutorialId,
      'completedSteps': completedSteps,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserTutorialProgress.fromMap(Map<String, dynamic> map) {
    return UserTutorialProgress(
      userId: map['userId'],
      tutorialId: map['tutorialId'],
      completedSteps: List<String>.from(map['completedSteps'] ?? []),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}