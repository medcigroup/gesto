import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../config/user_model.dart';

class EmployeeDetailDialog extends StatelessWidget {
  final UserModelPersonnel employee;
  final VoidCallback onEdit;

  const EmployeeDetailDialog({
    Key? key,
    required this.employee,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${employee.prenom} ${employee.nom}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(Icons.work),
            title: Text('Poste'),
            subtitle: Text(employee.poste),
          ),
          ListTile(
            leading: Icon(Icons.business),
            title: Text('Département'),
            subtitle: Text(employee.departement),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Email'),
            subtitle: Text(employee.email),
          ),
          if (employee.competences != null && employee.competences!.isNotEmpty)
            ListTile(
              leading: Icon(Icons.star),
              title: Text('Compétences'),
              subtitle: Text(employee.competences!.join(', ')),
            ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Date d\'embauche'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(employee.dateEmbauche)),
          ),
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Statut'),
            subtitle: Text(employee.statut),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Fermer'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onEdit();
          },
          child: Text('Modifier'),
        ),
      ],
    );
  }
}