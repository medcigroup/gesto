import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../config/Schedule_model_service.dart';


// ============================================================================
// DIALOGUE PRINCIPAL POUR AJOUTER/MODIFIER UN PROGRAMME
// ============================================================================

class ScheduleDialog extends StatefulWidget {
  final Schedule? schedule;
  final List<Employee> employees;
  final Function(Schedule) onSave;
  final Function(Schedule, List<int>, int)? onSaveMultipleDays;

  const ScheduleDialog({
    Key? key,
    this.schedule,
    required this.employees,
    required this.onSave,
    this.onSaveMultipleDays,
  }) : super(key: key);

  @override
  _ScheduleDialogState createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<ScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  Employee? _selectedEmployee;
  DateTime _selectedDate = DateTime.now();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String _selectedShift = 'morning';
  Color _selectedColor = Colors.blue;

  // Variables pour la duplication
  bool _duplicateOnMultipleDays = false;
  List<bool> _selectedWeekDays = List.filled(7, false);
  int _numberOfWeeks = 1;
  bool _allowNextDayEnd = false;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _endTime = _calculateDefaultEndTime();

    if (widget.schedule != null) {
      _initializeFromExistingSchedule();
    }
  }

  TimeOfDay _calculateDefaultEndTime() {
    final now = TimeOfDay.now();
    int endHour = now.hour + 8;

    if (endHour >= 24) {
      endHour = endHour - 24;
    }

    return TimeOfDay(hour: endHour, minute: now.minute);
  }

  void _initializeFromExistingSchedule() {
    final schedule = widget.schedule!;
    _selectedDate = schedule.startTime;
    _startTime = TimeOfDay.fromDateTime(schedule.startTime);
    _endTime = TimeOfDay.fromDateTime(schedule.endTime);
    _selectedShift = schedule.shift;
    _selectedColor = schedule.color;
    _notesController.text = schedule.notes ?? '';
    _allowNextDayEnd = schedule.spansMultipleDays;

    _selectedEmployee = widget.employees.firstWhere(
          (emp) => emp.id == schedule.employeeId,
      orElse: () => widget.employees.first,
    );

    if (schedule.weekDays.isNotEmpty) {
      _duplicateOnMultipleDays = true;
      for (int day in schedule.weekDays) {
        if (day >= 1 && day <= 7) {
          _selectedWeekDays[day - 1] = true;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Text(
              widget.schedule == null ? 'Ajouter un créneau' : 'Modifier le créneau',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Contenu scrollable
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildSimpleEmployeeDropdown(),
                    const SizedBox(height: 16),
                    _buildSimpleDateField(),
                    const SizedBox(height: 16),
                    _buildSimpleTimeFields(),
                    const SizedBox(height: 16),
                    _buildSimpleCheckbox(),
                    const SizedBox(height: 16),
                    _buildSimpleShiftDropdown(),
                    const SizedBox(height: 16),
                    _buildSimpleColorPicker(),
                    const SizedBox(height: 16),
                    _buildSimpleNotesField(),
                    const SizedBox(height: 16),
                    _buildSimpleDuplicationOptions(),
                  ],
                ),
              ),
            ),

            // Actions
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveSchedule,
                  child: Text(widget.schedule == null ? 'Ajouter' : 'Modifier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleEmployeeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Employé *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Employee>(
              value: _selectedEmployee,
              hint: const Text('Sélectionner un employé'),
              isExpanded: true,
              items: widget.employees.map((employee) {
                return DropdownMenuItem(
                  value: employee,
                  child: Text(employee.name),
                );
              }).toList(),
              onChanged: (Employee? value) {
                setState(() {
                  _selectedEmployee = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleTimeFields() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Début *', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (time != null) {
                    setState(() {
                      _startTime = time;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_startTime.format(context)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _allowNextDayEnd ? 'Fin (jour suivant)' : 'Fin *',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _endTime,
                  );
                  if (time != null) {
                    setState(() {
                      _endTime = time;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_endTime.format(context)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _allowNextDayEnd,
          onChanged: (bool? value) {
            setState(() {
              _allowNextDayEnd = value ?? false;
            });
          },
        ),
        const Expanded(
          child: Text('Le programme se termine le jour suivant'),
        ),
      ],
    );
  }

  Widget _buildSimpleShiftDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Service', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedShift,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'morning', child: Text('Matin (6h-14h)')),
                DropdownMenuItem(value: 'afternoon', child: Text('Après-midi (14h-22h)')),
                DropdownMenuItem(value: 'night', child: Text('Soir/Nuit (22h-6h)')),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedShift = value;
                    if (value == 'night' && !_allowNextDayEnd) {
                      _allowNextDayEnd = true;
                    }
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Couleur:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ScheduleUtils.getScheduleColors().map((color) {
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: _selectedColor == color
                      ? Border.all(color: Colors.white, width: 3)
                      : Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: _selectedColor == color
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSimpleNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notes (optionnel)', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Ajouter une note...',
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleDuplicationOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _duplicateOnMultipleDays,
              onChanged: (bool? value) {
                setState(() {
                  _duplicateOnMultipleDays = value ?? false;
                });
              },
            ),
            const Expanded(
              child: Text('Dupliquer sur plusieurs jours'),
            ),
          ],
        ),
        if (_duplicateOnMultipleDays) ...[
          const SizedBox(height: 8),
          const Text('Jours de la semaine:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedWeekDays[index] = !_selectedWeekDays[index];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedWeekDays[index] ? _selectedColor.withOpacity(0.3) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedWeekDays[index] ? _selectedColor : Colors.grey,
                    ),
                  ),
                  child: Text(
                    days[index],
                    style: TextStyle(
                      fontWeight: _selectedWeekDays[index] ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Nombre de semaines: '),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _numberOfWeeks,
                    items: List.generate(8, (index) => index + 1)
                        .map((weeks) => DropdownMenuItem(
                      value: weeks,
                      child: Text('$weeks'),
                    ))
                        .toList(),
                    onChanged: (int? value) {
                      if (value != null) {
                        setState(() {
                          _numberOfWeeks = value;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _saveSchedule() async {
    if (!_formKey.currentState!.validate() || _selectedEmployee == null) {
      return;
    }

    // Validation des jours sélectionnés pour la duplication
    if (_duplicateOnMultipleDays && !_selectedWeekDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un jour pour la duplication'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    DateTime endDateTime;
    if (_allowNextDayEnd) {
      // Si la fin est le jour suivant
      endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + 1,
        _endTime.hour,
        _endTime.minute,
      );
    } else {
      endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Validation: l'heure de fin doit être après l'heure de début
      if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L\'heure de fin doit être après l\'heure de début'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Vérifier les conflits
    try {
      final conflicts = await ScheduleService.checkScheduleConflicts(
        _selectedEmployee!.id,
        startDateTime,
        endDateTime,
        excludeScheduleId: widget.schedule?.id,
      );

      if (conflicts.isNotEmpty && mounted) {
        final shouldContinue = await _showConflictDialog(conflicts);
        if (!shouldContinue) return;
      }
    } catch (e) {
      print('Erreur lors de la vérification des conflits: $e');
    }

    final schedule = Schedule(
      id: widget.schedule?.id ?? '',
      employeeId: _selectedEmployee!.id,
      employeeName: _selectedEmployee!.name,
      startTime: startDateTime,
      endTime: endDateTime,
      shift: _selectedShift,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      color: _selectedColor,
      isMultiDay: _allowNextDayEnd,
      weekDays: _duplicateOnMultipleDays
          ? _selectedWeekDays.asMap().entries
          .where((entry) => entry.value)
          .map((entry) => entry.key + 1)
          .toList()
          : [],
    );

    if (_duplicateOnMultipleDays && widget.onSaveMultipleDays != null) {
      // Sauvegarder pour plusieurs jours
      final selectedDays = _selectedWeekDays.asMap().entries
          .where((entry) => entry.value)
          .map((entry) => entry.key + 1)
          .toList();

      widget.onSaveMultipleDays!(schedule, selectedDays, _numberOfWeeks);
    } else {
      // Sauvegarder un seul programme
      widget.onSave(schedule);
    }
  }

  Future<bool> _showConflictDialog(List<Schedule> conflicts) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflit d\'horaires détecté'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ce créneau entre en conflit avec:'),
            const SizedBox(height: 8),
            ...conflicts.map((conflict) => Card(
              child: ListTile(
                title: Text(ScheduleUtils.formatTimeRange(conflict.startTime, conflict.endTime)),
                subtitle: Text(conflict.notes ?? 'Aucune note'),
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuer quand même'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}

// ============================================================================
// DIALOGUE POUR LES DÉTAILS D'UN PROGRAMME
// ============================================================================

class ScheduleDetailsDialog extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ScheduleDetailsDialog({
    Key? key,
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: schedule.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Détails du créneau')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Employé', schedule.employeeName),
          _buildDetailRow('Date', DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(schedule.startTime)),
          _buildDetailRow('Horaires', ScheduleUtils.formatTimeRange(schedule.startTime, schedule.endTime)),
          _buildDetailRow('Service', ScheduleUtils.getShiftDisplayName(schedule.shift)),
          _buildDetailRow('Durée', '${schedule.durationInHours.toStringAsFixed(1)}h'),
          if (schedule.spansMultipleDays)
            _buildDetailRow('Multi-jours', 'Oui'),
          if (schedule.weekDays.isNotEmpty)
            _buildDetailRow('Répétition', schedule.weekDays.map((day) =>
                ScheduleUtils.getWeekDayName(day).substring(0, 3)).join(', ')),
          if (schedule.notes != null)
            _buildDetailRow('Notes', schedule.notes!),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        TextButton(
          onPressed: onEdit,
          child: const Text('Modifier'),
        ),
        TextButton(
          onPressed: () => _confirmDelete(context),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Supprimer'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le créneau de ${schedule.employeeName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              onDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DIALOGUE POUR AFFICHER LES PROGRAMMES D'UN EMPLOYÉ
// ============================================================================

class EmployeeScheduleDialog extends StatelessWidget {
  final Employee employee;

  const EmployeeScheduleDialog({
    Key? key,
    required this.employee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(),
            Expanded(child: _buildSchedulesList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF3F51B5),
          backgroundImage: employee.photoUrl != null
              ? NetworkImage(employee.photoUrl!)
              : null,
          child: employee.photoUrl == null
              ? Text(
            employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ScheduleUtils.getRoleDisplayName(employee.role),
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSchedulesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schedules')
          .where('employeeId', isEqualTo: employee.id)
          .orderBy('startTime')
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucun créneau planifié'),
              ],
            ),
          );
        }

        final schedules = snapshot.data!.docs
            .map((doc) => Schedule.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        return ListView.builder(
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 4,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: schedule.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                title: Text(
                  DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(schedule.startTime),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ScheduleUtils.formatTimeRange(schedule.startTime, schedule.endTime)),
                    Text(
                      '${ScheduleUtils.getShiftDisplayName(schedule.shift)} • ${schedule.durationInHours.toStringAsFixed(1)}h',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                trailing: schedule.spansMultipleDays
                    ? const Icon(Icons.schedule, color: Colors.orange)
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}