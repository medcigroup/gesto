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
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _licenceInputController.dispose();
    super.dispose();
  }

  Timestamp _calculateExpiryDate(String periodeType) {
    final now = DateTime.now();
    DateTime expiryDate;

    switch (periodeType) {
      case "month":
        expiryDate = now.add(const Duration(days: 30));
        break;
      case "6months":
        expiryDate = now.add(const Duration(days: 182));
        break;
      case "year":
        expiryDate = now.add(const Duration(days: 365));
        break;
      default:
        expiryDate = now.add(const Duration(days: 30));
    }

    return Timestamp.fromDate(expiryDate);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _activateLicence() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final licenceCode = _licenceInputController.text.trim();
      final cleanedLicenceCode = licenceCode.replaceAll('-', '');

      final licenceSnapshot = await FirebaseFirestore.instance
          .collection('licences')
          .where('code', isEqualTo: cleanedLicenceCode)
          .get();

      if (licenceSnapshot.docs.isEmpty) {
        _showSnackBar('Code de licence invalide.', isError: true);
        return;
      }

      final licenceData = licenceSnapshot.docs.first.data();
      final generationDate = licenceData['generationDate'];
      final periodeType = licenceData['periodeType'];
      final licenceType = licenceData['licenceType'];

      if (generationDate == null || periodeType == null) {
        _showSnackBar('Données de licence incomplètes.', isError: true);
        return;
      }

      final finalExpiryDate = _calculateExpiryDate(periodeType);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showSnackBar('Utilisateur non connecté.', isError: true);
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'licence': cleanedLicenceCode,
        'licenceGenerationDate': generationDate,
        'licenceExpiryDate': finalExpiryDate,
        'licenceType': licenceType,
        'plan': licenceType,
      });

      await FirebaseFirestore.instance
          .collection('licences')
          .doc(licenceSnapshot.docs.first.id)
          .delete();

      _showSnackBar('Licence activée avec succès.');

      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.renewlicencePage);
      }
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Activer une licence',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Icon and welcome text
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.vpn_key_rounded,
                    size: 64,
                    color: theme.primaryColor,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Entrez votre code de licence',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Saisissez le code reçu pour activer votre licence',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Licence input field
                TextFormField(
                  controller: _licenceInputController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Code de licence',
                    hintText: '####-####-####-####',
                    prefixIcon: const Icon(Icons.vpn_key),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    MaskTextInputFormatter(
                      mask: '####-####-####-####',
                      filter: {"#": RegExp(r'[0-9a-zA-Z]')},
                      type: MaskAutoCompletionType.lazy,
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir un code de licence';
                    }
                    final cleanedValue = value.replaceAll('-', '');
                    if (cleanedValue.length < 16) {
                      return 'Le code de licence doit contenir 16 caractères';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Activate button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _activateLicence,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Activer la licence',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Le code de licence est composé de 16 caractères alphanumériques séparés par des tirets.',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}