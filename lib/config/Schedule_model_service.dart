import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ============================================================================
// MODÈLES DE DONNÉES
// ============================================================================

class Employee {
  final String id;
  final String name;
  final String role;
  final String? photoUrl;
  final bool isActive;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    this.photoUrl,
    this.isActive = true,
  });

  factory Employee.fromMap(Map<String, dynamic> data, String id) {
    return Employee(
      id: id,
      name: '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim(),
      role: data['poste'] ?? 'autre',
      photoUrl: data['photoUrl'],
      isActive: data['isActive'] ?? true,
    );
  }
}

class Schedule {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime startTime;
  final DateTime endTime;
  final String shift;
  final String? notes;
  final Color color;
  final bool isMultiDay;
  final List<int> weekDays;

  Schedule({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.startTime,
    required this.endTime,
    required this.shift,
    this.notes,
    required this.color,
    this.isMultiDay = false,
    this.weekDays = const [],
  });

  factory Schedule.fromMap(Map<String, dynamic> data, String id) {
    return Schedule(
      id: id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      shift: data['shift'] ?? 'morning',
      notes: data['notes'],
      color: Color(data['color'] ?? Colors.blue.value),
      isMultiDay: data['isMultiDay'] ?? false,
      weekDays: List<int>.from(data['weekDays'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'shift': shift,
      'notes': notes,
      'color': color.value,
      'isMultiDay': isMultiDay,
      'weekDays': weekDays,
    };
  }

  double get durationInHours {
    return endTime.difference(startTime).inMinutes / 60.0;
  }

  bool get spansMultipleDays {
    return startTime.day != endTime.day || startTime.month != endTime.month;
  }

  Schedule copyToDate(DateTime newDate) {
    final duration = endTime.difference(startTime);
    final newStartTime = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      startTime.hour,
      startTime.minute,
    );

    return Schedule(
      id: '',
      employeeId: employeeId,
      employeeName: employeeName,
      startTime: newStartTime,
      endTime: newStartTime.add(duration),
      shift: shift,
      notes: notes,
      color: color,
      isMultiDay: isMultiDay,
      weekDays: weekDays,
    );
  }
}

// ============================================================================
// SERVICES AMÉLIORÉS
// ============================================================================

class ScheduleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== MÉTHODES DE RÉCUPÉRATION PAR PÉRIODE ==========

  /// Obtenir les programmes pour une semaine spécifique
  static Stream<List<Schedule>> getSchedulesForWeek(
      DateTime date, {
        String? employeeId,
      }) {
    DateTime startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    return _getSchedulesForPeriod(
      startOfWeek,
      endOfWeek,
      employeeId: employeeId,
    );
  }

  /// Obtenir les programmes pour un mois spécifique
  static Stream<List<Schedule>> getSchedulesForMonth(
      DateTime date, {
        String? employeeId,
      }) {
    DateTime startOfMonth = DateTime(date.year, date.month, 1);
    DateTime endOfMonth = DateTime(date.year, date.month + 1, 1);

    return _getSchedulesForPeriod(
      startOfMonth,
      endOfMonth,
      employeeId: employeeId,
    );
  }

  /// Obtenir les programmes pour un jour spécifique
  static Stream<List<Schedule>> getSchedulesForDay(
      DateTime date, {
        String? employeeId,
      }) {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _getSchedulesForPeriod(
      startOfDay,
      endOfDay,
      employeeId: employeeId,
    );
  }

