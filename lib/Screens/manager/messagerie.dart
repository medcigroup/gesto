import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../components/messagerie/NotificationProvider.dart';
import '../../config/UserModel.dart';

// Les modèles et services restent les mêmes
class Message {
  final String id;
  final String titre;
  final String contenu;
  final String expediteurId;
  final List<String> destinatairesIds;
  final DateTime dateEnvoi;
  final bool estMessageGroupe;

  Message({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.expediteurId,
    required this.destinatairesIds,
    required this.dateEnvoi,
    required this.estMessageGroupe,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'contenu': contenu,
      'expediteurId': expediteurId,
      'destinatairesIds': destinatairesIds,
      'dateEnvoi': dateEnvoi,
      'estMessageGroupe': estMessageGroupe,
    };
  }
}

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> getUtilisateurs() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  Future<bool> envoyerMessage({
    required String titre,
    required String contenu,
    required String expediteurId,
    required List<String> destinatairesIds,
    required bool estMessageGroupe,
    required BuildContext context,
  }) async {
    try {
      final messageId = _firestore.collection('messages').doc().id;
      final message = Message(
        id: messageId,
        titre: titre,
        contenu: contenu,
        expediteurId: expediteurId,
        destinatairesIds: destinatairesIds,
        dateEnvoi: DateTime.now(),
        estMessageGroupe: estMessageGroupe,
      );

      await _firestore.collection('messages').doc(messageId).set(message.toJson());

      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

      for (String destinataireId in destinatairesIds) {
        await notificationProvider.envoyerNotification(
          titre: titre,
          contenu: contenu,
          destinataireId: destinataireId,
        );
      }

      return true;
    } catch (e) {
      print('Erreur lors de l\'envoi du message: $e');
      return false;
    }
  }
}

class MessageProvider with ChangeNotifier {
  final MessageService _messageService = MessageService();
  List<UserModel> _utilisateurs = [];
  List<UserModel> _utilisateursSelectionnes = [];
  bool _estModeGroupe = false;
  String _searchQuery = "";

  List<UserModel> get utilisateurs => _utilisateurs;
  List<UserModel> get utilisateursSelectionnes => _utilisateursSelectionnes;
  bool get estModeGroupe => _estModeGroupe;
  String get searchQuery => _searchQuery;

  // Filtrer les utilisateurs selon la recherche
  List<UserModel> get utilisateursFiltres {
    if (_searchQuery.isEmpty) return _utilisateurs;
    return _utilisateurs.where((user) =>
    user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        user.establishmentName.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  // Charger les utilisateurs
  Future<void> chargerUtilisateurs() async {
    _utilisateurs = await _messageService.getUtilisateurs();
    notifyListeners();
  }

  // Mettre à jour la recherche
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Sélectionner/désélectionner un utilisateur
  void toggleUtilisateur(UserModel utilisateur) {
    if (_utilisateursSelectionnes.any((u) => u.email == utilisateur.email)) {
      _utilisateursSelectionnes.removeWhere((u) => u.email == utilisateur.email);
    } else {
      _utilisateursSelectionnes.add(utilisateur);
    }
    notifyListeners();
  }

  // Changer le mode (groupe ou spécifique)
  void toggleModeGroupe() {
    _estModeGroupe = !_estModeGroupe;
    if (_estModeGroupe) {
      _utilisateursSelectionnes = List.from(_utilisateurs);
    } else {
      _utilisateursSelectionnes = [];
    }
    notifyListeners();
  }

  // Envoyer un message
  Future<bool> envoyerMessage({
    required String titre,
    required String contenu,
    required String expediteurId,
    required BuildContext context,
  }) async {
    if (_estModeGroupe) {
      return await _messageService.envoyerMessage(
        titre: titre,
        contenu: contenu,
        expediteurId: expediteurId,
        destinatairesIds: _utilisateurs.map((u) => u.email).toList(),
        estMessageGroupe: true,
        context: context,
      );
    } else {
      if (_utilisateursSelectionnes.isEmpty) return false;
      return await _messageService.envoyerMessage(
        titre: titre,
        contenu: contenu,
        expediteurId: expediteurId,
        destinatairesIds: _utilisateursSelectionnes.map((u) => u.email).toList(),
        estMessageGroupe: false,
        context: context,
      );
    }
  }
}

// Widget modernisé pour afficher la liste des utilisateurs
class ListeUtilisateurs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MessageProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      flex: 1,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.all(12),
        surfaceTintColor: colorScheme.surfaceTint,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et compteur
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Destinataires',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (!provider.estModeGroupe)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${provider.utilisateursSelectionnes.length} sélectionné(s)',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              SizedBox(height: 16),

              // Champ de recherche
              SearchBar(
                onChanged: (value) => provider.updateSearchQuery(value),
                hintText: 'Rechercher un utilisateur...',
                leading: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                trailing: provider.searchQuery.isNotEmpty ? [
                  IconButton(
                    icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                    onPressed: () => provider.updateSearchQuery(''),
                  ),
                ] : null,
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(colorScheme.surfaceVariant),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                padding: MaterialStateProperty.all(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
              ),

              SizedBox(height: 16),

              // Liste des utilisateurs
              Expanded(
                child: provider.utilisateursFiltres.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          provider.searchQuery.isEmpty
                              ? Icons.people_alt_outlined
                              : Icons.search_off,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        provider.searchQuery.isEmpty
                            ? 'Aucun utilisateur disponible'
                            : 'Aucun résultat trouvé',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        provider.searchQuery.isEmpty
                            ? 'Les utilisateurs apparaîtront ici'
                            : 'Essayez une autre recherche',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  itemCount: provider.utilisateursFiltres.length,
                  separatorBuilder: (context, index) => Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    final utilisateur = provider.utilisateursFiltres[index];
                    final estSelectionne = provider.utilisateursSelectionnes
                        .any((u) => u.email == utilisateur.email);

                    // Initiales pour l'avatar
                    final initiales = utilisateur.fullName
                        .split(' ')
                        .take(2)
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .join('')
                        .toUpperCase();

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: estSelectionne
                            ? colorScheme.primaryContainer.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: provider.estModeGroupe
                              ? null
                              : () => provider.toggleUtilisateur(utilisateur),
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                          enabled: !provider.estModeGroupe,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: estSelectionne
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceVariant,
                            foregroundColor: estSelectionne
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                            radius: 24,
                            child: Text(
                              initiales,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Text(
                            utilisateur.fullName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: estSelectionne
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      utilisateur.email,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.business_outlined,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      utilisateur.establishmentName,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: provider.estModeGroupe
                              ? Icon(
                            Icons.check_circle,
                            color: colorScheme.primary,
                          )
                              : Checkbox(
                            value: estSelectionne,
                            activeColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (value) {
                              provider.toggleUtilisateur(utilisateur);
                            },
                          ),
                        ),
                      ),
                    ));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget modernisé pour composer et envoyer un message
class ComposerMessage extends StatefulWidget {
  final String expediteurId;

  ComposerMessage({required this.expediteurId});

  @override
  _ComposerMessageState createState() => _ComposerMessageState();
}

class _ComposerMessageState extends State<ComposerMessage> {
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _envoiEnCours = false;
  int _caracteresRestants = 1000; // Limite fictive pour l'exemple

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_updateCaracteresRestants);
  }

