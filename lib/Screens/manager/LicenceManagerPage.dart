import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../config/LicenceGenerator.dart';
import '../../config/LicencePrinter.dart';

// Enums pour une meilleure gestion des types
enum LicenceType {
  basic('basic', 'Basic'),
  starter('starter', 'Starter'),
  pro('pro', 'Pro'),
  entreprise('entreprise', 'Entreprise');

  final String value;
  final String label;
  const LicenceType(this.value, this.label);
}

enum PeriodeType {
  month('month', '1 Mois'),
  sixMonths('6months', '6 Mois'),
  year('year', '1 An');

  final String value;
  final String label;
  const PeriodeType(this.value, this.label);
}

enum LicenceDuration {
  week(7, '1 Semaine'),
  month(30, '1 Mois'),
  quarter(90, '3 Mois'),
  semester(180, '6 Mois'),
  year(365, '1 An');

  final int days;
  final String label;
  const LicenceDuration(this.days, this.label);
}

// Extension pour faciliter les calculs de dates
extension DateTimeExtension on DateTime {
  bool get isExpired => DateTime.now().isAfter(this);
  int get daysUntil => difference(DateTime.now()).inDays;
}

class LicenceManagerPage extends StatefulWidget {
  const LicenceManagerPage({Key? key}) : super(key: key);

  @override
  _LicenceManagerPageState createState() => _LicenceManagerPageState();
}

class _LicenceManagerPageState extends State<LicenceManagerPage> {
  final _licencesCollection = FirebaseFirestore.instance.collection('licences');
  final _formKey = GlobalKey<FormState>();

  // Variables pour la génération de nouvelles licences
  LicenceDuration _selectedDuration = LicenceDuration.month;
  LicenceType _selectedLicenceType = LicenceType.basic;
  PeriodeType _selectedPeriodeType = PeriodeType.month;
  bool _isGenerating = false;
  String? _lastGeneratedLicence;

  // Variables pour les filtres
  String _statusFilter = 'all'; // 'all', 'valid', 'expired'
  LicenceType? _typeFilter;
  PeriodeType? _periodeFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Licences'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section pour générer une nouvelle licence
            _LicenceGeneratorCard(
              formKey: _formKey,
              selectedDuration: _selectedDuration,
              selectedLicenceType: _selectedLicenceType,
              selectedPeriodeType: _selectedPeriodeType,
              isGenerating: _isGenerating,
              lastGeneratedLicence: _lastGeneratedLicence,
              onDurationChanged: (value) => setState(() => _selectedDuration = value),
              onLicenceTypeChanged: (value) => setState(() => _selectedLicenceType = value),
              onPeriodeTypeChanged: (value) => setState(() => _selectedPeriodeType = value),
              onGenerateLicence: _generateNewLicence,
              onCopyLicence: (code) => _copyToClipboard(context, code),
            ),
            const SizedBox(height: 24),

            // Section pour afficher les licences existantes
            Text(
              'Licences existantes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Liste des licences
            Expanded(
              child: _LicencesList(
                licencesCollection: _licencesCollection,
                statusFilter: _statusFilter,
                typeFilter: _typeFilter,
                periodeFilter: _periodeFilter,
                onCopyLicence: (code) => _copyToClipboard(context, code),
                onShowOptions: _showLicenceOptions,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFilterOptions(context),
        icon: const Icon(Icons.filter_list),
        label: const Text('Filtrer'),
      ),
    );
  }

