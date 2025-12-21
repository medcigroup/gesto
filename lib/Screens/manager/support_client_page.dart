import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/AuthService.dart';
import '../../models/support_ticket.dart';
import '../../services/support_service.dart';


class SupportClientPage extends StatefulWidget {
  const SupportClientPage({Key? key}) : super(key: key);

  @override
  State<SupportClientPage> createState() => _SupportClientPageState();
}

class _SupportClientPageState extends State<SupportClientPage> {
  final SupportService _supportService = SupportService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: FutureBuilder<Map<String, String>>(
        future: _getUserInfo(authService),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userId = userSnapshot.data!['id']!;
          final userName = userSnapshot.data!['name']!;
          final userEmail = userSnapshot.data!['email']!;

          return Column(
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.support_agent_rounded,
                      size: 32,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Support',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Besoin d\'aide ? Contactez notre équipe',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des tickets
              Expanded(
                child: StreamBuilder<List<SupportTicket>>(
                  stream: _supportService.getUserTickets(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text('Erreur: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }

                    final tickets = snapshot.data ?? [];

                    if (tickets.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun ticket de support',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Créez un nouveau ticket pour obtenir de l\'aide',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return _buildTicketCard(ticket, isDark);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTicketSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau ticket'),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket, bool isDark) {
    // Vérifier s'il y a des messages admin non lus
    final hasUnreadAdminMessages = _hasUnreadAdminMessages(ticket);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasUnreadAdminMessages
            ? BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTicketDetails(ticket),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (hasUnreadAdminMessages)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notification_important,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            ticket.subject,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnreadAdminMessages 
                                  ? FontWeight.w900 
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(ticket.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPriorityBadge(ticket.priority),
                  const SizedBox(width: 8),
                  _buildCategoryBadge(ticket.category),
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(ticket.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (ticket.messages.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.message, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${ticket.messages.length} message(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TicketStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case TicketStatus.open:
        color = Colors.blue;
        label = 'Ouvert';
        icon = Icons.new_releases;
        break;
      case TicketStatus.inProgress:
        color = Colors.orange;
        label = 'En cours';
        icon = Icons.autorenew;
        break;
      case TicketStatus.waiting:
        color = Colors.purple;
        label = 'En attente';
        icon = Icons.schedule;
        break;
      case TicketStatus.resolved:
        color = Colors.green;
        label = 'Résolu';
        icon = Icons.check_circle;
        break;
      case TicketStatus.closed:
        color = Colors.grey;
        label = 'Fermé';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(TicketPriority priority) {
    Color color;
    String label;

    switch (priority) {
      case TicketPriority.urgent:
        color = Colors.red;
        label = 'Urgent';
        break;
      case TicketPriority.high:
        color = Colors.orange;
        label = 'Haute';
        break;
      case TicketPriority.medium:
        color = Colors.yellow[700]!;
        label = 'Moyenne';
        break;
      case TicketPriority.low:
        color = Colors.green;
        label = 'Basse';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(TicketCategory category) {
    String label;
    IconData icon;

    switch (category) {
      case TicketCategory.bug:
        label = 'Bug';
        icon = Icons.bug_report;
        break;
      case TicketCategory.feature:
        label = 'Fonctionnalité';
        icon = Icons.lightbulb;
        break;
      case TicketCategory.question:
        label = 'Question';
        icon = Icons.help;
        break;
      case TicketCategory.feedback:
        label = 'Feedback';
        icon = Icons.feedback;
        break;
      case TicketCategory.other:
        label = 'Autre';
        icon = Icons.more_horiz;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 11),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<Map<String, String>> _getUserInfo(AuthService authService) async {
    final user = await authService.getCurrentUser();
    final currentUser = FirebaseAuth.instance.currentUser;
    return {
      'id': currentUser?.uid ?? 'anonymous',
      'name': user?.fullName ?? 'Utilisateur',
      'email': user?.email ?? 'no-email@example.com',
    };
  }

  void _showCreateTicketSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: CreateTicketForm(
              scrollController: scrollController,
              supportService: _supportService,
            ),
          );
        },
      ),
    );
  }

  bool _hasUnreadAdminMessages(SupportTicket ticket) {
    // Pas de badge pour les tickets fermés
    if (ticket.status == TicketStatus.closed) return false;
    
    if (ticket.messages.isEmpty) return false;
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;
    
    DateTime? lastUserMessageTime;
    DateTime? lastAdminMessageTime;
    
    for (var message in ticket.messages) {
      if (message.isAdmin) {
        if (lastAdminMessageTime == null || message.timestamp.isAfter(lastAdminMessageTime)) {
          lastAdminMessageTime = message.timestamp;
        }
      } else if (message.senderId == userId) {
        if (lastUserMessageTime == null || message.timestamp.isAfter(lastUserMessageTime)) {
          lastUserMessageTime = message.timestamp;
        }
      }
    }
    
    // Si le dernier message est de l'admin et plus récent que le dernier message utilisateur
    if (lastAdminMessageTime != null) {
      return lastUserMessageTime == null || lastAdminMessageTime.isAfter(lastUserMessageTime);
    }
    
    return false;
  }

  void _showTicketDetails(SupportTicket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailsPage(
          ticket: ticket,
          supportService: _supportService,
        ),
      ),
    );
  }
}

// Formulaire de création de ticket
class CreateTicketForm extends StatefulWidget {
  final ScrollController scrollController;
  final SupportService supportService;

  const CreateTicketForm({
    Key? key,
    required this.scrollController,
    required this.supportService,
  }) : super(key: key);

  @override
  State<CreateTicketForm> createState() => _CreateTicketFormState();
}

class _CreateTicketFormState extends State<CreateTicketForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  TicketCategory _selectedCategory = TicketCategory.question;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titre
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, size: 28),
                SizedBox(width: 12),
                Text(
                  'Nouveau ticket de support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          // Formulaire
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Sujet *',
                      hintText: 'Résumez votre problème en quelques mots',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.subject),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le sujet est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Décrivez votre problème en détail',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La description est requise';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<TicketCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: TicketCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(_getCategoryLabel(category)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitTicket,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSubmitting ? 'Envoi...' : 'Créer le ticket'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(TicketCategory category) {
    switch (category) {
      case TicketCategory.bug:
        return '🐛 Bug';
      case TicketCategory.feature:
        return '💡 Fonctionnalité';
      case TicketCategory.question:
        return '❓ Question';
      case TicketCategory.feedback:
        return '📢 Feedback';
      case TicketCategory.other:
        return '📝 Autre';
    }
  }

  String _getPriorityLabel(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.urgent:
        return '🔴 Urgent';
      case TicketPriority.high:
        return '🟠 Haute';
      case TicketPriority.medium:
        return '🟡 Moyenne';
      case TicketPriority.low:
        return '🟢 Basse';
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();
      final currentUser = FirebaseAuth.instance.currentUser;

      await widget.supportService.createTicket(
        userId: currentUser?.uid ?? 'anonymous',
        userEmail: user?.email ?? 'no-email@example.com',
        userName: user?.fullName ?? 'Utilisateur',
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        // La priorité par défaut sera 'medium' (définie côté admin)
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

// Page de détails du ticket
class TicketDetailsPage extends StatefulWidget {
  final SupportTicket ticket;
  final SupportService supportService;

  const TicketDetailsPage({
    Key? key,
    required this.ticket,
    required this.supportService,
  }) : super(key: key);

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SupportTicket?>(
      stream: widget.supportService.getTicketStream(widget.ticket.id),
      initialData: widget.ticket,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erreur')),
            body: Center(
              child: Text('Erreur: ${snapshot.error}'),
            ),
          );
        }

        final ticket = snapshot.data ?? widget.ticket;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Détails du ticket'),
            actions: [
              if (ticket.status != TicketStatus.closed)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Fermer le ticket',
                  onPressed: _closeTicket,
                ),
            ],
          ),
          body: Column(
            children: [
              // En-tête du ticket
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.subject,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticket.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Créé le ${DateFormat('dd/MM/yyyy à HH:mm').format(ticket.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: ticket.messages.length,
                  itemBuilder: (context, index) {
                    final message = ticket.messages.reversed.toList()[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),

              // Zone de saisie ou message pour tickets fermés
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ticket.status == TicketStatus.closed
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ce ticket est fermé. Vous ne pouvez plus envoyer de messages.',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Votre message...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _isSending ? null : _sendMessage,
                            icon: _isSending
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(TicketMessage message) {
    final isAdmin = message.isAdmin;
    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isAdmin 
              ? Colors.grey[200]
              : Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAdmin ? Icons.support_agent : Icons.person,
                  size: 16,
                  color: isAdmin ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isAdmin ? Colors.blue : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message.message,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy à HH:mm').format(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    // Bloquer l'envoi si le ticket est fermé
    if (widget.ticket.status == TicketStatus.closed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ce ticket est fermé. Vous ne pouvez plus envoyer de messages.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();
      final currentUser = FirebaseAuth.instance.currentUser;

      await widget.supportService.addMessageToTicket(
        ticketId: widget.ticket.id,
        senderId: currentUser?.uid ?? 'anonymous',
        senderName: user?.fullName ?? 'Utilisateur',
        senderEmail: user?.email ?? 'no-email@example.com',
        isAdmin: false,
        message: _messageController.text.trim(),
      );

      _messageController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message envoyé !'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _closeTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fermer le ticket'),
        content: const Text('Êtes-vous sûr de vouloir fermer ce ticket ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await widget.supportService.updateTicketStatus(
          widget.ticket.id,
          TicketStatus.closed,
        );
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ticket fermé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
