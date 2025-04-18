import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'NotificationProvider.dart';
import 'NotificationService.dart' as NS;

class NotificationPanel extends StatefulWidget {
  @override
  _NotificationPanelState createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: 100, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Lancer l'animation à l'ouverture
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Méthode pour fermer le panneau avec animation
  void _closePanel(BuildContext context) {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF3F51B5); // Indigo

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              elevation: 16,
              child: Container(
                width: 500,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(-5, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(context, notificationProvider, isDark, primaryColor),
                    Expanded(
                      child: _buildNotificationList(
                          context,
                          notificationProvider,
                          isDark,
                          primaryColor
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context,
      NotificationProvider notificationProvider,
      bool isDark,
      Color primaryColor
      ) {
    return Hero(
      tag: 'notification_header',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF263238)
              : primaryColor.withOpacity(0.08),
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_none,
                  color: isDark ? Colors.white70 : primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (notificationProvider.nonLuesCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${notificationProvider.nonLuesCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                if (notificationProvider.nonLuesCount > 0)
                  TextButton.icon(
                    onPressed: () {
                      notificationProvider.marquerToutesCommeLues();
                    },
                    icon: Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: primaryColor,
                    ),
                    label: Text(
                      'Tout marquer comme lu',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () => _closePanel(context),
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(
      BuildContext context,
      NotificationProvider notificationProvider,
      bool isDark,
      Color primaryColor
      ) {
    if (notificationProvider.notifications.isEmpty) {
      return Center(
        child: AnimatedOpacity(
          opacity: _fadeAnimation.value,
          duration: const Duration(milliseconds: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 64,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                'Pas de notifications',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: notificationProvider.notifications.length,
        itemBuilder: (context, index) {
          final notification = notificationProvider.notifications[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildNotificationItem(
                  context,
                  notification,
                  isDark,
                  primaryColor,
                  notificationProvider,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context,
      NS.Notification notification,
      bool isDark,
      Color primaryColor,
      NotificationProvider provider,
      ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _confirmerSuppression(context, isDark);
      },
      onDismissed: (direction) {
        _supprimerNotification(context, notification.id, provider);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: notification.estLu
              ? (isDark ? Colors.transparent : Colors.white)
              : (isDark
              ? primaryColor.withOpacity(0.15)
              : primaryColor.withOpacity(0.08)),
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // Marquer comme lu
              if (!notification.estLu) {
                await provider.marquerCommeLue(notification.id);
              }
              // Afficher le contenu de la notification dans une boîte de dialogue
              _afficherDetails(context, notification, isDark, primaryColor);
            },
            splashColor: primaryColor.withOpacity(0.1),
            highlightColor: primaryColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: notification.estLu
                          ? primaryColor.withOpacity(0.15)
                          : primaryColor.withOpacity(0.3),
                      child: Icon(
                        Icons.message_outlined,
                        color: notification.estLu
                            ? (isDark ? Colors.white70 : primaryColor)
                            : primaryColor,
                        size: 20,
                      ),
                    ),
                    if (!notification.estLu)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  notification.titre,
                  style: TextStyle(
                    fontWeight: notification.estLu ? FontWeight.normal : FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      notification.contenu,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(notification.dateEnvoi),
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!notification.estLu)
                      IconButton(
                        icon: Icon(
                          Icons.check_circle_outline,
                          size: 20,
                          color: primaryColor,
                        ),
                        onPressed: () => provider.marquerCommeLue(notification.id),
                        tooltip: 'Marquer comme lu',
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                      onPressed: () async {
                        final confirme = await _confirmerSuppression(context, isDark);
                        if (confirme) {
                          _supprimerNotification(context, notification.id, provider);
                        }
                      },
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmerSuppression(BuildContext context, bool isDark) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF263238) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirmation',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'Voulez-vous vraiment supprimer cette notification ?',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Supprimer',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
          elevation: 10,
        );
      },
    ) ?? false;
  }

  void _supprimerNotification(
      BuildContext context,
      String notificationId,
      NotificationProvider provider,
      ) {
    provider.supprimerNotification(notificationId).then((success) {
      if (success) {
        _afficherSnackBar(
            context,
            'Notification supprimée',
            Colors.green,
            Icons.check_circle
        );
      } else {
        _afficherSnackBar(
            context,
            'Erreur lors de la suppression',
            Colors.red,
            Icons.error_outline
        );
      }
    });
  }

  void _afficherSnackBar(
      BuildContext context,
      String message,
      Color backgroundColor,
      IconData iconData
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
    );
  }

  void _afficherDetails(
      BuildContext context,
      NS.Notification notification,
      bool isDark,
      Color primaryColor
      ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    void supprimerNotification() async {
      Navigator.of(context).pop();

      final success = await notificationProvider.supprimerNotification(notification.id);

      if (success) {
        _afficherSnackBar(
            context,
            'Notification supprimée',
            Colors.green,
            Icons.check_circle
        );
      } else {
        _afficherSnackBar(
            context,
            'Erreur lors de la suppression',
            Colors.red,
            Icons.error_outline
        );
      }
    }

    Future<void> confirmerEtSupprimer() async {
      final confirme = await _confirmerSuppression(context, isDark);
      if (confirme) {
        supprimerNotification();
      }
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Détails de la notification",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: isDark ? const Color(0xFF263238) : Colors.white,
              elevation: 20,
              child: Container(
                width: 600,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.titre,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: confirmerEtSupprimer,
                              tooltip: 'Supprimer',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: isDark ? Colors.white70 : Colors.black54,
                                size: 20,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: 'Fermer',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 14,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(notification.dateEnvoi),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.2)
                            : primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : primaryColor.withOpacity(0.1),
                        ),
                      ),
                      child: SelectableLinkify(
                        text: notification.contenu,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.6,
                        ),
                        linkStyle: TextStyle(
                          color: primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                        onOpen: (link) async {
                          if (await canLaunch(link.url)) {
                            await launch(link.url);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.check_circle,
                          size: 18,
                          color: primaryColor,
                        ),
                        label: Text(
                          'OK',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}