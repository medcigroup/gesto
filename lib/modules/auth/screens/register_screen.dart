import 'dart:async';
import 'dart:ui';
import 'package:flutter/animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../config/routes.dart';
import '../../../../../config/theme.dart';
import '../../../config/CodeEntrepriseGenerator.dart';
import '../../../config/HotelSettingsService.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  // Contrôleurs de texte
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _establishmentNameController = TextEditingController();
  final _establishmentAddressController = TextEditingController();
  final _employeeCountController = TextEditingController();

  // Variables d'état
  String _establishmentType = 'hotel_restaurant';
  String _userRole = 'manager';
  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _establishmentNameController.dispose();
    _establishmentAddressController.dispose();
    _employeeCountController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Vérifiez uniquement les champs essentiels pour Firebase
    if (_emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text &&
        _acceptTerms) {

      setState(() => _isLoading = true);

      try {
        // Création du compte
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Générer un code entreprise unique
        final entrepriseData = await CodeEntrepriseGenerator.generateUniqueCode(
          _establishmentNameController.text.trim(),
          email,
          _phoneController.text.trim(),
        );

        // Sauvegarde des données utilisateur
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'fullName': _fullNameController.text.trim(),
          'email': email,
          'phone': _phoneController.text.trim(),
          'establishmentName': _establishmentNameController.text.trim(),
          'establishmentAddress': _establishmentAddressController.text.trim(),
          'establishmentType': _establishmentType,
          'userRole': _userRole,
          'employeeCount': _employeeCountController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'entrepriseCode': entrepriseData['code'],
        });

        // Utilisation du service pour définir les paramètres par défaut
        final hotelSettingsService = HotelSettingsService();
        await hotelSettingsService.saveHotelSettings(
          hotelName : _establishmentNameController.text.trim(),
          address : _establishmentAddressController.text.trim(),
          phoneNumber : _phoneController.text.trim(),
          email : email,
          currency: "FCFA",
          checkInTime: "12:00",
          checkOutTime: "10:00",
          roomTypes: ["Standard", "Deluxe", "Suite"],
          depositPercentage: 30,
          otherSettings: {},
        );

        // Mise à jour du nom d'affichage
        await userCredential.user!.updateDisplayName(
            _fullNameController.text.trim());

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, AppRoutes.choosePlan);
      } on FirebaseAuthException catch (e) {
        _showErrorSnackbar(_getAuthErrorMessage(e));
      } catch (e) {
        _showErrorSnackbar('Une erreur inattendue s\'est produite');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (!_acceptTerms) {
      _showErrorSnackbar('Veuillez accepter les conditions');
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Mot de passe trop faible';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _showSuccessDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            title: const Text('Succès'),
            content: const Text('Votre compte a été créé avec succès !'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continuer'),
              ),
            ],
          ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(color: Colors.black.withOpacity(0.3)),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: GestoTheme.navyBlue.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 1.0 + (value * 0.2),
                      child: child,
                    );
                  },
                  child: Icon(
                    Icons.home_work,
                    size: 60,
                    color: GestoTheme.gold,
                  ),
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(GestoTheme.gold),
                  strokeWidth: 5,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Création de votre compte...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Veuillez patienter quelques instants',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Informations personnelles
        return _fullNameController.text.isNotEmpty &&
            _userRole.isNotEmpty;
      case 1: // Informations de l'établissement
        return _establishmentNameController.text.isNotEmpty &&
            _establishmentAddressController.text.isNotEmpty &&
            _establishmentType.isNotEmpty &&
            _employeeCountController.text.isNotEmpty;
      case 2: // Sécurité et confirmation
        return _emailController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _passwordController.text == _confirmPasswordController.text &&
            _acceptTerms;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;
    final theme = Theme.of(context);
    final isMobile = size.width < 800;

    // Création des étapes du formulaire
    List<Step> formSteps = [
      // Étape 1: Informations personnelles
      Step(
        title: const Text('Informations personnelles'),
        content: Form(
          key: _formKeyStep1,
          child: Column(
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom complet';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  prefixIcon: Icon(Icons.work_outline),
                  border: OutlineInputBorder(),
                ),
                value: _userRole,
                items: const [
                  DropdownMenuItem(
                    value: 'manager',
                    child: Text('Manager / Gérant'),
                  ),
                  DropdownMenuItem(
                    value: 'owner',
                    child: Text('Propriétaire'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _userRole = value);
                  }
                },
              ),
            ],
          ),
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),

      // Étape 2: Informations de l'établissement
      Step(
        title: const Text('Informations de l\'établissement'),
        content: Form(
          key: _formKeyStep2,
          child: Column(
            children: [
              TextFormField(
                controller: _establishmentNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'établissement',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom de votre établissement';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _establishmentAddressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse de l\'établissement',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer l\'adresse de votre établissement';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Type d\'établissement',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                value: _establishmentType,
                items: const [
                  DropdownMenuItem(
                    value: 'hotel_restaurant',
                    child: Text('Hôtel et Restaurant'),
                  ),
                  DropdownMenuItem(
                    value: 'hotel',
                    child: Text('Hôtel uniquement'),
                  ),
                  DropdownMenuItem(
                    value: 'restaurant',
                    child: Text('Restaurant uniquement'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _establishmentType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeCountController,
                decoration: const InputDecoration(
                  labelText: 'Nombre d\'employés',
                  prefixIcon: Icon(Icons.people_outline),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez indiquer le nombre d\'employés';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),

      // Étape 3: Sécurité et confirmation
      Step(
        title: const Text('Sécurité et confirmation'),
        content: Form(
          key: _formKeyStep3,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(
                      value)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro de téléphone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons
                          .visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  if (value.length < 8) {
                    return 'Le mot de passe doit contenir au moins 8 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons
                          .visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez confirmer votre mot de passe';
                  }
                  if (value != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text(
                  'J\'accepte les conditions générales d\'utilisation et la politique de confidentialité',
                  style: TextStyle(fontSize: 14),
                ),
                value: _acceptTerms,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _acceptTerms = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];

    return Stack(
      children: [
        Scaffold(
          body: Row(
            children: [
              if (!isMobile)
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: GestoTheme.navyBlue,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_work,
                          size: 120,
                          color: GestoTheme.gold,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'GESTO',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: GestoTheme.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Text(
                            'Plateforme modulaire de gestion hôtelière et de restauration',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: GestoTheme.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                flex: isMobile ? 1 : 4,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 64,
                    vertical: 32,
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isMobile) ...[
                            Center(
                              child: Icon(
                                Icons.home_work,
                                size: 80,
                                color: GestoTheme.navyBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'GESTO',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: GestoTheme.navyBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                          Text(
                            'Créer un compte',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Veuillez remplir les champs ci-dessous pour créer votre compte',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Dans la méthode build(), modifiez le onStepContinue
                          Stepper(
                            currentStep: _currentStep,
                            onStepContinue: () {
                              bool isStepValid = false;
                              switch (_currentStep) {
                                case 0:
                                  isStepValid = _formKeyStep1.currentState!.validate();
                                  break;
                                case 1:
                                  isStepValid = _formKeyStep2.currentState!.validate();
                                  break;
                                case 2:
                                  isStepValid = _formKeyStep3.currentState!.validate() && _acceptTerms; // Ajouter _acceptTerms
                                  break;
                              }

                              if (isStepValid) {
                                if (_currentStep < formSteps.length - 1) {
                                  setState(() => _currentStep += 1);
                                } else {
                                  _register();
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Veuillez remplir tous les champs obligatoires et accepter les conditions'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            onStepCancel: () {
                              if (_currentStep > 0) {
                                setState(() => _currentStep -= 1);
                              }
                            },
                            steps: formSteps,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Vous avez déjà un compte?',
                                style: theme.textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacementNamed(
                                    AppRoutes.login,
                                  );
                                },
                                child: const Text('Se connecter'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isLoading) _buildLoadingOverlay(),
        if (_isLoading)
          IgnorePointer(
            ignoring: false,
            child: Container(color: Colors.transparent),
          ),
      ],
    );
  }
}