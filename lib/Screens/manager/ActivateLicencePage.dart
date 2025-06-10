import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../config/routes.dart';

class ActivateLicencePage extends StatefulWidget {
  const ActivateLicencePage({Key? key}) : super(key: key);

  @override
  _ActivateLicencePageState createState() => _ActivateLicencePageState();
}

class _ActivateLicencePageState extends State<ActivateLicencePage> {
  final TextEditingController _licenceInputController = TextEditingController();
  bool _isLoading = false;

  // Fonction pour calculer la date d'expiration basée sur le type de licence
  Timestamp _calculateExpiryDate(String periodeType) {
    final now = DateTime.now();
    DateTime expiryDate;

    switch (periodeType) {
      case "month":
      // Ajouter 30 jours
        expiryDate = now.add(const Duration(days: 30));
        break;
      case "6months":
      // Ajouter 6 mois (approximativement 182 jours)
        expiryDate = now.add(const Duration(days: 182));
        break;
      case "year":
      // Ajouter 365 jours
        expiryDate = now.add(const Duration(days: 365));
        break;
      default:
      // Pour tout autre type, utiliser 30 jours par défaut
        expiryDate = now.add(const Duration(days: 30));
    }

    return Timestamp.fromDate(expiryDate);
  }

  Future<void> _activateLicence(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final licenceCode = _licenceInputController.text.trim();
      if (licenceCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez saisir un code de licence.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Supprimer les tirets du code saisi par l'utilisateur
      final cleanedLicenceCode = licenceCode.replaceAll('-', '');

      try {
        final licenceSnapshot = await FirebaseFirestore.instance
            .collection('licences')
            .where('code', isEqualTo: cleanedLicenceCode)
            .get();

        if (licenceSnapshot.docs.isEmpty) {
          throw Exception('Code de licence invalide.');
        }

        final licenceData = licenceSnapshot.docs.first.data();

        // Vérification des valeurs null
        final generationDate = licenceData['generationDate'];
        final periodeType = licenceData['periodeType'];
        final licenceType = licenceData['licenceType'];

        if (generationDate == null || periodeType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Données de licence incomplètes.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Calculer la date d'expiration basée sur le type de licence
        final finalExpiryDate = _calculateExpiryDate(periodeType);

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Utilisateur non connecté.');

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'licence': cleanedLicenceCode,
          'licenceGenerationDate': generationDate,
          'licenceExpiryDate': finalExpiryDate, // Utiliser la date d'expiration calculée
          'licenceType': licenceType,
          'plan': licenceType,
        });

        await FirebaseFirestore.instance
            .collection('licences')
            .doc(licenceSnapshot.docs.first.id)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Licence activée avec succès.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        // Navigation après l'activation réussie
        Navigator.pushNamed(context, AppRoutes.renewlicencePage);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'activation de la licence: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Une erreur est survenue: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activer une licence'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _licenceInputController,
              decoration: const InputDecoration(labelText: 'Code de licence'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                MaskTextInputFormatter(
                  mask: '####-####-####-####',
                  filter: {"#": RegExp(r'[0-9a-zA-Z]')},
                  type: MaskAutoCompletionType.lazy,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _activateLicence(context),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Activer la licence'),
            ),
          ],
        ),
      ),
    );
  }
}