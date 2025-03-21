import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/side_menu.dart';
import 'LicenceManagerPage.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      List<Map<String, dynamic>> usersList = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id;

        // Formater la date de création si elle existe
        if (userData['createdAt'] != null) {
          Timestamp timestamp = userData['createdAt'] as Timestamp;
          DateTime dateTime = timestamp.toDate();
          userData['createdAtFormatted'] = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
        } else {
          userData['createdAtFormatted'] = 'N/A';
        }

        // Formater la date d'expiration de licence si elle existe
        if (userData['licenceExpiryDate'] != null) {
          Timestamp timestamp = userData['licenceExpiryDate'] as Timestamp;
          DateTime dateTime = timestamp.toDate();
          userData['licenceExpiryFormatted'] = '${dateTime.day}/${dateTime.month}/${dateTime.year}';

          // Calculer si la licence est expirée
          userData['isLicenceExpired'] = dateTime.isBefore(DateTime.now());
        } else {
          userData['licenceExpiryFormatted'] = 'N/A';
          userData['isLicenceExpired'] = true;
        }

        usersList.add(userData);
      }

      setState(() {
        _users = usersList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des utilisateurs: $e')),
      );
    }
  }

  Future<void> _deleteUser(String userId, String userEmail) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer l\'utilisateur $userEmail ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmDelete) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Obtenir une instance admin de Firebase Auth (nécessite une fonction Cloud)
        // Cette partie devrait être implémentée en tant que fonction Firebase Cloud
        // car la suppression d'un utilisateur Auth nécessite des privilèges admin

        // 1. Supprimer le document Firestore de l'utilisateur
        await _firestore.collection('users').doc(userId).delete();

        // 2. Rafraîchir la liste des utilisateurs
        await _fetchUsers();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Utilisateur $userEmail supprimé avec succès')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(String userId, String userEmail, bool isActive) async {
    String action = isActive ? 'désactiver' : 'activer';
    bool confirmToggle = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer l\'action'),
          content: Text('Êtes-vous sûr de vouloir $action l\'utilisateur $userEmail ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(isActive ? 'Désactiver' : 'Activer'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmToggle) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Mettre à jour le statut de l'utilisateur dans Firestore
        await _firestore.collection('users').doc(userId).update({
          'isActive': !isActive,
        });

        await _fetchUsers();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Utilisateur $userEmail ${isActive ? 'désactivé' : 'activé'} avec succès')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour du statut: $e')),
        );
      }
    }
  }

  void _navigateToLicenseManagement() {
    // Navigation vers l'espace licence en utilisant la page que nous avons créée
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LicenceManagerPage()),
    );
  }

  void _navigateToMessageCenter() {
    // Navigation vers l'espace message
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MessageCenterScreen()),
    );
  }

  Future<void> _updateUserLicense(String userId, String userEmail) async {
    // Valeurs par défaut pour les contrôleurs
    final licenseTypeController = TextEditingController();
    final dateController = TextEditingController();
    DateTime? selectedDate;

    bool result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Mettre à jour la licence de $userEmail'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Type de licence',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                        DropdownMenuItem(value: 'Premium', child: Text('Premium')),
                        DropdownMenuItem(value: 'Enterprise', child: Text('Enterprise')),
                        DropdownMenuItem(value: 'basic', child: Text('basic')),
                      ],
                      onChanged: (value) {
                        licenseTypeController.text = value!;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date d\'expiration',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                            dateController.text = "${picked.day}/${picked.month}/${picked.year}";
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (licenseTypeController.text.isNotEmpty && selectedDate != null) {
                      Navigator.of(context).pop(true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez remplir tous les champs')),
                      );
                    }
                  },
                  child: const Text('Mettre à jour'),
                ),
              ],
            );
          },
        );
      },
    ) ?? false;

    if (result && selectedDate != null && licenseTypeController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _firestore.collection('users').doc(userId).update({
          'licenceType': licenseTypeController.text,
          'licenceExpiryDate': Timestamp.fromDate(selectedDate!),
        });

        await _fetchUsers();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Licence mise à jour pour $userEmail')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour de la licence: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        actions: [
          // Bouton Espace Licence
          TextButton.icon(
            onPressed: _navigateToLicenseManagement,
            icon: const Icon(Icons.card_membership, color: Colors.orange),
            label: const Text('Espace Licence', style: TextStyle(color: Colors.orange)),
          ),
          const SizedBox(width: 8),

          // Bouton Espace Message
          TextButton.icon(
            onPressed: _navigateToMessageCenter,
            icon: const Icon(Icons.message, color: Colors.blue),
            label: const Text('Espace Message', style: TextStyle(color: Colors.blue)),
          ),
          const SizedBox(width: 8),

          // Bouton Rafraîchir
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
            tooltip: 'Rafraîchir la liste',
          ),
        ],
      ),
      drawer: const SideMenu(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(child: Text('Aucun utilisateur trouvé'))
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Téléphone')),
              DataColumn(label: Text('Établissement')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Rôle')),
              DataColumn(label: Text('Date de création')),
              DataColumn(label: Text('Type de licence')),
              DataColumn(label: Text('Expiration licence')),
              DataColumn(label: Text('Statut')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _users.map((user) {
              bool isActive = user['isActive'] ?? true;
              bool isLicenseExpired = user['isLicenceExpired'] ?? true;

              return DataRow(
                cells: [
                  DataCell(Text(user['fullName'] ?? 'N/A')),
                  DataCell(Text(user['email'] ?? 'N/A')),
                  DataCell(Text(user['phone'] ?? 'N/A')),
                  DataCell(Text(user['establishmentName'] ?? 'N/A')),
                  DataCell(Text(user['establishmentType'] ?? 'N/A')),
                  DataCell(Text(user['userRole'] ?? 'N/A')),
                  DataCell(Text(user['createdAtFormatted'])),
                  DataCell(
                    user['licenceType'] != null
                        ? Text(user['licenceType'])
                        : TextButton(
                      onPressed: () => _updateUserLicense(user['id'], user['email']),
                      child: const Text('Définir'),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLicenseExpired ? Colors.red[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user['licenceExpiryFormatted'] ?? 'Non définie',
                        style: TextStyle(
                          color: isLicenseExpired ? Colors.red[800] : Colors.green[800],
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          color: isActive ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ),
                  ),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _updateUserLicense(user['id'], user['email']),
                        tooltip: 'Modifier la licence',
                      ),
                      IconButton(
                        icon: Icon(
                          isActive ? Icons.block : Icons.check_circle,
                          color: isActive ? Colors.orange : Colors.green,
                        ),
                        onPressed: () => _toggleUserStatus(user['id'], user['email'], isActive),
                        tooltip: isActive ? 'Désactiver' : 'Activer',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(user['id'], user['email']),
                        tooltip: 'Supprimer',
                      ),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class MessageCenterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Message'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.message, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Centre de Messages',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gérez les communications avec vos utilisateurs',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Implémentation à venir
              },
              child: const Text('Voir les messages'),
            ),
          ],
        ),
      ),
    );
  }
}