  // Widget pour la carte de génération de licence
  Widget _buildLicenceGeneratorCard_OLD() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Générer une nouvelle licence',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Choix du type de licence
              DropdownButtonFormField<LicenceType>(
                decoration: const InputDecoration(
                  labelText: 'Type de licence',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                value: _selectedLicenceType,
                items: LicenceType.values.map((type) {
                  return DropdownMenuItem<LicenceType>(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLicenceType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Choix du type de période
              DropdownButtonFormField<PeriodeType>(
                decoration: const InputDecoration(
                  labelText: 'Type de période',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                ),
                value: _selectedPeriodeType,
                items: PeriodeType.values.map((type) {
                  return DropdownMenuItem<PeriodeType>(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriodeType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Choix de la durée
              DropdownButtonFormField<LicenceDuration>(
                decoration: const InputDecoration(
                  labelText: 'Durée de validité',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                value: _selectedDuration,
                items: LicenceDuration.values.map((duration) {
                  return DropdownMenuItem<LicenceDuration>(
                    value: duration,
                    child: Text(duration.label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              // Bouton de génération
              Center(
                child: FilledButton.icon(
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.key),
                  label: Text(_isGenerating
                      ? 'Génération en cours...'
                      : 'Générer une licence'),
                  onPressed: _isGenerating ? null : _generateNewLicence,
                ),
              ),

              // Affichage de la dernière licence générée
              if (_lastGeneratedLicence != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Licence générée avec succès',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _lastGeneratedLicence!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Copier'),
                          onPressed: () {
                            _copyToClipboard(context, _lastGeneratedLicence!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
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
        _selectedDuration.days,
        _selectedLicenceType.value,
        _selectedPeriodeType.value,
      );

      if (!mounted) return;

      setState(() {
        _lastGeneratedLicence = result['code'];
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Licence générée avec succès'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
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
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Filtrer les licences',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_statusFilter != 'all' || _typeFilter != null || _periodeFilter != null)
                            TextButton.icon(
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Réinitialiser'),
                              onPressed: () {
                                setState(() {
                                  _statusFilter = 'all';
                                  _typeFilter = null;
                                  _periodeFilter = null;
                                });
                                setModalState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Filtres réinitialisés'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const Divider(),
                      // Statut
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Statut',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.all_inclusive,
                          color: _statusFilter == 'all' ? Theme.of(context).colorScheme.primary : null,
                        ),
                        title: const Text('Toutes les licences'),
                        trailing: _statusFilter == 'all' ? const Icon(Icons.check) : null,
                        selected: _statusFilter == 'all',
                        onTap: () {
                          setState(() => _statusFilter = 'all');
                          setModalState(() {});
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.check_circle_outline,
                          color: _statusFilter == 'valid' ? Colors.green : null,
                        ),
                        title: const Text('Licences valides'),
                        trailing: _statusFilter == 'valid' ? const Icon(Icons.check, color: Colors.green) : null,
                        selected: _statusFilter == 'valid',
                        onTap: () {
                          setState(() => _statusFilter = 'valid');
                          setModalState(() {});
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.highlight_off,
                          color: _statusFilter == 'expired' ? Colors.red : null,
                        ),
                        title: const Text('Licences expirées'),
                        trailing: _statusFilter == 'expired' ? const Icon(Icons.check, color: Colors.red) : null,
                        selected: _statusFilter == 'expired',
                        onTap: () {
                          setState(() => _statusFilter = 'expired');
                          setModalState(() {});
                        },
                      ),
                      const Divider(),
                      // Type de licence
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Type de licence',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: LicenceType.values.map((type) {
                            return FilterChip(
                              label: Text(type.label),
                              selected: _typeFilter == type,
                              onSelected: (selected) {
                                setState(() {
                                  _typeFilter = selected ? type : null;
                                });
                                setModalState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(),
                      // Type de période
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Type de période',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: PeriodeType.values.map((type) {
                            return FilterChip(
                              label: Text(type.label),
                              selected: _periodeFilter == type,
                              onSelected: (selected) {
                                setState(() {
                                  _periodeFilter = selected ? type : null;
                                });
                                setModalState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FilledButton.icon(
                          icon: const Icon(Icons.done),
                          label: const Text('Appliquer les filtres'),
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Boîte de dialogue pour prolonger une licence
  void _showExtendLicence(BuildContext context, String docId, Map<String, dynamic> data) {
    LicenceDuration extensionDuration = LicenceDuration.month;
    PeriodeType extensionPeriodeType = PeriodeType.values.firstWhere(
      (type) => type.value == (data['periodeType'] ?? 'month'),
      orElse: () => PeriodeType.month,
    );

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
                  DropdownButtonFormField<LicenceDuration>(
                    decoration: const InputDecoration(
                      labelText: 'Durée',
                      border: OutlineInputBorder(),
                    ),
                    value: extensionDuration,
                    items: LicenceDuration.values.map((duration) {
                      return DropdownMenuItem<LicenceDuration>(
                        value: duration,
                        child: Text(duration.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        extensionDuration = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PeriodeType>(
                    decoration: const InputDecoration(
                      labelText: 'Type de période',
                      border: OutlineInputBorder(),
                    ),
                    value: extensionPeriodeType,
                    items: PeriodeType.values.map((type) {
                      return DropdownMenuItem<PeriodeType>(
                        value: type,
                        child: Text(type.label),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _extendLicence(docId, extensionDuration.days, extensionPeriodeType.value);
                  },
                  child: const Text('Prolonger'),
                ),
              ],
            );
          },
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
          icon: const Icon(Icons.warning_amber_rounded, size: 48),
          title: const Text('Révoquer la licence'),
          content: const Text(
            'Êtes-vous sûr de vouloir révoquer cette licence ? '
            'Elle sera marquée comme expirée immédiatement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
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
          icon: Icon(Icons.delete_forever, size: 48, color: Colors.red.shade400),
          title: const Text('Supprimer la licence'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer définitivement cette licence ? '
            'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
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

// Widget séparé pour la carte de génération de licence
class _LicenceGeneratorCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final LicenceDuration selectedDuration;
  final LicenceType selectedLicenceType;
  final PeriodeType selectedPeriodeType;
  final bool isGenerating;
  final String? lastGeneratedLicence;
  final ValueChanged<LicenceDuration> onDurationChanged;
  final ValueChanged<LicenceType> onLicenceTypeChanged;
  final ValueChanged<PeriodeType> onPeriodeTypeChanged;
  final VoidCallback onGenerateLicence;
  final ValueChanged<String> onCopyLicence;

  const _LicenceGeneratorCard({
    required this.formKey,
    required this.selectedDuration,
    required this.selectedLicenceType,
    required this.selectedPeriodeType,
    required this.isGenerating,
    required this.lastGeneratedLicence,
    required this.onDurationChanged,
    required this.onLicenceTypeChanged,
    required this.onPeriodeTypeChanged,
    required this.onGenerateLicence,
    required this.onCopyLicence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Générer une nouvelle licence',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<LicenceType>(
                decoration: const InputDecoration(
                  labelText: 'Type de licence',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                value: selectedLicenceType,
                items: LicenceType.values.map((type) {
                  return DropdownMenuItem<LicenceType>(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (value) => onLicenceTypeChanged(value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PeriodeType>(
                decoration: const InputDecoration(
                  labelText: 'Type de période',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                ),
                value: selectedPeriodeType,
                items: PeriodeType.values.map((type) {
                  return DropdownMenuItem<PeriodeType>(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (value) => onPeriodeTypeChanged(value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<LicenceDuration>(
                decoration: const InputDecoration(
                  labelText: 'Durée de validité',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                value: selectedDuration,
                items: LicenceDuration.values.map((duration) {
                  return DropdownMenuItem<LicenceDuration>(
                    value: duration,
                    child: Text(duration.label),
                  );
                }).toList(),
                onChanged: (value) => onDurationChanged(value!),
              ),
              const SizedBox(height: 24),
              Center(
                child: FilledButton.icon(
                  icon: isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.key),
                  label: Text(isGenerating ? 'Génération en cours...' : 'Générer une licence'),
                  onPressed: isGenerating ? null : onGenerateLicence,
                ),
              ),
              if (lastGeneratedLicence != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Licence générée avec succès',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          lastGeneratedLicence!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Copier'),
                          onPressed: () => onCopyLicence(lastGeneratedLicence!),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget séparé pour la liste des licences
class _LicencesList extends StatelessWidget {
  final CollectionReference licencesCollection;
  final String statusFilter;
  final LicenceType? typeFilter;
  final PeriodeType? periodeFilter;
  final ValueChanged<String> onCopyLicence;
  final void Function(BuildContext, String, Map<String, dynamic>) onShowOptions;

  const _LicencesList({
    required this.licencesCollection,
    required this.statusFilter,
    required this.typeFilter,
    required this.periodeFilter,
    required this.onCopyLicence,
    required this.onShowOptions,
  });

  bool _matchesFilters(Map<String, dynamic> data) {
    final expiryDate = (data['expiryDate'] as Timestamp).toDate();
    final isExpired = expiryDate.isExpired;

    // Filtre par statut
    if (statusFilter == 'valid' && isExpired) return false;
    if (statusFilter == 'expired' && !isExpired) return false;

    // Filtre par type de licence
    if (typeFilter != null) {
      final licenceType = data['licenceType'] as String?;
      if (licenceType != typeFilter!.value) return false;
    }

    // Filtre par type de période
    if (periodeFilter != null) {
      final periodeType = data['periodeType'] as String?;
      if (periodeType != periodeFilter!.value) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: licencesCollection.orderBy('generationDate', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Aucune licence trouvée',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        // Appliquer les filtres
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _matchesFilters(data);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list_off, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Aucune licence ne correspond aux filtres',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Essayez de modifier vos critères de filtrage',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _LicenceCard(
              data: data,
              docId: doc.id,
              onCopyLicence: onCopyLicence,
              onShowOptions: (docId, data) => onShowOptions(context, docId, data),
            );
          },
        );
      },
    );
  }
}

// Widget séparé pour chaque carte de licence
class _LicenceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final ValueChanged<String> onCopyLicence;
  final void Function(String, Map<String, dynamic>) onShowOptions;

  const _LicenceCard({
    required this.data,
    required this.docId,
    required this.onCopyLicence,
    required this.onShowOptions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final generationDate = (data['generationDate'] as Timestamp).toDate();
    final expiryDate = (data['expiryDate'] as Timestamp).toDate();
    final isExpired = expiryDate.isExpired;
    final daysLeft = expiryDate.daysUntil;
    final dateFormat = DateFormat('dd/MM/yyyy');

    Color getStatusColor() {
      if (isExpired) return theme.colorScheme.error;
      if (daysLeft < 30) return Colors.orange;
      return theme.colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isExpired ? 0 : 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: SelectableText(
                data['code'] ?? '',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isExpired ? theme.disabledColor : theme.colorScheme.onSurface,
                  decoration: isExpired ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () => onCopyLicence(data['code']),
              tooltip: 'Copier la clé',
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.label, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text('${data['licenceType'] ?? 'Non spécifié'}'),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text('${data['periodeType'] ?? 'Non spécifié'}'),
              ],
            ),
            const SizedBox(height: 4),
            Text('Généré: ${dateFormat.format(generationDate)}'),
            Text('Expire: ${dateFormat.format(expiryDate)}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: getStatusColor().withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                isExpired ? 'Expirée' : 'Valide ($daysLeft j restants)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: getStatusColor(),
                ),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => onShowOptions(docId, data),
        ),
      ),
    );
  }
}


