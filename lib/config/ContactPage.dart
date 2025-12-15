import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'AppConstants.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({Key? key}) : super(key: key);

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir $url'),
            backgroundColor: AppConstants.accentColor,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simuler l'envoi du formulaire
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message envoyé avec succès !'),
            backgroundColor: AppConstants.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Réinitialiser le formulaire
        _formKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _subjectController.clear();
        _messageController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > AppConstants.tabletBreakpoint;
    final isMobile = size.width < AppConstants.mobileBreakpoint;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppConstants.darkColor,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec dégradé
            FadeInDown(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppConstants.primaryColor,
                      AppConstants.primaryColor.withOpacity(0.8),
                      AppConstants.purpleAccent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 40 : 60,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    // Logo animé
                    ZoomIn(
                      child: Container(
                        width: isMobile ? 80 : 100,
                        height: isMobile ? 80 : 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 5,
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(15),
                        child: Image.asset(
                          AppConstants.logoPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Contactez-nous',
                      style: AppConstants.getHeadlineFont(color: Colors.white).copyWith(
                        fontSize: isMobile ? 28 : 36,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Notre équipe est à votre écoute',
                      style: AppConstants.getBodyFont(color: Colors.white.withOpacity(0.9)).copyWith(
                        fontSize: isMobile ? 14 : 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Contenu principal
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : (isDesktop ? 100 : 40),
              ),
              child: Column(
                children: [
                  // Cartes d'information de contact
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _buildContactCards(isMobile),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          flex: 6,
                          child: _buildContactForm(isMobile),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildContactCards(isMobile),
                        const SizedBox(height: 40),
                        _buildContactForm(isMobile),
                      ],
                    ),

                  const SizedBox(height: 60),

                  // Section des réseaux sociaux
                  _buildSocialSection(isMobile),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCards(bool isMobile) {
    return Column(
      children: [
        FadeInLeft(
          delay: const Duration(milliseconds: 200),
          child: _buildContactCard(
            icon: Icons.email_rounded,
            title: 'Email',
            subtitle: AppConstants.companyEmail,
            color: AppConstants.blueAccent,
            onTap: () => _launchUrl('mailto:${AppConstants.companyEmail}'),
          ),
        ),
        const SizedBox(height: 15),
        FadeInLeft(
          delay: const Duration(milliseconds: 400),
          child: _buildContactCard(
            icon: Icons.phone_rounded,
            title: 'Téléphone',
            subtitle: AppConstants.companyPhone,
            color: AppConstants.secondaryColor,
            onTap: () => _launchUrl('tel:${AppConstants.companyPhone}'),
          ),
        ),
        const SizedBox(height: 15),
        FadeInLeft(
          delay: const Duration(milliseconds: 600),
          child: _buildContactCard(
            icon: Icons.location_on_rounded,
            title: 'Adresse',
            subtitle: AppConstants.companyAddress,
            color: AppConstants.orangeAccent,
            onTap: null,
          ),
        ),
        const SizedBox(height: 15),
        FadeInLeft(
          delay: const Duration(milliseconds: 800),
          child: _buildContactCard(
            icon: Icons.support_agent_rounded,
            title: 'Support',
            subtitle: AppConstants.companySupportEmail,
            color: AppConstants.purpleAccent,
            onTap: () => _launchUrl('mailto:${AppConstants.companySupportEmail}'),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppConstants.getHeadlineFont().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppConstants.getBodyFont().copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm(bool isMobile) {
    return FadeInRight(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 20 : 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Envoyez-nous un message',
                style: AppConstants.getHeadlineFont().copyWith(
                  fontSize: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nous vous répondrons dans les plus brefs délais',
                style: AppConstants.getBodyFont().copyWith(fontSize: 14),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                controller: _nameController,
                label: 'Nom complet',
                hint: 'Votre nom',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'votre.email@exemple.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!value.contains('@')) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _subjectController,
                label: 'Sujet',
                hint: 'Objet de votre message',
                icon: Icons.subject_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un sujet';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _messageController,
                label: 'Message',
                hint: 'Votre message...',
                icon: Icons.message_outlined,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre message';
                  }
                  if (value.length < 10) {
                    return 'Le message doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Envoyer le message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.send_rounded, size: 20),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppConstants.getHeadlineFont().copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: AppConstants.primaryColor),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppConstants.accentColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSection(bool isMobile) {
    return FadeInUp(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 30 : 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor.withOpacity(0.05),
              AppConstants.purpleAccent.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
        child: Column(
          children: [
            Text(
              'Suivez-nous',
              style: AppConstants.getHeadlineFont().copyWith(
                fontSize: isMobile ? 20 : 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Restez connectés avec ${AppConstants.appName}',
              style: AppConstants.getBodyFont().copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              alignment: WrapAlignment.center,
              children: [
                _buildSocialButton(
                  icon: Icons.facebook_rounded,
                  color: const Color(0xFF1877F2),
                  onTap: () => _launchUrl(AppConstants.facebookUrl),
                ),
                _buildSocialButton(
                  icon: Icons.camera_alt_rounded,
                  color: const Color(0xFFE4405F),
                  onTap: () => _launchUrl(AppConstants.instagramUrl),
                ),
                _buildSocialButton(
                  icon: Icons.work_rounded,
                  color: const Color(0xFF0A66C2),
                  onTap: () => _launchUrl(AppConstants.linkedinUrl),
                ),
                _buildSocialButton(
                  icon: Icons.tag_rounded,
                  color: const Color(0xFF1DA1F2),
                  onTap: () => _launchUrl(AppConstants.twitterUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}