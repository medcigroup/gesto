// services/tutorial_service.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Ou votre backend
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tutorial_step.dart';

class TutorialService {
  static const String _tutorialCompletedKey = 'tutorial_completed_';
  static const String _tutorialProgressKey = 'tutorial_progress_';

  final SharedPreferences _prefs;
  final FirebaseFirestore? _firestore;

  TutorialService(this._prefs, {FirebaseFirestore? firestore}) : _firestore = firestore;

  // Vérifier si l'utilisateur a déjà complété le tutoriel
  Future<bool> hasCompletedTutorial(String userId, String tutorialId) async {
    try {
      // Vérifier d'abord en local
      final localKey = '$_tutorialCompletedKey$userId-$tutorialId';
      final localCompleted = _prefs.getBool(localKey) ?? false;

      if (localCompleted) return true;

      // Vérifier sur le backend si disponible
      if (_firestore != null) {
        final doc = await _firestore!
            .collection('userTutorials')
            .doc('$userId-$tutorialId')
            .get();

        if (doc.exists) {
          final progress = UserTutorialProgress.fromMap(doc.data()!);
          return progress.isCompleted;
        }
      }

      return false;
    } catch (e) {
      print('Erreur vérification tutoriel: $e');
      return false;
    }
  }

  // Marquer une étape comme complétée
  Future<void> completeStep(String userId, String tutorialId, String stepId) async {
    try {
      // Sauvegarder en local
      final progressKey = '$_tutorialProgressKey$userId-$tutorialId';
      final List<String> completedSteps = _prefs.getStringList(progressKey) ?? [];

      if (!completedSteps.contains(stepId)) {
        completedSteps.add(stepId);
        await _prefs.setStringList(progressKey, completedSteps);
      }

      // Sauvegarder sur le backend si disponible
      if (_firestore != null) {
        await _firestore!
            .collection('userTutorials')
            .doc('$userId-$tutorialId')
            .set({
          'userId': userId,
          'tutorialId': tutorialId,
          'completedSteps': completedSteps,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Erreur sauvegarde étape tutoriel: $e');
    }
  }

  // Marquer tout le tutoriel comme complété
  Future<void> completeTutorial(String userId, String tutorialId) async {
    try {
      // Sauvegarder en local
      final completedKey = '$_tutorialCompletedKey$userId-$tutorialId';
      await _prefs.setBool(completedKey, true);

      // Sauvegarder sur le backend
      if (_firestore != null) {
        await _firestore!
            .collection('userTutorials')
            .doc('$userId-$tutorialId')
            .set({
          'userId': userId,
          'tutorialId': tutorialId,
          'isCompleted': true,
          'completedAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Erreur complétion tutoriel: $e');
    }
  }

  // Obtenir la progression
  Future<List<String>> getCompletedSteps(String userId, String tutorialId) async {
    final progressKey = '$_tutorialProgressKey$userId-$tutorialId';
    return _prefs.getStringList(progressKey) ?? [];
  }

  // Réinitialiser le tutoriel pour l'utilisateur
  Future<void> resetTutorial(String userId, String tutorialId) async {
    try {
      // Local
      final completedKey = '$_tutorialCompletedKey$userId-$tutorialId';
      final progressKey = '$_tutorialProgressKey$userId-$tutorialId';

      await _prefs.remove(completedKey);
      await _prefs.remove(progressKey);

      // Backend
      if (_firestore != null) {
        await _firestore!
            .collection('userTutorials')
            .doc('$userId-$tutorialId')
            .delete();
      }
    } catch (e) {
      print('Erreur réinitialisation tutoriel: $e');
    }
  }
}