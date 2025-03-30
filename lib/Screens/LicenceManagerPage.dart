import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../config/LicenceGenerator.dart';
import '../config/LicencePrinter.dart';

// Importation de la classe LicenceGenerator
// Assurez-vous que cette classe est accessible dans votre projet

class LicenceManagerPage extends StatefulWidget {
  const LicenceManagerPage({Key? key}) : super(key: key);

  @override
  _LicenceManagerPageState createState() => _LicenceManagerPageState();
}

class _LicenceManagerPageState extends State<LicenceManagerPage> {
  final _licencesCollection = FirebaseFirestore.instance.collection('licences');
  final _formKey = GlobalKey<FormState>();

  // Variables pour la génération de nouvelles licences
  int _durationDays = 30;
  String _licenceType = 'basic';
  String _PeriodeType = 'month';
  bool _isGenerating = false;
  String? _lastGeneratedLicence;

  // Liste des types de licences disponibles
  final List<String> _licenceTypes = ['basic','starter', 'pro', 'entreprise'];
  final List<String> _PeriodeTypes = ['month','6months', 'year'];


  // Liste des durées prédéfinies en jours
  final List<int> _durationOptions = [7, 30, 90, 180, 365];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Licences'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section pour générer une nouvelle licence
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Générer une nouvelle licence',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Choix du type de licence
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Type de licence',
                          border: OutlineInputBorder(),
                        ),
                        value: _licenceType,
                        items: _licenceTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _licenceType = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez sélectionner un type de licence';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Choix du type de période
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Type de période',
                          border: OutlineInputBorder(),
                        ),
                        value: _PeriodeType,
                        items: _PeriodeTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _PeriodeType = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez sélectionner un type de période';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Choix de la durée
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Durée de validité (jours)',
                          border: OutlineInputBorder(),
                        ),
                        value: _durationDays,
                        items: _durationOptions.map((days) {
                          return DropdownMenuItem<int>(
                            value: days,
                            child: Text('$days jours'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _durationDays = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner une durée';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Bouton de génération
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.key),
                          label: Text(_isGenerating
                              ? 'Génération en cours...'
                              : 'Générer une licence'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: _isGenerating
                              ? null
                              : _generateNewLicence,
                        ),
                      ),

                      // Affichage de la dernière licence générée
                      if (_lastGeneratedLicence != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Card(
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Licence générée avec succès :',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    _lastGeneratedLicence!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.copy),
                                    label: const Text('Copier'),
                                    onPressed: () {
                                      _copyToClipboard(context,_lastGeneratedLicence!);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section pour afficher les licences existantes
            const Text(
              'Licences existantes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Liste des licences
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _licencesCollection
                    .orderBy('generationDate', descending: true)
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
                      child: Text('Aucune licence trouvée'),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      // Conversion des Timestamps en DateTime
                      final generationDate = (data['generationDate'] as Timestamp).toDate();
                      final expiryDate = (data['expiryDate'] as Timestamp).toDate();

                      // Calcul de l'état de la licence
                      final now = DateTime.now();
                      final isExpired = now.isAfter(expiryDate);
                      final daysLeft = expiryDate.difference(now).inDays;

                      // Formatage des dates
                      final dateFormat = DateFormat('dd/MM/yyyy');

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isExpired ? Colors.grey.shade200 : Colors.white,
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  data['code'] ?? '',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: isExpired ? Colors.grey : Colors.black,
                                    decoration: isExpired
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () {
                                  _copyToClipboard(context,data['code']);
                                },
                                tooltip: 'Copier la clé',
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Type: ${data['licenceType'] ?? 'Non spécifié'}'),
                              Text('Période: ${data['periodeType'] ?? 'Non spécifié'}'),
                              Text('Généré le: ${dateFormat.format(generationDate)}'),
                              Text('Expire le: ${dateFormat.format(expiryDate)}'),
                              const SizedBox(height: 4),
                              // Badge d'état
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isExpired
                                      ? Colors.red.shade100
                                      : (daysLeft < 30
                                      ? Colors.orange.shade100
                                      : Colors.green.shade100),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isExpired
                                      ? 'Expirée'
                                      : 'Valide (${daysLeft}j restants)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isExpired
                                        ? Colors.red.shade800
                                        : (daysLeft < 30
                                        ? Colors.orange.shade800
                                        : Colors.green.shade800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {
                              _showLicenceOptions(context, doc.id, data);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showFilterOptions(context);
        },
        child: const Icon(Icons.filter_list),
        tooltip: 'Filtrer les licences',
      ),
    );
  }

  // Méthode pour générer une nouvelle licence
  Future<void> _generateNewLicence() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Génération de la licence en utilisant la classe LicenceGenerator
      final result = await LicenceGenerator.generateUniqueLicence(
          _durationDays,
          _licenceType,
          _PeriodeType
      );

      setState(() {
        _lastGeneratedLicence = result['code'];
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Licence générée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour copier une licence dans le presse-papiers
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Licence copiée dans le presse-papiers'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Afficher les options pour une licence
  void _showLicenceOptions(BuildContext context, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Détails'),
                onTap: () {
                  Navigator.pop(context);
                  _showLicenceDetails(context, data);
                },
              ),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Imprimer la licence'),
                onTap: () {
                  Navigator.pop(context);
                  _printLicence(context, data);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Prolonger'),
                onTap: () {
                  Navigator.pop(context);
                  _showExtendLicence(context, docId, data);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Révoquer'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmRevokeLicence(context, docId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Supprimer'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteLicence(context, docId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Afficher les détails d'une licence
  void _showLicenceDetails(BuildContext context, Map<String, dynamic> data) {
    final generationDate = (data['generationDate'] as Timestamp).toDate();
    final expiryDate = (data['expiryDate'] as Timestamp).toDate();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Détails de la licence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Code de licence:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(
                data['code'],
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              Text('Type: ${data['licenceType'] ?? 'Non spécifié'}'),
              Text('Période: ${data['periodeType'] ?? 'Non spécifié'}'),
              Text('Date de génération: ${dateFormat.format(generationDate)}'),
              Text('Date d\'expiration: ${dateFormat.format(expiryDate)}'),
              const SizedBox(height: 16),
              Text('Durée: ${expiryDate.difference(generationDate).inDays} jours'),
              Text(
                'Statut: ${DateTime.now().isAfter(expiryDate) ? 'Expirée' : 'Valide'}',
                style: TextStyle(
                  color: DateTime.now().isAfter(expiryDate) ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  // Afficher les options de filtrage
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Filtrer les licences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('Toutes les licences'),
                onTap: () {
                  Navigator.pop(context);
                  // Implémentez la logique de filtrage ici
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('Licences valides'),
                onTap: () {
                  Navigator.pop(context);
                  // Implémentez la logique de filtrage ici
                },
              ),
              ListTile(
                leading: const Icon(Icons.highlight_off, color: Colors.red),
                title: const Text('Licences expirées'),
                onTap: () {
                  Navigator.pop(context);
                  // Implémentez la logique de filtrage ici
                },
              ),
              const Divider(),
              // Type de licence
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Filtrer par type'),
              ),
              Wrap(
                spacing: 8.0,
                children: _licenceTypes.map((type) {
                  return ActionChip(
                    label: Text(type),
                    onPressed: () {
                      Navigator.pop(context);
                      // Implémentez la logique de filtrage ici
                    },
                  );
                }).toList(),
              ),
              const Divider(),
              // Type de période
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Filtrer par période'),
              ),
              Wrap(
                spacing: 8.0,
                children: _PeriodeTypes.map((type) {
                  return ActionChip(
                    label: Text(type),
                    onPressed: () {
                      Navigator.pop(context);
                      // Implémentez la logique de filtrage ici
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Boîte de dialogue pour prolonger une licence
  void _showExtendLicence(BuildContext context, String docId, Map<String, dynamic> data) {
    int extensionDays = 30;
    String extensionPeriodeType = data['periodeType'] ?? 'month';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Prolonger la licence'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Choisissez la durée et le type de période:'),
                    const SizedBox(height: 16),
                    DropdownButton<int>(
                      value: extensionDays,
                      items: _durationOptions.map((days) {
                        return DropdownMenuItem<int>(
                          value: days,
                          child: Text('$days jours'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          extensionDays = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      value: extensionPeriodeType,
                      items: _PeriodeTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          extensionPeriodeType = value!;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _extendLicence(docId, extensionDays, extensionPeriodeType);
                    },
                    child: const Text('Prolonger'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  // Méthode pour prolonger une licence
  Future<void> _extendLicence(String docId, int days, String periodeType) async {
    try {
      // Récupérer la licence actuelle
      final docSnapshot = await _licencesCollection.doc(docId).get();
      final data = docSnapshot.data() as Map<String, dynamic>;

      // Obtenir la date d'expiration actuelle
      final currentExpiryDate = (data['expiryDate'] as Timestamp).toDate();

      // Calculer la nouvelle date d'expiration
      final newExpiryDate = currentExpiryDate.add(Duration(days: days));

      // Mettre à jour la date d'expiration et le type de période
      await _licencesCollection.doc(docId).update({
        'expiryDate': newExpiryDate,
        'periodeType': periodeType,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Licence prolongée de $days jours ($periodeType)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Confirmation de révocation d'une licence
  void _confirmRevokeLicence(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Révoquer la licence'),
          content: const Text(
              'Êtes-vous sûr de vouloir révoquer cette licence ? '
                  'Elle sera marquée comme expirée immédiatement.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);
                _revokeLicence(docId);
              },
              child: const Text('Révoquer'),
            ),
          ],
        );
      },
    );
  }

  // Méthode pour révoquer une licence
  Future<void> _revokeLicence(String docId) async {
    try {
      // Définir la date d'expiration à maintenant
      await _licencesCollection.doc(docId).update({
        'expiryDate': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Licence révoquée avec succès'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Confirmation de suppression d'une licence
  void _confirmDeleteLicence(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la licence'),
          content: const Text(
              'Êtes-vous sûr de vouloir supprimer définitivement cette licence ? '
                  'Cette action est irréversible.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteLicence(docId);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  // Méthode pour supprimer une licence
  Future<void> _deleteLicence(String docId) async {
    try {
      await _licencesCollection.doc(docId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Licence supprimée avec succès'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour imprimer une licence
  void _printLicence(BuildContext context, Map<String, dynamic> data) {
    // Conversion des Timestamps en DateTime pour l'impression
    final licenceData = Map<String, dynamic>.from(data);
    licenceData['generationDate'] = (data['generationDate'] as Timestamp).toDate();
    licenceData['expiryDate'] = (data['expiryDate'] as Timestamp).toDate();

    LicencePrinter.printLicence(context, licenceData);
  }
}