  @override
  void dispose() {
    _messageController.removeListener(_updateCaracteresRestants);
    _titreController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _updateCaracteresRestants() {
    setState(() {
      _caracteresRestants = 1000 - _messageController.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MessageProvider>(context);
    final theme = Theme.of(context);

    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      flex: 2,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.all(12),
        surfaceTintColor: colorScheme.surfaceTint,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et sélecteur de mode
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nouveau Message',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Spécifique'),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Tous'),
                        icon: Icon(Icons.groups_outlined),
                      ),
                    ],
                    selected: {provider.estModeGroupe},
                    onSelectionChanged: (Set<bool> selection) {
                      if (selection.first != provider.estModeGroupe) {
                        provider.toggleModeGroupe();
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.selected)) {
                          return colorScheme.secondaryContainer;
                        }
                        return null;
                      }),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 6),

              // Mode actuel
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: provider.estModeGroupe
                      ? colorScheme.primaryContainer
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      provider.estModeGroupe ? Icons.groups : Icons.people,
                      size: 16,
                      color: provider.estModeGroupe
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSecondaryContainer,
                    ),
                    SizedBox(width: 8),
                    Text(
                      provider.estModeGroupe
                          ? 'Message à tous les utilisateurs'
                          : 'Message aux ${provider.utilisateursSelectionnes.length} utilisateur(s) sélectionné(s)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: provider.estModeGroupe
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Champ titre
              TextField(
                controller: _titreController,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: 'Quel est le sujet de votre message ?',
                  labelText: 'Titre',
                  prefixIcon: Icon(Icons.title_rounded, color: colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),

              SizedBox(height: 20),

              // Champ contenu
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outline),
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  child: Column(
                    children: [
                      // Barre d'outils de formatage (simulée)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.format_bold, size: 20),
                              onPressed: () {},
                              tooltip: 'Gras',
                              color: colorScheme.onSurfaceVariant,
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.format_italic, size: 20),
                              onPressed: () {},
                              tooltip: 'Italique',
                              color: colorScheme.onSurfaceVariant,
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.format_underlined, size: 20),
                              onPressed: () {},
                              tooltip: 'Souligné',
                              color: colorScheme.onSurfaceVariant,
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            VerticalDivider(width: 16, thickness: 1, indent: 4, endIndent: 4),
                            IconButton(
                              icon: Icon(Icons.format_list_bulleted, size: 20),
                              onPressed: () {},
                              tooltip: 'Liste à puces',
                              color: colorScheme.onSurfaceVariant,
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.format_list_numbered, size: 20),
                              onPressed: () {},
                              tooltip: 'Liste numérotée',
                              color: colorScheme.onSurfaceVariant,
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.attach_file, size: 20),
                              onPressed: () {},
                              tooltip: 'Pièce jointe',
                              color: colorScheme.onSurfaceVariant,
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.emoji_emotions_outlined, size: 20),
                              onPressed: () {},
                              tooltip: 'Emoji',
                              color: colorScheme.onSurfaceVariant,
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Champ de texte
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          expands: true,
                          decoration: InputDecoration(
                            hintText: 'Rédigez votre message ici...',
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),

                      // Compteur de caractères
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              _caracteresRestants < 100
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline,
                              size: 14,
                              color: _caracteresRestants < 100
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '$_caracteresRestants caractères restants',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _caracteresRestants < 100
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: _caracteresRestants < 100
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Boutons d'action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Erreur si aucun destinataire n'est sélectionné
                  if (!provider.estModeGroupe && provider.utilisateursSelectionnes.isEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: colorScheme.onErrorContainer,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Sélectionnez au moins un destinataire',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Spacer(),

                  // Bouton d'annulation
                  OutlinedButton.icon(
                    onPressed: () {
                      _titreController.clear();
                      _messageController.clear();
                    },
                    icon: Icon(Icons.delete_outline),
                    label: Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: colorScheme.outline),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  // Bouton d'envoi
                  FilledButton.icon(
                    onPressed: _envoiEnCours ||
                        (_messageController.text.trim().isEmpty) ||
                        (_titreController.text.trim().isEmpty) ||
                        (!provider.estModeGroupe && provider.utilisateursSelectionnes.isEmpty)
                        ? null
                        : () async {
                      setState(() {
                        _envoiEnCours = true;
                      });

                      final resultat = await provider.envoyerMessage(
                        titre: _titreController.text.trim(),
                        contenu: _messageController.text.trim(),
                        expediteurId: widget.expediteurId,
                        context: context,
                      );

                      setState(() {
                        _envoiEnCours = false;
                      });

                      if (resultat) {
                        _titreController.clear();
                        _messageController.clear();

                        // Message de succès plus moderne
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: colorScheme.onPrimaryContainer),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    provider.estModeGroupe
                                        ? 'Message envoyé à tous les utilisateurs'
                                        : 'Message envoyé à ${provider.utilisateursSelectionnes.length} destinataire(s)',
                                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: colorScheme.primaryContainer,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: colorScheme.primary,
                              onPressed: () {},
                            ),
                          ),
                        );
                      } else {
                        // Message d'erreur plus moderne
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.error_outline_rounded, color: colorScheme.onErrorContainer),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Erreur lors de l\'envoi du message',
                                    style: TextStyle(color: colorScheme.onErrorContainer),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: colorScheme.errorContainer,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    icon: _envoiEnCours
                        ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Icon(Icons.send_rounded),
                    label: Text(_envoiEnCours ? 'Envoi...' : 'Envoyer'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget pour les boutons de mode dans le composeur
class _ModeButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// Composant principal modernisé
class PageMessagerieComponent extends StatefulWidget {
  final String expediteurId;

  const PageMessagerieComponent({
    Key? key,
    required this.expediteurId,
  }) : super(key: key);

  @override
  _PageMessagerieComponentState createState() => _PageMessagerieComponentState();
}

class _PageMessagerieComponentState extends State<PageMessagerieComponent> with SingleTickerProviderStateMixin {
  bool _chargementEnCours = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _chargerDonnees();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    final provider = Provider.of<MessageProvider>(context, listen: false);
    await provider.chargerUtilisateurs();
    if (mounted) {
      setState(() {
        _chargementEnCours = false;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messagerie',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 3,
        actions: [
          // Badge avec notifications (pour montrer l'aspect moderne)
          Badge(
            label: Text('3'),
            child: IconButton(
              icon: Icon(Icons.notifications_outlined),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _chargementEnCours = true;
              });
              _chargerDonnees();
            },
            tooltip: 'Actualiser',
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'archives',
                child: ListTile(
                  leading: Icon(Icons.archive_outlined, size: 20),
                  title: Text('Archives'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined, size: 20),
                  title: Text('Paramètres'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help_outline_rounded, size: 20),
                  title: Text('Aide'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _chargementEnCours
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'Chargement des utilisateurs...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      )
          : Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
        ),
        child: FadeTransition(
          opacity: _animation,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message d'information sur l'utilisation
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Material(
                    elevation: 0,
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.secondaryContainer,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: theme.colorScheme.onSecondaryContainer,
                            size: 22,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Sélectionnez des destinataires à gauche ou activez le mode "Tous" pour envoyer à tout le monde.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Zone principale avec la liste et le composeur
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive: affichage vertical sur petits écrans
                      if (constraints.maxWidth < 800) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 400,
                                child: ListeUtilisateurs(),
                              ),
                              SizedBox(
                                height: 600,
                                child: ComposerMessage(expediteurId: widget.expediteurId),
                              ),
                            ],
                          ),
                        );
                      }
                      // Affichage horizontal sur grands écrans
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListeUtilisateurs(),
                          ComposerMessage(expediteurId: widget.expediteurId),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }}