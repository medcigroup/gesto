import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';

import '../../components/messagerie/NotificationProvider.dart';
import '../../widgets/side_menu.dart';
import 'LicenceManagerPage.dart';
import 'messagerie.dart';



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
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer l\'utilisateur $userEmail ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        // Appeler la fonction Cloud pour supprimer l'utilisateur
        final callable = FirebaseFunctions.instance.httpsCallable('deleteUser');
        final result = await callable.call({'uid': userId});

        if (result.data['success']) {
          await _fetchUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Utilisateur $userEmail supprimé avec succès')),
          );
        } else {
          throw Exception('Échec de la suppression: ${result.data['message']}');
        }
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
    bool confirmToggle = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer le changement de statut'),
          content: Text('Êtes-vous sûr de vouloir ${isActive ? 'désactiver' : 'activer'} l\'utilisateur $userEmail ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.orange : Colors.green,
              ),
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
        // Appeler la fonction Cloud pour modifier le statut
        final callable = FirebaseFunctions.instance.httpsCallable('toggleUserStatus');
        final result = await callable.call({
          'uid': userId,
          'disable': isActive,
        });

        if (result.data['success']) {
          await _fetchUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Utilisateur $userEmail ${isActive ? 'désactivé' : 'activé'} avec succès')),
          );
        } else {
          throw Exception('Échec de la mise à jour du statut: ${result.data['message']}');
        }
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

  // Nouvelle fonction pour définir un utilisateur comme admin
  Future<void> _setUserAsAdmin(String userId, String userEmail, [bool isSuperAdmin = false]) async {
    final roleTitle = isSuperAdmin ? 'super-administrateur' : 'administrateur';

    bool confirmRole = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer le changement de rôle'),
          content: Text('Êtes-vous sûr de vouloir définir $userEmail comme $roleTitle ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text('Confirmer'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmRole) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Appeler la fonction Cloud pour définir l'utilisateur comme admin
        final callable = FirebaseFunctions.instance.httpsCallable('addAdmin');
        final result = await callable.call({
          'uid': userId,
          'role': isSuperAdmin ? 'superAdmin' : 'admin',
        });

        if (result.data['success']) {
          await _fetchUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Utilisateur $userEmail défini comme $roleTitle avec succès')),
          );
        } else {
          throw Exception('Échec de la mise à jour du rôle: ${result.data['message']}');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la définition du rôle: $e')),
        );
      }
    }
  }
  Future<void> removeUserAdmin(String userId, String userEmail) async {
    bool confirmRole = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer le changement de rôle'),
          content: Text('Êtes-vous sûr de vouloir supprimer les droits d\'administrateur de $userEmail ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Confirmer'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmRole) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Appeler la fonction Cloud pour révoquer les droits d'admin
        final callable = FirebaseFunctions.instance.httpsCallable('removeAdmin');
        final result = await callable.call({
          'uid': userId,
        });

        if (result.data['success']) {
          await _fetchUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Droits d\'administrateur retirés pour $userEmail avec succès')),
          );
        } else {
          throw Exception('Échec de la mise à jour du rôle: ${result.data['message']}');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        // Extraire le message d'erreur de la réponse Firebase
        String errorMessage = e.toString();
        if (e is FirebaseFunctionsException) {
          // Pour les erreurs Firebase, on extrait le message plus proprement
          errorMessage = e.message ?? 'Erreur inconnue';

          // Vérifier si c'est une erreur de permission
          if (errorMessage.contains('permission-denied')) {
            errorMessage = 'Vous n\'avez pas les droits nécessaires pour effectuer cette action';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $errorMessage')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  void _navigateToMessageCenter() {
    // Récupérer le NotificationProvider existant
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    // Navigation vers l'espace message avec les providers nécessaires
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider<MessageProvider>(
              create: (context) => MessageProvider(),
            ),
            ChangeNotifierProvider<NotificationProvider>.value(
              value: notificationProvider,
            ),
          ],
          child: PageMessagerieComponent(
            expediteurId: userId, // Remplacez par l'ID de l'utilisateur actuel
          ),
        ),
      ),
    );
  }

  // Fonction pour afficher le dialogue de configuration du premier super-admin
  Future<void> _showSetupFirstAdminDialog() async {
    final _emailController = TextEditingController();
    final _secretKeyController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Configuration Premier Super-Admin'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un email';
                    }
                    if (!value.contains('@')) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _secretKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Clé secrète',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la clé secrète';
                    }
                    return null;
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
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Configurer'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmed && _emailController.text.isNotEmpty && _secretKeyController.text.isNotEmpty) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Appeler la fonction Cloud pour configurer le premier admin
        final callable = FirebaseFunctions.instance.httpsCallable('setupFirstAdmin');
        final result = await callable.call({
          'email': _emailController.text,
          'secretKey': _secretKeyController.text,
        });

        setState(() {
          _isLoading = false;
        });

        if (result.data['success']) {
          await _fetchUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.data['message'] ?? 'Super-admin configuré avec succès')),
          );
        } else {
          throw Exception('Échec de la configuration: ${result.data['message']}');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la configuration: $e')),
        );
      }
    }
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Bouton pour configurer le premier super-admin
          FloatingActionButton.extended(
            onPressed: _showSetupFirstAdminDialog,
            icon: const Icon(Icons.security),
            label: const Text('Configurer Super-Admin'),
            heroTag: 'setupSuperAdmin',
            backgroundColor: Colors.purple,
          ),
          const SizedBox(height: 12),
        ],
      ),
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
              String userRole = user['userRole'] ?? 'user';

              return DataRow(
                cells: [
                  DataCell(Text(user['fullName'] ?? 'N/A')),
                  DataCell(Text(user['email'] ?? 'N/A')),
                  DataCell(Text(user['phone'] ?? 'N/A')),
                  DataCell(Text(user['establishmentName'] ?? 'N/A')),
                  DataCell(Text(user['establishmentType'] ?? 'N/A')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: userRole == 'superAdmin'
                            ? Colors.purple[100]
                            : userRole == 'admin'
                            ? Colors.blue[100]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        userRole == 'superAdmin'
                            ? 'Super Admin'
                            : userRole == 'admin'
                            ? 'Admin'
                            : userRole.isEmpty
                            ? 'Utilisateur'
                            : userRole,
                        style: TextStyle(
                          color: userRole == 'superAdmin'
                              ? Colors.purple[800]
                              : userRole == 'admin'
                              ? Colors.blue[800]
                              : Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
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
                      // Bouton pour modifier la licence
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _updateUserLicense(user['id'], user['email']),
                        tooltip: 'Modifier la licence',
                      ),
                      // Pour les utilisateurs qui ne sont ni admin ni super-admin, afficher le bouton pour définir comme admin
                      if (userRole != 'admin' && userRole != 'superAdmin')
                        IconButton(
                          icon: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                          onPressed: () => _setUserAsAdmin(user['id'], user['email']),
                          tooltip: 'Définir comme admin',
                        ),

                      // Pour les utilisateurs qui sont admin uniquement (et non super-admin), afficher le bouton pour révoquer
                      if (userRole == 'admin')
                        IconButton(
                          icon: const Icon(Icons.remove_moderator, color: Colors.red),
                          onPressed: () => removeUserAdmin(user['id'], user['email']),
                          tooltip: 'Retirer les droits d\'admin',
                        ),
                      // Bouton pour définir comme super-admin
                      if (userRole != 'superAdmin')
                        IconButton(
                          icon: const Icon(Icons.security, color: Colors.purple),
                          onPressed: () => _setUserAsAdmin(user['id'], user['email'], true),
                          tooltip: 'Définir comme super-admin',
                        ),
                      // Bouton pour activer/désactiver
                      IconButton(
                        icon: Icon(
                          isActive ? Icons.block : Icons.check_circle,
                          color: isActive ? Colors.orange : Colors.green,
                        ),
                        onPressed: () => _toggleUserStatus(user['id'], user['email'], isActive),
                        tooltip: isActive ? 'Désactiver' : 'Activer',
                      ),
                      // Bouton pour supprimer
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
  const MessageCenterScreen({Key? key}) : super(key: key);

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