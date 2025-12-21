import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/AuthService.dart';
import '../../models/support_ticket.dart';
import '../../services/support_service.dart';


class SupportAdminPage extends StatefulWidget {
  const SupportAdminPage({Key? key}) : super(key: key);

  @override
  State<SupportAdminPage> createState() => _SupportAdminPageState();
}

class _SupportAdminPageState extends State<SupportAdminPage> with SingleTickerProviderStateMixin {
  final SupportService _supportService = SupportService();
  late TabController _tabController;
  Map<String, int> _statistics = {};
  
  // Filtres et recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TicketPriority? _filterPriority;
  TicketCategory? _filterCategory;
  String _sortBy = 'date_desc'; // date_desc, date_asc, priority_high, priority_low
  bool _showOnlyUnread = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadStatistics();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    final stats = await _supportService.getTicketStatistics();
    if (mounted) {
      setState(() {
        _statistics = stats;
      });
    }
  }
  
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _filterPriority = null;
      _filterCategory = null;
      _sortBy = 'date_desc';
      _showOnlyUnread = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // En-tête avec statistiques
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 32,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Support - Administration',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Gérez tous les tickets de support',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadStatistics,
                      tooltip: 'Actualiser',
                    ),
                    IconButton(
                      icon: Icon(_showOnlyUnread ? Icons.mark_email_unread : Icons.mark_email_read),
                      onPressed: () {
                        setState(() {
                          _showOnlyUnread = !_showOnlyUnread;
                        });
                      },
                      tooltip: _showOnlyUnread ? 'Afficher tous' : 'Nouveaux messages seulement',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Barre de recherche et filtres
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un ticket...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.filter_list,
                        color: (_filterPriority != null || _filterCategory != null) 
                            ? theme.primaryColor 
                            : null,
                      ),
                      tooltip: 'Filtres',
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          enabled: false,
                          child: Text(
                            'Filtrer par priorité',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        ...TicketPriority.values.map((priority) => PopupMenuItem(
                          value: 'priority_${priority.name}',
                          child: Row(
                            children: [
                              if (_filterPriority == priority)
                                const Icon(Icons.check, size: 16),
                              if (_filterPriority == priority)
                                const SizedBox(width: 8),
                              Text(_getPriorityLabel(priority)),
                            ],
                          ),
                        )),
                        const PopupMenuItem(
                          enabled: false,
                          child: Divider(),
                        ),
                        const PopupMenuItem(
                          enabled: false,
                          child: Text(
                            'Filtrer par catégorie',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        ...TicketCategory.values.map((category) => PopupMenuItem(
                          value: 'category_${category.name}',
                          child: Row(
                            children: [
                              if (_filterCategory == category)
                                const Icon(Icons.check, size: 16),
                              if (_filterCategory == category)
                                const SizedBox(width: 8),
                              Text(_getCategoryLabel(category)),
                            ],
                          ),
                        )),
                        const PopupMenuItem(
                          enabled: false,
                          child: Divider(),
                        ),
                        const PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.clear_all, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Effacer les filtres', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        setState(() {
                          if (value == 'clear') {
                            _filterPriority = null;
                            _filterCategory = null;
                          } else if (value.startsWith('priority_')) {
                            final priorityName = value.substring(9);
                            _filterPriority = TicketPriority.values.firstWhere(
                              (p) => p.name == priorityName,
                            );
                          } else if (value.startsWith('category_')) {
                            final categoryName = value.substring(9);
                            _filterCategory = TicketCategory.values.firstWhere(
                              (c) => c.name == categoryName,
                            );
                          }
                        });
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.sort),
                      tooltip: 'Trier',
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'date_desc',
                          child: Row(
                            children: [
                              if (_sortBy == 'date_desc')
                                const Icon(Icons.check, size: 16),
                              if (_sortBy == 'date_desc')
                                const SizedBox(width: 8),
                              const Text('Plus récents'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'date_asc',
                          child: Row(
                            children: [
                              if (_sortBy == 'date_asc')
                                const Icon(Icons.check, size: 16),
                              if (_sortBy == 'date_asc')
                                const SizedBox(width: 8),
                              const Text('Plus anciens'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'priority_high',
                          child: Row(
                            children: [
                              if (_sortBy == 'priority_high')
                                const Icon(Icons.check, size: 16),
                              if (_sortBy == 'priority_high')
                                const SizedBox(width: 8),
                              const Text('Priorité haute'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'priority_low',
                          child: Row(
                            children: [
                              if (_sortBy == 'priority_low')
                                const Icon(Icons.check, size: 16),
                              if (_sortBy == 'priority_low')
                                const SizedBox(width: 8),
                              const Text('Priorité basse'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        setState(() {
                          _sortBy = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Statistiques
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard(
                        'Total',
                        _statistics['total']?.toString() ?? '0',
                        Icons.confirmation_number,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Ouverts',
                        _statistics['open']?.toString() ?? '0',
                        Icons.new_releases,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'En cours',
                        _statistics['inProgress']?.toString() ?? '0',
                        Icons.autorenew,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        'Résolus',
                        _statistics['resolved']?.toString() ?? '0',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Fermés',
                        _statistics['closed']?.toString() ?? '0',
                        Icons.cancel,
                        Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Onglets
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Tous'),
                Tab(text: 'Ouverts'),
                Tab(text: 'En cours'),
                Tab(text: 'En attente'),
                Tab(text: 'Résolus'),
              ],
            ),
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTicketList(null),
                _buildTicketList(TicketStatus.open),
                _buildTicketList(TicketStatus.inProgress),
                _buildTicketList(TicketStatus.waiting),
                _buildTicketList(TicketStatus.resolved),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(TicketStatus? status) {
    return StreamBuilder<List<SupportTicket>>(
      stream: status == null
          ? _supportService.getAllTickets()
          : _supportService.getTicketsByStatus(status),
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

        var tickets = snapshot.data ?? [];
        
        // Appliquer les filtres
        tickets = _applyFilters(tickets);

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
                  (_searchQuery.isNotEmpty || _filterPriority != null || _filterCategory != null || _showOnlyUnread)
                      ? 'Aucun ticket ne correspond aux filtres'
                      : 'Aucun ticket',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                if (_searchQuery.isNotEmpty || _filterPriority != null || _filterCategory != null || _showOnlyUnread)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Effacer les filtres'),
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
            return _buildAdminTicketCard(ticket);
          },
        );
      },
    );
  }
  
  List<SupportTicket> _applyFilters(List<SupportTicket> tickets) {
    var filtered = tickets;
    
    // Filtre de recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ticket) {
        return ticket.subject.toLowerCase().contains(_searchQuery) ||
            ticket.description.toLowerCase().contains(_searchQuery) ||
            ticket.userName.toLowerCase().contains(_searchQuery) ||
            ticket.userEmail.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    // Filtre par priorité
    if (_filterPriority != null) {
      filtered = filtered.where((ticket) => ticket.priority == _filterPriority).toList();
    }
    
    // Filtre par catégorie
    if (_filterCategory != null) {
      filtered = filtered.where((ticket) => ticket.category == _filterCategory).toList();
    }
    
    // Filtre messages non lus
    if (_showOnlyUnread) {
      filtered = filtered.where((ticket) {
        if (ticket.messages.isEmpty) return false;
        return ticket.messages.last.isAdmin == false;
      }).toList();
    }
    
    // Tri
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'date_asc':
          return a.createdAt.compareTo(b.createdAt);
        case 'priority_high':
          return _getPriorityValue(b.priority).compareTo(_getPriorityValue(a.priority));
        case 'priority_low':
          return _getPriorityValue(a.priority).compareTo(_getPriorityValue(b.priority));
        case 'date_desc':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });
    
    return filtered;
  }
  
  int _getPriorityValue(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 1;
      case TicketPriority.medium:
        return 2;
      case TicketPriority.high:
        return 3;
      case TicketPriority.urgent:
        return 4;
    }
  }

  Widget _buildAdminTicketCard(SupportTicket ticket) {
    // Vérifier s'il y a des nouveaux messages utilisateur
    final hasUnreadUserMessages = ticket.messages.isNotEmpty && 
                                   ticket.messages.last.isAdmin == false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: hasUnreadUserMessages ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasUnreadUserMessages
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAdminTicketDetails(ticket),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (hasUnreadUserMessages)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.priority_high,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                ticket.subject,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: hasUnreadUserMessages 
                                      ? FontWeight.w900 
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              ticket.userName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: hasUnreadUserMessages ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.email, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ticket.userEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusBadge(ticket.status),
                      if (hasUnreadUserMessages)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NOUVEAU',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
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
                const SizedBox(height: 8),
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
                    if (ticket.messages.last.isAdmin == false) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Réponse requise',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
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

  void _showAdminTicketDetails(SupportTicket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminTicketDetailsPage(
          ticket: ticket,
          supportService: _supportService,
          onTicketUpdated: _loadStatistics,
        ),
      ),
    );
  }
  
  String _getPriorityLabel(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 'Basse';
      case TicketPriority.medium:
        return 'Moyenne';
      case TicketPriority.high:
        return 'Haute';
      case TicketPriority.urgent:
        return 'Urgente';
    }
  }
  
  String _getCategoryLabel(TicketCategory category) {
    switch (category) {
      case TicketCategory.bug:
        return 'Bug';
      case TicketCategory.feature:
        return 'Fonctionnalité';
      case TicketCategory.question:
        return 'Question';
      case TicketCategory.feedback:
        return 'Feedback';
      case TicketCategory.other:
        return 'Autre';
    }
  }
}

// Page de détails du ticket pour admin
class AdminTicketDetailsPage extends StatefulWidget {
  final SupportTicket ticket;
  final SupportService supportService;
  final VoidCallback onTicketUpdated;

  const AdminTicketDetailsPage({
    Key? key,
    required this.ticket,
    required this.supportService,
    required this.onTicketUpdated,
  }) : super(key: key);

  @override
  State<AdminTicketDetailsPage> createState() => _AdminTicketDetailsPageState();
}

class _AdminTicketDetailsPageState extends State<AdminTicketDetailsPage> {
  final _messageController = TextEditingController();
  bool _isSending = false;
  
  // Templates de réponses rapides
  final List<Map<String, String>> _quickReplies = [
    {
      'title': 'Merci pour le rapport',
      'message': 'Merci pour votre rapport. Nous avons bien pris en compte votre demande et notre équipe l\'examine actuellement. Nous reviendrons vers vous très prochainement.',
    },
    {
      'title': 'En cours d\'investigation',
      'message': 'Nous avons commencé l\'investigation de votre demande. Nous vous tiendrons informé de l\'avancement et reviendrons vers vous dès que nous aurons plus d\'informations.',
    },
    {
      'title': 'Problème résolu',
      'message': 'Nous avons résolu le problème que vous avez signalé. La correction a été déployée. Pourriez-vous vérifier de votre côté et nous confirmer que tout fonctionne correctement ?',
    },
    {
      'title': 'Plus d\'informations nécessaires',
      'message': 'Pour mieux vous aider, nous aurions besoin de quelques informations complémentaires. Pourriez-vous nous fournir plus de détails sur votre problème ?',
    },
    {
      'title': 'Fermeture du ticket',
      'message': 'Nous considérons cette demande comme résolue. Si vous rencontrez à nouveau ce problème ou si vous avez d\'autres questions, n\'hésitez pas à ouvrir un nouveau ticket.',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  
  void _showQuickReplies() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Réponses rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(_quickReplies.map((reply) => ListTile(
              title: Text(reply['title']!),
              subtitle: Text(
                reply['message']!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                _messageController.text = reply['message']!;
                Navigator.pop(context);
              },
            ))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du ticket'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'status':
                  _changeStatus();
                  break;
                case 'priority':
                  _changePriority();
                  break;
                case 'delete':
                  _deleteTicket();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Changer le statut'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'priority',
                child: Row(
                  children: [
                    Icon(Icons.flag),
                    SizedBox(width: 8),
                    Text('Changer la priorité'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ticket.subject,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16),
                              const SizedBox(width: 4),
                              Text(widget.ticket.userName),
                              const SizedBox(width: 12),
                              const Icon(Icons.email, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.ticket.userEmail,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.ticket.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusChip(widget.ticket.status),
                    _buildPriorityChip(widget.ticket.priority),
                    _buildCategoryChip(widget.ticket.category),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Créé le ${DateFormat('dd/MM/yyyy à HH:mm').format(widget.ticket.createdAt)}',
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
              itemCount: widget.ticket.messages.length,
              itemBuilder: (context, index) {
                final message = widget.ticket.messages.reversed.toList()[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Zone de saisie (réponse admin) avec boutons d'action rapide
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
            child: Column(
              children: [
                // Boutons d'action rapide
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickActionButton(
                        'Réponses rapides',
                        Icons.flash_on,
                        Colors.blue,
                        _showQuickReplies,
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionButton(
                        'En cours',
                        Icons.autorenew,
                        Colors.purple,
                        () => _quickChangeStatus(TicketStatus.inProgress),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionButton(
                        'Résolu',
                        Icons.check_circle,
                        Colors.green,
                        () => _quickChangeStatus(TicketStatus.resolved),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionButton(
                        'En attente',
                        Icons.schedule,
                        Colors.orange,
                        () => _quickChangeStatus(TicketStatus.waiting),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Champ de saisie
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Votre réponse en tant qu\'admin...',
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
                      onPressed: _isSending ? null : _sendAdminMessage,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TicketStatus status) {
    return Chip(
      avatar: Icon(_getStatusIcon(status), size: 16),
      label: Text(_getStatusLabel(status)),
      backgroundColor: _getStatusColor(status).withOpacity(0.2),
      labelStyle: TextStyle(
        color: _getStatusColor(status),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPriorityChip(TicketPriority priority) {
    return Chip(
      avatar: const Icon(Icons.flag, size: 16),
      label: Text(_getPriorityLabel(priority)),
      backgroundColor: _getPriorityColor(priority).withOpacity(0.2),
      labelStyle: TextStyle(
        color: _getPriorityColor(priority),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCategoryChip(TicketCategory category) {
    return Chip(
      avatar: Icon(_getCategoryIcon(category), size: 16),
      label: Text(_getCategoryLabel(category)),
    );
  }

  Widget _buildMessageBubble(TicketMessage message) {
    final isAdmin = message.isAdmin;
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isAdmin
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[200],
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
                if (isAdmin) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
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

  Future<void> _sendAdminMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();
      final currentUser = FirebaseAuth.instance.currentUser;

      await widget.supportService.addMessageToTicket(
        ticketId: widget.ticket.id,
        senderId: currentUser?.uid ?? 'admin',
        senderName: user?.fullName ?? 'Administrateur',
        senderEmail: user?.email ?? 'support@app.gestoapp.cloud',
        isAdmin: true,
        message: _messageController.text.trim(),
      );

      _messageController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réponse envoyée !'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      widget.onTicketUpdated();
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
  
  // Action rapide pour changer le statut sans dialogue
  Future<void> _quickChangeStatus(TicketStatus newStatus) async {
    try {
      await widget.supportService.updateTicketStatus(widget.ticket.id, newStatus);
      widget.onTicketUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut changé en: ${_getStatusLabel(newStatus)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
  
  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus() async {
    final newStatus = await showDialog<TicketStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Changer le statut'),
        children: TicketStatus.values.map((status) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, status),
            child: Row(
              children: [
                Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                const SizedBox(width: 8),
                Text(_getStatusLabel(status)),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (newStatus != null && mounted) {
      try {
        await widget.supportService.updateTicketStatus(widget.ticket.id, newStatus);
        widget.onTicketUpdated();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Statut mis à jour'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
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

  Future<void> _changePriority() async {
    final newPriority = await showDialog<TicketPriority>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Changer la priorité'),
        children: TicketPriority.values.map((priority) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, priority),
            child: Row(
              children: [
                Icon(Icons.flag, color: _getPriorityColor(priority)),
                const SizedBox(width: 8),
                Text(_getPriorityLabel(priority)),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (newPriority != null && mounted) {
      try {
        await widget.supportService.updateTicketPriority(widget.ticket.id, newPriority);
        widget.onTicketUpdated();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Priorité mise à jour'),
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

  Future<void> _deleteTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le ticket'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce ticket ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await widget.supportService.deleteTicket(widget.ticket.id);
        widget.onTicketUpdated();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ticket supprimé'),
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

  String _getStatusLabel(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'Ouvert';
      case TicketStatus.inProgress:
        return 'En cours';
      case TicketStatus.waiting:
        return 'En attente';
      case TicketStatus.resolved:
        return 'Résolu';
      case TicketStatus.closed:
        return 'Fermé';
    }
  }

  IconData _getStatusIcon(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Icons.new_releases;
      case TicketStatus.inProgress:
        return Icons.autorenew;
      case TicketStatus.waiting:
        return Icons.schedule;
      case TicketStatus.resolved:
        return Icons.check_circle;
      case TicketStatus.closed:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Colors.blue;
      case TicketStatus.inProgress:
        return Colors.orange;
      case TicketStatus.waiting:
        return Colors.purple;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.urgent:
        return 'Urgent';
      case TicketPriority.high:
        return 'Haute';
      case TicketPriority.medium:
        return 'Moyenne';
      case TicketPriority.low:
        return 'Basse';
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.urgent:
        return Colors.red;
      case TicketPriority.high:
        return Colors.orange;
      case TicketPriority.medium:
        return Colors.yellow[700]!;
      case TicketPriority.low:
        return Colors.green;
    }
  }

  String _getCategoryLabel(TicketCategory category) {
    switch (category) {
      case TicketCategory.bug:
        return 'Bug';
      case TicketCategory.feature:
        return 'Fonctionnalité';
      case TicketCategory.question:
        return 'Question';
      case TicketCategory.feedback:
        return 'Feedback';
      case TicketCategory.other:
        return 'Autre';
    }
  }

  IconData _getCategoryIcon(TicketCategory category) {
    switch (category) {
      case TicketCategory.bug:
        return Icons.bug_report;
      case TicketCategory.feature:
        return Icons.lightbulb;
      case TicketCategory.question:
        return Icons.help;
      case TicketCategory.feedback:
        return Icons.feedback;
      case TicketCategory.other:
        return Icons.more_horiz;
    }
  }
}
