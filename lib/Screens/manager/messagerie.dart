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

    return Expanded(
      flex: 1,
      child: Card(
        elevation: 3,
        margin: EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!provider.estModeGroupe)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${provider.utilisateursSelectionnes.length} sélectionné(s)',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 16),

              // Champ de recherche
              TextField(
                onChanged: (value) => provider.updateSearchQuery(value),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Rechercher un utilisateur...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: theme.primaryColor, width: 1),
                  ),
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
                      Icon(Icons.people_alt_outlined, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        provider.searchQuery.isEmpty
                            ? 'Aucun utilisateur disponible'
                            : 'Aucun résultat trouvé',
                        style: TextStyle(color: Colors.grey[600]),
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

                    return ListTile(
                      enabled: !provider.estModeGroupe,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: estSelectionne
                            ? theme.primaryColor
                            : Colors.grey[300],
                        foregroundColor: estSelectionne
                            ? Colors.white
                            : Colors.grey[800],
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: estSelectionne
                              ? theme.primaryColor
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            utilisateur.email,
                            style: TextStyle(fontSize: 13),
                          ),
                          Text(
                            utilisateur.establishmentName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: provider.estModeGroupe
                          ? Icon(
                        Icons.check_circle,
                        color: theme.primaryColor,
                      )
                          : Checkbox(
                        value: estSelectionne,
                        activeColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (value) {
                          provider.toggleUtilisateur(utilisateur);
                        },
                      ),
                      onTap: provider.estModeGroupe
                          ? null
                          : () {
                        provider.toggleUtilisateur(utilisateur);
                      },
                    );
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

    return Expanded(
      flex: 2,
      child: Card(
        elevation: 3,
        margin: EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ModeButton(
                          text: 'Spécifique',
                          isActive: !provider.estModeGroupe,
                          onTap: () {
                            if (provider.estModeGroupe) provider.toggleModeGroupe();
                          },
                        ),
                        SizedBox(width: 8),
                        _ModeButton(
                          text: 'Tous',
                          isActive: provider.estModeGroupe,
                          onTap: () {
                            if (!provider.estModeGroupe) provider.toggleModeGroupe();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 6),

              // Mode actuel
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: provider.estModeGroupe
                      ? theme.primaryColor.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  provider.estModeGroupe
                      ? 'Message à tous les utilisateurs'
                      : 'Message aux ${provider.utilisateursSelectionnes.length} utilisateur(s) sélectionné(s)',
                  style: TextStyle(
                    color: provider.estModeGroupe ? theme.primaryColor : Colors.grey[800],
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
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
                  prefixIcon: Icon(Icons.title, color: theme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
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
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.all(16),
                ),
              ),

              SizedBox(height: 20),

              // Champ contenu
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      // Barre d'outils de formatage (simulée)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(11),
                            topRight: Radius.circular(11),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.format_bold, size: 20),
                              onPressed: () {},
                              tooltip: 'Gras',
                              color: Colors.grey[700],
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                            ),
                            IconButton(
                              icon: Icon(Icons.format_italic, size: 20),
                              onPressed: () {},
                              tooltip: 'Italique',
                              color: Colors.grey[700],
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                            ),
                            IconButton(
                              icon: Icon(Icons.format_underlined, size: 20),
                              onPressed: () {},
                              tooltip: 'Souligné',
                              color: Colors.grey[700],
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                            ),
                            VerticalDivider(width: 16, thickness: 1, indent: 4, endIndent: 4),
                            IconButton(
                              icon: Icon(Icons.format_list_bulleted, size: 20),
                              onPressed: () {},
                              tooltip: 'Liste à puces',
                              color: Colors.grey[700],
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                            ),
                            IconButton(
                              icon: Icon(Icons.format_list_numbered, size: 20),
                              onPressed: () {},
                              tooltip: 'Liste numérotée',
                              color: Colors.grey[700],
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.attach_file, size: 20),
                              onPressed: () {},
                              tooltip: 'Pièce jointe',
                              color: Colors.grey[700],
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                            ),
                            IconButton(
                              icon: Icon(Icons.emoji_emotions_outlined, size: 20),
                              onPressed: () {},
                              tooltip: 'Emoji',
                              color: Colors.grey[700],
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
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
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(11),
                            bottomRight: Radius.circular(11),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '$_caracteresRestants caractères restants',
                              style: TextStyle(
                                color: _caracteresRestants < 100 ? Colors.red : Colors.grey[600],
                                fontSize: 12,
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
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Sélectionnez au moins un destinataire',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 13,
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
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  // Bouton d'envoi
                  ElevatedButton.icon(
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    provider.estModeGroupe
                                        ? 'Message envoyé à tous les utilisateurs'
                                        : 'Message envoyé à ${provider.utilisateursSelectionnes.length} destinataire(s)',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green[600],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {},
                            ),
                          ),
                        );
                      } else {
                        // Message d'erreur plus moderne
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.white),
                                SizedBox(width: 16),
                                Expanded(child: Text('Erreur lors de l\'envoi du message')),
                              ],
                            ),
                            backgroundColor: Colors.red[600],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    icon: _envoiEnCours
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Icon(Icons.send),
                    label: Text(_envoiEnCours ? 'Envoi en cours...' : 'Envoyer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Badge avec notifications (pour montrer l'aspect moderne)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _chargementEnCours = true;
              });
              _chargerDonnees();
            },
            tooltip: 'Actualiser',
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'archives',
                child: Row(
                  children: [
                    Icon(Icons.archive, color: Colors.grey[700], size: 20),
                    SizedBox(width: 12),
                    Text('Archives'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey[700], size: 20),
                    SizedBox(width: 12),
                    Text('Paramètres'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.grey[700], size: 20),
                    SizedBox(width: 12),
                    Text('Aide'),
                  ],
                ),
              ),
            ],
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: _chargementEnCours
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
            SizedBox(height: 24),
            Text(
              'Chargement des utilisateurs...',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
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
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sélectionnez des destinataires à gauche ou activez le mode "Tous" pour envoyer à tout le monde.',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        InkWell(
                          onTap: () {},
                          child: Icon(Icons.close, color: Colors.blue[700], size: 16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ],
                    ),
                  ),
                ),

                // Zone principale avec la liste et le composeur
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListeUtilisateurs(),
                      ComposerMessage(expediteurId: widget.expediteurId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }}