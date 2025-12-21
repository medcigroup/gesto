import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/remote_config_service.dart';
import 'config/routes.dart';

class GestoMobileDownloadPage extends StatefulWidget {
  const GestoMobileDownloadPage({super.key});

  @override
  State<GestoMobileDownloadPage> createState() => _GestoMobileDownloadPageState();
}

class _GestoMobileDownloadPageState extends State<GestoMobileDownloadPage> {
  static const _primaryColor = Color(0xFF263238);
  static const _accentColor = Color(0xFF4CAF50);
  static const _betaColor = Color(0xFFFF9800);
  static const _padding = 20.0;
  static const _spacing = 16.0;
  static const _borderRadius = 16.0;

  bool _isDownloading = false;
  bool _isLoading = true;
  bool _isBetaSelected = false;

  final RemoteConfigService _remoteConfig = RemoteConfigService();
  ApkVersionInfo? _stableVersion;
  ApkVersionInfo? _betaVersion;

  @override
  void initState() {
    super.initState();
    _loadRemoteConfig();
  }

  Future<void> _loadRemoteConfig() async {
    setState(() => _isLoading = true);

    try {
      await _remoteConfig.initialize();
      _stableVersion = _remoteConfig.getVersionInfo(false);
      _betaVersion = _remoteConfig.getVersionInfo(true);
      if (!(_betaVersion?.isAvailable ?? false)) _isBetaSelected = false;
    } catch (e) {
      if (mounted) _showSnackBar('Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ApkVersionInfo get _selectedVersion =>
      _isBetaSelected && (_betaVersion?.isAvailable ?? false)
          ? _betaVersion!
          : _stableVersion!;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _accentColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _downloadApk() async {
    if (_selectedVersion.url.isEmpty) {
      _showSnackBar('Aucune URL de téléchargement disponible', isError: true);
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final url = Uri.parse(_selectedVersion.url);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) _showSnackBar('Téléchargement lancé...');
      } else {
        throw 'Impossible d\'ouvrir le lien';
      }
    } catch (e) {
      if (mounted) _showSnackBar('Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildHeroSection(),
                      const SizedBox(height: 40),
                      _buildValueProposition(),
                      const SizedBox(height: 40),
                      _buildKeyFeatures(),
                      const SizedBox(height: 40),
                      _buildRolesSection(),
                      const SizedBox(height: 40),
                      _buildDownloadSection(),
                      if (_selectedVersion.getChangelog()?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 40),
                        _buildChangelog(),
                      ],
                      const SizedBox(height: 40),
                      _buildFAQSection(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: _primaryColor),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.phone_android, color: _accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Gesto Mobile',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _padding, vertical: 40),
      child: Column(
        children: [
          // Badge "Nouvelle application"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentColor.withValues(alpha: 0.1), _betaColor.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: _accentColor, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Application Mobile disponible',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Titre principal
          const Text(
            'Gérez votre hôtel\ndepuis votre poche',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Sous-titre
          Text(
            'L\'application mobile qui transforme la gestion quotidienne de votre établissement',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Logo Gesto Mobile
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _accentColor.withValues(alpha: 0.1),
                  _betaColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/gesto_logo2.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueProposition() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _padding),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _primaryColor.withBlue(100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: Column(
        children: [
          const Icon(Icons.flash_on, color: Colors.amber, size: 32),
          const SizedBox(height: 16),
          const Text(
            'Pourquoi Gesto Mobile ?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildValuePoint(
            Icons.speed,
            'Réactivité maximale',
            'Prenez des commandes et gérez votre service en temps réel',
          ),
          const SizedBox(height: 16),
          _buildValuePoint(
            Icons.people,
            'Pour toute l\'équipe',
            'Serveurs, cuisiniers, barmans : chacun son interface optimisée',
          ),
          const SizedBox(height: 16),
          _buildValuePoint(
            Icons.sync_alt,
            'Synchronisation instantanée',
            'Connecté en permanence avec Gesto Web',
          ),
        ],
      ),
    );
  }

  Widget _buildValuePoint(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyFeatures() {
    final features = [
      {
        'icon': Icons.restaurant_menu,
        'title': 'Prise de commandes',
        'description': 'Interface intuitive pour commander rapidement depuis les tables',
        'color': const Color(0xFFFF9800),
      },
      {
        'icon': Icons.kitchen,
        'title': 'Gestion cuisine',
        'description': 'Suivez les préparations en temps réel et organisez votre production',
        'color': const Color(0xFF9C27B0),
      },
      {
        'icon': Icons.wine_bar,
        'title': 'Inventaire bar',
        'description': 'Gérez vos stocks de boissons avec alertes automatiques',
        'color': const Color(0xFF00BCD4),
      },
      {
        'icon': Icons.qr_code_scanner,
        'title': 'Badge QR Code',
        'description': 'Identification rapide du personnel et suivi des présences',
        'color': const Color(0xFF3F51B5),
      },
      {
        'icon': Icons.notifications_active,
        'title': 'Notifications',
        'description': 'Alertes en temps réel pour ne rien manquer',
        'color': Colors.red,
      },
      {
        'icon': Icons.offline_bolt,
        'title': 'Mode hors ligne',
        'description': 'Consultez les données même sans connexion',
        'color': _accentColor,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padding),
      child: Column(
        children: [
          const Text(
            'Fonctionnalités clés',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tout ce dont vous avez besoin au quotidien',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWeb = constraints.maxWidth > 600;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWeb ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWeb ? 1.15 : 1.1,
                ),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return _buildFeatureCard(
                    feature['icon'] as IconData,
                    feature['title'] as String,
                    feature['description'] as String,
                    feature['color'] as Color,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRolesSection() {
    final roles = [
      {
        'icon': Icons.restaurant_menu,
        'title': 'Serveur',
        'color': const Color(0xFFFF9800),
        'features': ['Prise de commandes rapide', 'Suivi des tables', 'Communication cuisine'],
      },
      {
        'icon': Icons.restaurant,
        'title': 'Chef / Cuisinier',
        'color': const Color(0xFF9C27B0),
        'features': ['Réception commandes', 'Gestion préparations', 'Priorisation des plats'],
      },
      {
        'icon': Icons.wine_bar,
        'title': 'Barman',
        'color': const Color(0xFF00BCD4),
        'features': ['Commandes boissons', 'Gestion inventaire', 'Suivi des stocks'],
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      color: Colors.grey[50],
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: _padding),
            child: Text(
              'Adapté à chaque rôle',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _padding),
            child: Text(
              'Une interface personnalisée pour chaque membre de l\'équipe',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _padding),
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final role = roles[index];
                return Container(
                  width: 280,
                  margin: EdgeInsets.only(right: index < roles.length - 1 ? 16 : 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_borderRadius),
                    border: Border.all(color: (role['color'] as Color).withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: (role['color'] as Color).withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(role['icon'] as IconData, color: role['color'] as Color, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            role['title'] as String,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: role['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...(role['features'] as List<String>).map((feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 16, color: role['color'] as Color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: const TextStyle(fontSize: 13, color: _primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padding),
      child: Column(
        children: [
          const Text(
            'Télécharger maintenant',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 24),

          // Sélecteur de version
          if (_betaVersion?.isAvailable ?? false) ...[
            Row(
              children: [
                Expanded(child: _buildVersionChip(false, 'Stable', _stableVersion, _accentColor, Icons.verified)),
                const SizedBox(width: 12),
                Expanded(child: _buildVersionChip(true, 'Beta', _betaVersion, _betaColor, Icons.science)),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Bouton de téléchargement
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accentColor, Color(0xFF45A049)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(_borderRadius),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.download_rounded, size: 48, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'Version ${_selectedVersion.versionLabel}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_selectedVersion.releaseDate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _selectedVersion.releaseDate,
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isDownloading ? null : _downloadApk,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isDownloading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_accentColor)),
                        )
                      else
                        const Icon(Icons.download_rounded, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        _isDownloading ? 'Téléchargement...' : 'Télécharger l\'APK',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.android, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Text(
                      'Android 8.0 et supérieur',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Instructions
          const SizedBox(height: 24),
          _buildInstallInstructions(),
        ],
      ),
    );
  }

  Widget _buildVersionChip(bool isBeta, String label, ApkVersionInfo? version, Color color, IconData icon) {
    final isSelected = _isBetaSelected == isBeta;
    return GestureDetector(
      onTap: () => setState(() => _isBetaSelected = isBeta),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isSelected ? color : Colors.grey[700],
                  ),
                ),
                if (version?.version.isNotEmpty ?? false)
                  Text(
                    'v${version!.version}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Installation rapide',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstallStep('1', 'Téléchargez le fichier APK'),
          _buildInstallStep('2', 'Autorisez les sources inconnues dans vos paramètres'),
          _buildInstallStep('3', 'Installez et connectez-vous avec vos identifiants'),
        ],
      ),
    );
  }

  Widget _buildInstallStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangelog() {
    final changelog = _selectedVersion.getChangelog()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.new_releases, color: _isBetaSelected ? _betaColor : _accentColor, size: 28),
              const SizedBox(width: 12),
              Text(
                'Nouveautés ${_selectedVersion.versionLabel}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(_borderRadius),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (changelog.features.isNotEmpty) _buildChangelogList('Nouveautés', changelog.features, _accentColor, Icons.star),
                if (changelog.fixes.isNotEmpty) _buildChangelogList('Corrections', changelog.fixes, Colors.red, Icons.bug_report),
                if (changelog.improvements.isNotEmpty) _buildChangelogList('Améliorations', changelog.improvements, Colors.blue, Icons.trending_up),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangelogList(String title, List<String> items, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      {
        'question': 'Ai-je besoin d\'un compte Gesto ?',
        'answer': 'Oui, vous devez avoir un compte Gesto actif et être enregistré comme employé dans l\'application web.',
      },
      {
        'question': 'L\'application fonctionne-t-elle hors ligne ?',
        'answer': 'Certaines fonctionnalités de consultation sont disponibles hors ligne. Les actions nécessitant une synchronisation requièrent une connexion.',
      },
      {
        'question': 'Quels appareils sont compatibles ?',
        'answer': 'Tous les smartphones et tablettes Android 8.0 (Oreo) ou version ultérieure.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Questions fréquentes',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          ...faqs.map((faq) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faq['question']!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      faq['answer']!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