  /// Méthode générique pour obtenir les programmes pour une période donnée
  static Stream<List<Schedule>> _getSchedulesForPeriod(
      DateTime startDate,
      DateTime endDate, {
        String? employeeId,
      }) {
    Query query = _firestore
        .collection('schedules')
        .where('startTime', isGreaterThanOrEqualTo: startDate)
        .where('startTime', isLessThan: endDate);

    if (employeeId != null && employeeId.isNotEmpty) {
      query = query.where('employeeId', isEqualTo: employeeId);
    }

    return query.orderBy('startTime').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Schedule.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Méthode de compatibilité avec l'ancien code (délègue à getSchedulesForWeek)
  static Stream<List<Schedule>> getSchedules(
      DateTime date, {
        String? employeeId,
      }) {
    return getSchedulesForWeek(date, employeeId: employeeId);
  }

  // ========== MÉTHODES D'AJOUT ==========

  /// Ajouter un programme simple
  static Future<void> addSchedule(Schedule schedule) async {
    await _firestore.collection('schedules').add(schedule.toMap());
  }

  /// Ajouter des programmes pour plusieurs jours
  static Future<void> addScheduleForMultipleDays(
      Schedule baseSchedule,
      List<int> weekDays,
      DateTime startWeek,
      int numberOfWeeks,
      ) async {
    final batch = _firestore.batch();
    int batchCount = 0;
    List<WriteBatch> batches = [batch];

    for (int week = 0; week < numberOfWeeks; week++) {
      for (int weekDay in weekDays) {
        final targetDate =
        startWeek.add(Duration(days: (week * 7) + (weekDay - 1)));
        final newSchedule = baseSchedule.copyToDate(targetDate);

        final scheduleWithWeekDays = Schedule(
          id: newSchedule.id,
          employeeId: newSchedule.employeeId,
          employeeName: newSchedule.employeeName,
          startTime: newSchedule.startTime,
          endTime: newSchedule.endTime,
          shift: newSchedule.shift,
          notes: newSchedule.notes,
          color: newSchedule.color,
          isMultiDay: newSchedule.isMultiDay,
          weekDays: weekDays,
        );

        final docRef = _firestore.collection('schedules').doc();
        batches.last.set(docRef, scheduleWithWeekDays.toMap());

        batchCount++;

        // Firestore limite à 500 opérations par batch
        if (batchCount >= 500) {
          batches.add(_firestore.batch());
          batchCount = 0;
        }
      }
    }

    // Commit tous les batches
    for (final b in batches) {
      await b.commit();
    }
  }

  // ========== MÉTHODES DE MODIFICATION ==========

  /// Mettre à jour un programme
  static Future<void> updateSchedule(Schedule schedule) async {
    await _firestore
        .collection('schedules')
        .doc(schedule.id)
        .update(schedule.toMap());
  }

  /// Supprimer un programme
  static Future<void> deleteSchedule(String scheduleId) async {
    await _firestore.collection('schedules').doc(scheduleId).delete();
  }

  /// Supprimer plusieurs programmes (par employé et période)
  static Future<void> deleteSchedulesForEmployee(
      String employeeId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    final query = await _firestore
        .collection('schedules')
        .where('employeeId', isEqualTo: employeeId)
        .where('startTime', isGreaterThanOrEqualTo: startDate)
        .where('startTime', isLessThan: endDate)
        .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ========== MÉTHODES DE VÉRIFICATION ==========

  /// Vérifier les conflits d'horaires
  static Future<List<Schedule>> checkScheduleConflicts(
      String employeeId,
      DateTime startTime,
      DateTime endTime, {
        String? excludeScheduleId,
      }) async {
    // Rechercher dans une plage étendue pour capturer tous les chevauchements possibles
    final searchStart = startTime.subtract(const Duration(days: 1));
    final searchEnd = endTime.add(const Duration(days: 1));

    final query = await _firestore
        .collection('schedules')
        .where('employeeId', isEqualTo: employeeId)
        .where('startTime', isGreaterThanOrEqualTo: searchStart)
        .where('startTime', isLessThan: searchEnd)
        .get();

    final conflictingSchedules = <Schedule>[];

    for (final doc in query.docs) {
      if (excludeScheduleId != null && doc.id == excludeScheduleId) continue;

      final schedule = Schedule.fromMap(doc.data(), doc.id);

      if (_schedulesOverlap(startTime, endTime, schedule.startTime, schedule.endTime)) {
        conflictingSchedules.add(schedule);
      }
    }

    return conflictingSchedules;
  }

  /// Vérifier le chevauchement entre deux plages horaires
  static bool _schedulesOverlap(
      DateTime start1,
      DateTime end1,
      DateTime start2,
      DateTime end2,
      ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  /// Obtenir les statistiques pour une période
  static Future<ScheduleStatistics> getStatistics(
      DateTime startDate,
      DateTime endDate, {
        String? employeeId,
      }) async {
    Query query = _firestore
        .collection('schedules')
        .where('startTime', isGreaterThanOrEqualTo: startDate)
        .where('startTime', isLessThan: endDate);

    if (employeeId != null) {
      query = query.where('employeeId', isEqualTo: employeeId);
    }

    final snapshot = await query.get();
    final schedules = snapshot.docs
        .map((doc) => Schedule.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    return ScheduleStatistics.fromSchedules(schedules);
  }
}

// ============================================================================
// CLASSE DE STATISTIQUES
// ============================================================================

class ScheduleStatistics {
  final int totalSchedules;
  final double totalHours;
  final int uniqueEmployees;
  final int multiDaySchedules;
  final Map<String, double> hoursByEmployee;
  final Map<String, int> schedulesByShift;

  ScheduleStatistics({
    required this.totalSchedules,
    required this.totalHours,
    required this.uniqueEmployees,
    required this.multiDaySchedules,
    required this.hoursByEmployee,
    required this.schedulesByShift,
  });

  factory ScheduleStatistics.fromSchedules(List<Schedule> schedules) {
    final hoursByEmployee = <String, double>{};
    final schedulesByShift = <String, int>{};
    double totalHours = 0;
    int multiDayCount = 0;

    for (final schedule in schedules) {
      // Heures par employé
      hoursByEmployee[schedule.employeeName] =
          (hoursByEmployee[schedule.employeeName] ?? 0) + schedule.durationInHours;

      // Heures totales
      totalHours += schedule.durationInHours;

      // Comptage par service
      schedulesByShift[schedule.shift] = (schedulesByShift[schedule.shift] ?? 0) + 1;

      // Multi-jours
      if (schedule.spansMultipleDays) {
        multiDayCount++;
      }
    }

    return ScheduleStatistics(
      totalSchedules: schedules.length,
      totalHours: totalHours,
      uniqueEmployees: schedules.map((s) => s.employeeId).toSet().length,
      multiDaySchedules: multiDayCount,
      hoursByEmployee: hoursByEmployee,
      schedulesByShift: schedulesByShift,
    );
  }
}

// ============================================================================
// SERVICE EMPLOYÉS
// ============================================================================

class EmployeeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Charger les employés pour un administrateur
  static Future<List<Employee>> loadEmployees(String adminId) async {
    try {
      final snapshot = await _firestore
          .collection('staff')
          .where('idadmin', isEqualTo: adminId)
          .where('statut', isEqualTo: 'actif')
          .get();

      return snapshot.docs
          .map((doc) => Employee.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Erreur lors du chargement des employés: $e');
      return [];
    }
  }

  /// Stream des employés
  static Stream<List<Employee>> getEmployeesStream(String adminId) {
    return _firestore
        .collection('staff')
        .where('idadmin', isEqualTo: adminId)
        .where('statut', isEqualTo: 'actif')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Employee.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Obtenir un employé spécifique
  static Future<Employee?> getEmployee(String employeeId) async {
    try {
      final doc = await _firestore.collection('staff').doc(employeeId).get();

      if (doc.exists) {
        return Employee.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'employé: $e');
      return null;
    }
  }
}

// ============================================================================
// UTILITAIRES
// ============================================================================

class ScheduleUtils {
  /// Obtenir le nom d'affichage du rôle
  static String getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return 'Manager';
      case 'serveur':
        return 'Serveur';
      case 'chef':
        return 'Chef de cuisine';
      case 'barman':
        return 'Barman';
      case 'réceptionniste':
        return 'Réceptionniste';
      case 'caissier':
        return 'Caissier';
      case 'agent d\'entretien':
        return 'Agent d\'entretien';
      case 'personnel de chambre':
        return 'Personnel de chambre';
      default:
        return 'Employé';
    }
  }

  /// Obtenir le nom d'affichage du service
  static String getShiftDisplayName(String shift) {
    switch (shift) {
      case 'morning':
        return 'Matin';
      case 'afternoon':
        return 'Après-midi';
      case 'night':
        return 'Soir';
      default:
        return shift;
    }
  }

  /// Vérifier si une date est aujourd'hui
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Obtenir le numéro de la semaine
  static int getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final difference = date.difference(startOfYear).inDays;
    return (difference / 7).ceil();
  }

  /// Calculer le total des heures
  static double calculateTotalHours(List<Schedule> schedules) {
    return schedules.fold(0.0, (total, schedule) {
      return total + schedule.durationInHours;
    });
  }

  /// Obtenir les employés uniques
  static Set<String> getUniqueEmployees(List<Schedule> schedules) {
    return schedules.map((s) => s.employeeId).toSet();
  }

  /// Obtenir les noms des jours de la semaine
  static List<String> getWeekDayNames() {
    return [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
  }

  /// Obtenir le nom du jour de la semaine
  static String getWeekDayName(int weekDay) {
    final names = getWeekDayNames();
    return names[weekDay - 1];
  }

  /// Créer une palette de couleurs pour les programmes
  static List<Color> getScheduleColors() {
    return [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];
  }

  /// Formater une plage d'heures
  static String formatTimeRange(DateTime start, DateTime end) {
    final startFormat = DateFormat('HH:mm', 'fr_FR');
    final endFormat = DateFormat('HH:mm', 'fr_FR');

    if (start.day == end.day) {
      return '${startFormat.format(start)} - ${endFormat.format(end)}';
    } else {
      final startDay = DateFormat('EEE dd/MM', 'fr_FR');
      final endDay = DateFormat('EEE dd/MM', 'fr_FR');
      return '${startDay.format(start)} ${startFormat.format(start)} - ${endDay.format(end)} ${endFormat.format(end)}';
    }
  }

  /// Obtenir le premier jour du mois
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Obtenir le dernier jour du mois
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Obtenir le premier jour de la semaine (lundi)
  static DateTime getFirstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Obtenir le dernier jour de la semaine (dimanche)
  static DateTime getLastDayOfWeek(DateTime date) {
    return getFirstDayOfWeek(date).add(const Duration(days: 6));
  }

  /// Obtenir tous les jours d'un mois
  static List<DateTime> getDaysInMonth(DateTime date) {
    final firstDay = getFirstDayOfMonth(date);
    final lastDay = getLastDayOfMonth(date);

    final days = <DateTime>[];
    for (int i = 0; i <= lastDay.day - 1; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }

    return days;
  }

  /// Obtenir tous les jours d'une semaine
  static List<DateTime> getDaysInWeek(DateTime date) {
    final firstDay = getFirstDayOfWeek(date);
    return List.generate(7, (index) => firstDay.add(Duration(days: index)));
  }

  /// Grouper les créneaux par jour
  static Map<String, List<Schedule>> groupSchedulesByDay(List<Schedule> schedules) {
    final grouped = <String, List<Schedule>>{};

    for (final schedule in schedules) {
      final dayKey = DateFormat('yyyy-MM-dd').format(schedule.startTime);
      if (!grouped.containsKey(dayKey)) {
        grouped[dayKey] = [];
      }
      grouped[dayKey]!.add(schedule);
    }

    return grouped;
  }

  /// Grouper les créneaux par employé
  static Map<String, List<Schedule>> groupSchedulesByEmployee(List<Schedule> schedules) {
    final grouped = <String, List<Schedule>>{};

    for (final schedule in schedules) {
      if (!grouped.containsKey(schedule.employeeId)) {
        grouped[schedule.employeeId] = [];
      }
      grouped[schedule.employeeId]!.add(schedule);
    }

    return grouped;
  }
}