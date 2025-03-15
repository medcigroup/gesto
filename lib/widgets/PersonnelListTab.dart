import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gesto/config/user_model.dart';
import 'package:intl/intl.dart';

import '../components/personnels/constants.dart';
import 'EmployeeDetailDialog.dart';

class PersonnelListTab extends StatelessWidget {
  final bool isLoading;
  final List<UserModelPersonnel> personnelList;
  final TextEditingController searchController;
  final String selectedDepartement;
  final Function(String?) onDepartementChanged;
  final Function(String) onSearch;
  final VoidCallback onRefresh;
  final Function(UserModelPersonnel) onEditEmployee;
  final Function(UserModelPersonnel) onToggleStatus;
  final Function(String) showSuccessMessage;
  final Function(String) showErrorMessage;
  final Function(UserModelPersonnel) onDeleteEmployee; // New callback for deletion

  const PersonnelListTab({
    Key? key,
    required this.isLoading,
    required this.personnelList,
    required this.searchController,
    required this.selectedDepartement,
    required this.onDepartementChanged,
    required this.onSearch,
    required this.onRefresh,
    required this.onEditEmployee,
    required this.onToggleStatus,
    required this.showSuccessMessage,
    required this.showErrorMessage,
    required this.onDeleteEmployee, // Added this parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: _buildEmployeeList(context),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeList(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (personnelList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun personnel trouvé',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: personnelList.length,
      itemBuilder: (context, index) {
        final employee = personnelList[index];
        return _buildEmployeeCard(context, employee);
      },
    );
  }

  Widget _buildEmployeeCard(BuildContext context, UserModelPersonnel employee) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Slidable(
        key: Key(employee.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.5, // Increased to accommodate two actions
          children: [
            SlidableAction(
              label: employee.statut == 'actif' ? 'Désactiver' : 'Activer',
              backgroundColor: employee.statut == 'actif'
                  ? Colors.orange
                  : Colors.green,
              foregroundColor: Colors.white,
              icon: employee.statut == 'actif'
                  ? Icons.person_off_outlined
                  : Icons.person,
              onPressed: (context) => onToggleStatus(employee),
            ),
            SlidableAction(
              label: 'Supprimer',
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
              onPressed: (context) => _confirmDelete(context, employee),
            ),
          ],
        ),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              label: 'Modifier',
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              icon: Icons.edit_outlined,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              onPressed: (context) => onEditEmployee(employee),
            ),
          ],
        ),
        child: Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showEmployeeDetails(context, employee),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(employee),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${employee.prenom} ${employee.nom}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.work_outline,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${employee.poste}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${employee.departement}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Embauché le: ${DateFormat('dd/MM/yyyy').format(employee.dateEmbauche)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(employee),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModelPersonnel employee) {
    return Hero(
      tag: 'avatar-${employee.id}',
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: employee.photoUrl == null ? _getAvatarColor(employee) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: employee.photoUrl != null
              ? Image.network(
            employee.photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _getInitialsAvatar(employee),
          )
              : _getInitialsAvatar(employee),
        ),
      ),
    );
  }

  Widget _getInitialsAvatar(UserModelPersonnel employee) {
    return Center(
      child: Text(
        '${employee.prenom.isNotEmpty ? employee.prenom[0] : ''}${employee.nom.isNotEmpty ? employee.nom[0] : ''}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Color _getAvatarColor(UserModelPersonnel employee) {
    // Generate a deterministic color based on employee id
    final int hash = employee.id.hashCode;
    final List<Color> colors = [
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.teal,
      Colors.amber.shade700,
      Colors.redAccent,
      Colors.indigo,
      Colors.green,
      Colors.deepOrange,
    ];
    return colors[hash.abs() % colors.length];
  }

  Widget _buildStatusBadge(UserModelPersonnel employee) {
    final bool isActive = employee.statut == 'actif';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 14,
            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            employee.statut.toUpperCase(),
            style: TextStyle(
              color: isActive ? Colors.green.shade800 : Colors.red.shade800,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDetails(BuildContext context, UserModelPersonnel employee) {
    showDialog(
      context: context,
      builder: (context) => EmployeeDetailDialog(
        employee: employee,
        onEdit: () => onEditEmployee(employee),
      ),
    );
  }

  // New confirmation dialog for delete
  void _confirmDelete(BuildContext context, UserModelPersonnel employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.black87, fontSize: 16),
            children: [
              const TextSpan(
                text: 'Êtes-vous sûr de vouloir supprimer ',
              ),
              TextSpan(
                text: '${employee.prenom} ${employee.nom}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text: ' de votre personnel ? Cette action est irréversible.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              onDeleteEmployee(employee);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

}

