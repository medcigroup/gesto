import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/roadmap_item.dart';
import '../../services/support_service.dart';

class RoadmapAdminPage extends StatefulWidget {
  const RoadmapAdminPage({Key? key}) : super(key: key);

  @override
  State<RoadmapAdminPage> createState() => _RoadmapAdminPageState();
}

enum ViewMode { list, timeline, priority }
enum GroupBy { none, period, status, priority, category }
enum SortBy { priority, date, votes, alphabetical }

class _RoadmapAdminPageState extends State<RoadmapAdminPage> {
  final SupportService _supportService = SupportService();
  RoadmapStatus? _filterStatus;
  ViewMode _viewMode = ViewMode.timeline;
  GroupBy _groupBy = GroupBy.period;
  SortBy _sortBy = SortBy.priority;
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header
          _buildHeader(theme, isDark),

          // Toolbar avec options de vue et filtres
          _buildToolbar(theme, isDark),

          // Filters
          _buildFilters(theme, isDark),

          // List
          Expanded(
            child: _buildRoadmapContent(isDark),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle fonctionnalité'),
        backgroundColor: theme.primaryColor,
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E2E), const Color(0xFF2D2D44)]
              : [theme.primaryColor.withOpacity(0.1), Colors.white],
        ),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion de la Roadmap',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez et gérez les fonctionnalités à venir',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Vue
          Text(
            'Vue:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<ViewMode>(
            segments: const [
              ButtonSegment(
                value: ViewMode.list,
                icon: Icon(Icons.view_list, size: 18),
                label: Text('Liste'),
              ),
              ButtonSegment(
                value: ViewMode.timeline,
                icon: Icon(Icons.timeline, size: 18),
                label: Text('Timeline'),
              ),
              ButtonSegment(
                value: ViewMode.priority,
                icon: Icon(Icons.priority_high, size: 18),
                label: Text('Priorité'),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (Set<ViewMode> newSelection) {
              setState(() {
                _viewMode = newSelection.first;
                // Ajuster le groupement selon la vue
                if (_viewMode == ViewMode.timeline) {
                  _groupBy = GroupBy.period;
                } else if (_viewMode == ViewMode.priority) {
                  _groupBy = GroupBy.priority;
                }
              });
            },
          ),
          const SizedBox(width: 24),
          // Groupement
          Text(
            'Grouper:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<GroupBy>(
            value: _groupBy,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: GroupBy.none, child: Text('Aucun')),
              DropdownMenuItem(value: GroupBy.period, child: Text('Période')),
              DropdownMenuItem(value: GroupBy.status, child: Text('Statut')),
              DropdownMenuItem(value: GroupBy.priority, child: Text('Priorité')),
              DropdownMenuItem(value: GroupBy.category, child: Text('Catégorie')),
            ],
            onChanged: (value) {
              setState(() {
                _groupBy = value!;
              });
            },
          ),
          const SizedBox(width: 24),
          // Tri
          Text(
            'Trier:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<SortBy>(
            value: _sortBy,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: SortBy.priority, child: Text('Priorité')),
              DropdownMenuItem(value: SortBy.date, child: Text('Date')),
              DropdownMenuItem(value: SortBy.votes, child: Text('Votes')),
              DropdownMenuItem(value: SortBy.alphabetical, child: Text('A-Z')),
            ],
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
            },
          ),
          IconButton(
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
            tooltip: _sortAscending ? 'Ordre croissant' : 'Ordre décroissant',
          ),
          const Spacer(),
          // Statistiques rapides
          _buildQuickStats(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme, bool isDark) {
    return StreamBuilder<List<RoadmapItem>>(
      stream: _supportService.getRoadmapItems(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final items = snapshot.data!;
        final planned = items.where((i) => i.status == RoadmapStatus.planned).length;
        final inProgress = items.where((i) => i.status == RoadmapStatus.inProgress).length;
        final completed = items.where((i) => i.status == RoadmapStatus.completed).length;
        
        return Row(
          children: [
            _buildStatChip('Planifié', planned, const Color(0xFF2196F3), isDark),
            const SizedBox(width: 8),
            _buildStatChip('En cours', inProgress, const Color(0xFFFF9800), isDark),
            const SizedBox(width: 8),
            _buildStatChip('Terminé', completed, const Color(0xFF4CAF50), isDark),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(String label, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tous', null, theme, isDark),
            const SizedBox(width: 8),
            ...RoadmapStatus.values.map((status) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  _getStatusLabel(status),
                  status,
                  theme,
                  isDark,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, RoadmapStatus? status, ThemeData theme, bool isDark) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? status : null;
        });
      },
      selectedColor: theme.primaryColor.withOpacity(0.2),
      checkmarkColor: theme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? theme.primaryColor : (isDark ? Colors.grey[400] : Colors.grey[700]),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildRoadmapContent(bool isDark) {
    return StreamBuilder<List<RoadmapItem>>(
      stream: _filterStatus == null
          ? _supportService.getRoadmapItems()
          : _supportService.getRoadmapItemsByStatus(_filterStatus!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        var items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune fonctionnalité',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Tri des éléments
        items = _sortItems(items);

        // Affichage selon le mode de groupement
        if (_groupBy == GroupBy.none) {
          return _buildSimpleList(items, isDark);
        } else {
          return _buildGroupedList(items, isDark);
        }
      },
    );
  }

  List<RoadmapItem> _sortItems(List<RoadmapItem> items) {
    final sortedItems = List<RoadmapItem>.from(items);
    
    sortedItems.sort((a, b) {
      int comparison;
      
      switch (_sortBy) {
        case SortBy.priority:
          final priorityOrder = {
            RoadmapPriority.high: 3,
            RoadmapPriority.medium: 2,
            RoadmapPriority.low: 1,
          };
          comparison = (priorityOrder[b.priority] ?? 0).compareTo(priorityOrder[a.priority] ?? 0);
          break;
        
        case SortBy.date:
          if (a.estimatedDate == null && b.estimatedDate == null) {
            comparison = 0;
          } else if (a.estimatedDate == null) {
            comparison = 1;
          } else if (b.estimatedDate == null) {
            comparison = -1;
          } else {
            comparison = a.estimatedDate!.compareTo(b.estimatedDate!);
          }
          break;
        
        case SortBy.votes:
          comparison = b.votesCount.compareTo(a.votesCount);
          break;
        
        case SortBy.alphabetical:
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return sortedItems;
  }

  Widget _buildSimpleList(List<RoadmapItem> items, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildRoadmapCard(items[index], isDark);
      },
    );
  }

  Widget _buildGroupedList(List<RoadmapItem> items, bool isDark) {
    final groups = _groupItems(items);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final groupKey = groups.keys.elementAt(index);
        final groupItems = groups[groupKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupHeader(groupKey, groupItems.length, isDark),
            const SizedBox(height: 12),
            ...groupItems.map((item) => _buildRoadmapCard(item, isDark)),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Map<String, List<RoadmapItem>> _groupItems(List<RoadmapItem> items) {
    final groups = <String, List<RoadmapItem>>{};
    
    for (final item in items) {
      String groupKey;
      
      switch (_groupBy) {
        case GroupBy.period:
          groupKey = _getPeriodLabel(item.estimatedDate);
          break;
        
        case GroupBy.status:
          groupKey = _getStatusLabel(item.status);
          break;
        
        case GroupBy.priority:
          groupKey = _getPriorityLabel(item.priority);
          break;
        
        case GroupBy.category:
          groupKey = item.category.isEmpty ? 'Sans catégorie' : item.category;
          break;
        
        case GroupBy.none:
          groupKey = 'Tous';
          break;
      }
      
      groups.putIfAbsent(groupKey, () => []);
      groups[groupKey]!.add(item);
    }
    
    // Tri des groupes
    final sortedGroups = Map.fromEntries(
      groups.entries.toList()
        ..sort((a, b) => _compareGroupKeys(a.key, b.key)),
    );
    
    return sortedGroups;
  }

  int _compareGroupKeys(String a, String b) {
    if (_groupBy == GroupBy.period) {
      // Ordre chronologique pour les périodes
      final periodOrder = {
        '🔥 En retard': 0,
        '📅 Ce mois-ci': 1,
        '📆 Prochainement (3 mois)': 2,
        '🔮 Plus tard (6+ mois)': 3,
        '❓ Date non définie': 4,
      };
      return (periodOrder[a] ?? 99).compareTo(periodOrder[b] ?? 99);
    } else if (_groupBy == GroupBy.priority) {
      // Ordre de priorité
      final priorityOrder = {
        '🔴 Priorité Haute': 0,
        '🟠 Priorité Moyenne': 1,
        '🟢 Priorité Basse': 2,
      };
      return (priorityOrder[a] ?? 99).compareTo(priorityOrder[b] ?? 99);
    }
    return a.compareTo(b);
  }

  String _getPeriodLabel(DateTime? date) {
    if (date == null) return '❓ Date non définie';
    
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) return '🔥 En retard';
    if (difference <= 30) return '📅 Ce mois-ci';
    if (difference <= 90) return '📆 Prochainement (3 mois)';
    return '🔮 Plus tard (6+ mois)';
  }

  String _getPriorityLabel(RoadmapPriority priority) {
    switch (priority) {
      case RoadmapPriority.high:
        return '🔴 Priorité Haute';
      case RoadmapPriority.medium:
        return '🟠 Priorité Moyenne';
      case RoadmapPriority.low:
        return '🟢 Priorité Basse';
    }
  }

  Widget _buildGroupHeader(String title, int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D2D44), const Color(0xFF1E1E2E)]
              : [Colors.grey[100]!, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapList(bool isDark) {
    return StreamBuilder<List<RoadmapItem>>(
      stream: _filterStatus == null
          ? _supportService.getRoadmapItems()
          : _supportService.getRoadmapItemsByStatus(_filterStatus!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune fonctionnalité',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildRoadmapCard(items[index], isDark);
          },
        );
      },
    );
  }

  Widget _buildRoadmapCard(RoadmapItem item, bool isDark) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(item.status);
    final isOverdue = item.estimatedDate != null && 
                      item.estimatedDate!.isBefore(DateTime.now()) &&
                      item.status != RoadmapStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOverdue 
              ? Colors.red.withOpacity(0.5)
              : statusColor.withOpacity(0.3), 
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isOverdue
              ? LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.05),
                    Colors.transparent,
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getStatusIcon(item.status), size: 14, color: statusColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getStatusLabel(item.status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildPriorityBadge(item.priority),
                            if (isOverdue) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                                    SizedBox(width: 4),
                                    Text(
                                      'En retard',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditDialog(context, item);
                          break;
                        case 'delete':
                          _confirmDelete(item);
                          break;
                        case 'duplicate':
                          _duplicateItem(item);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.content_copy, size: 20),
                            SizedBox(width: 12),
                            Text('Dupliquer'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  height: 1.5,
                ),
              ),
              if (item.category.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined, size: 14, color: theme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.thumb_up_outlined, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    '${item.votesCount} votes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 24),
                  if (item.estimatedDate != null) ...[
                    Icon(
                      Icons.calendar_month,
                      size: 16,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd/MM/yyyy').format(item.estimatedDate!),
                      style: TextStyle(
                        fontSize: 14,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Boutons d'action rapide
                  if (item.status == RoadmapStatus.planned)
                    OutlinedButton.icon(
                      onPressed: () => _quickStatusUpdate(item, RoadmapStatus.inProgress),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Démarrer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF9800),
                        side: const BorderSide(color: Color(0xFFFF9800)),
                      ),
                    ),
                  if (item.status == RoadmapStatus.inProgress)
                    OutlinedButton.icon(
                      onPressed: () => _quickStatusUpdate(item, RoadmapStatus.completed),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Terminer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4CAF50),
                        side: const BorderSide(color: Color(0xFF4CAF50)),
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

  void _quickStatusUpdate(RoadmapItem item, RoadmapStatus newStatus) async {
    await _supportService.updateRoadmapItem(
      item.id,
      {
        'status': newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Statut mis à jour: ${_getStatusLabel(newStatus)}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _duplicateItem(RoadmapItem item) async {
    await _supportService.createRoadmapItem(
      title: '${item.title} (Copie)',
      description: item.description,
      category: item.category,
      tags: item.tags,
      status: RoadmapStatus.planned,
      priority: item.priority,
      estimatedDate: item.estimatedDate,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité dupliquée avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildPriorityBadge(RoadmapPriority priority) {
    Color color;
    String label;

    switch (priority) {
      case RoadmapPriority.high:
        color = Colors.red;
        label = 'Haute';
        break;
      case RoadmapPriority.medium:
        color = Colors.orange;
        label = 'Moyenne';
        break;
      case RoadmapPriority.low:
        color = Colors.green;
        label = 'Basse';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _getStatusLabel(RoadmapStatus status) {
    switch (status) {
      case RoadmapStatus.planned:
        return 'Planifié';
      case RoadmapStatus.inProgress:
        return 'En cours';
      case RoadmapStatus.completed:
        return 'Terminé';
      case RoadmapStatus.cancelled:
        return 'Annulé';
    }
  }

  IconData _getStatusIcon(RoadmapStatus status) {
    switch (status) {
      case RoadmapStatus.planned:
        return Icons.schedule_rounded;
      case RoadmapStatus.inProgress:
        return Icons.autorenew_rounded;
      case RoadmapStatus.completed:
        return Icons.check_circle_rounded;
      case RoadmapStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  Color _getStatusColor(RoadmapStatus status) {
    switch (status) {
      case RoadmapStatus.planned:
        return const Color(0xFF2196F3);
      case RoadmapStatus.inProgress:
        return const Color(0xFFFF9800);
      case RoadmapStatus.completed:
        return const Color(0xFF4CAF50);
      case RoadmapStatus.cancelled:
        return const Color(0xFF9E9E9E);
    }
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final tagsController = TextEditingController();
    RoadmapStatus selectedStatus = RoadmapStatus.planned;
    RoadmapPriority selectedPriority = RoadmapPriority.medium;
    DateTime? estimatedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return AlertDialog(
            title: const Text('Nouvelle fonctionnalité'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie',
                        border: OutlineInputBorder(),
                        hintText: 'ex: Fonctionnalités, Intégrations',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (séparés par des virgules)',
                        border: OutlineInputBorder(),
                        hintText: 'ex: mobile, paiement, api',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RoadmapStatus>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(),
                      ),
                      items: RoadmapStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(_getStatusLabel(status)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedStatus = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RoadmapPriority>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priorité',
                        border: OutlineInputBorder(),
                      ),
                      items: RoadmapPriority.values.map((priority) {
                        String label;
                        switch (priority) {
                          case RoadmapPriority.high:
                            label = 'Haute';
                            break;
                          case RoadmapPriority.medium:
                            label = 'Moyenne';
                            break;
                          case RoadmapPriority.low:
                            label = 'Basse';
                            break;
                        }
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPriority = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: estimatedDate ?? DateTime.now().add(const Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (date != null) {
                          setDialogState(() {
                            estimatedDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        estimatedDate == null
                            ? 'Sélectionner une date estimée'
                            : 'Date: ${DateFormat('dd/MM/yyyy').format(estimatedDate!)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez remplir tous les champs obligatoires'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final tags = tagsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  await _supportService.createRoadmapItem(
                    title: titleController.text,
                    description: descriptionController.text,
                    category: categoryController.text,
                    tags: tags,
                    status: selectedStatus,
                    priority: selectedPriority,
                    estimatedDate: estimatedDate,
                  );

                  if (!context.mounted) return;
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité créée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Créer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, RoadmapItem item) {
    final titleController = TextEditingController(text: item.title);
    final descriptionController = TextEditingController(text: item.description);
    final categoryController = TextEditingController(text: item.category);
    final tagsController = TextEditingController(text: item.tags.join(', '));
    RoadmapStatus selectedStatus = item.status;
    RoadmapPriority selectedPriority = item.priority;
    DateTime? estimatedDate = item.estimatedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Modifier la fonctionnalité'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (séparés par des virgules)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RoadmapStatus>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(),
                      ),
                      items: RoadmapStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(_getStatusLabel(status)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedStatus = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RoadmapPriority>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priorité',
                        border: OutlineInputBorder(),
                      ),
                      items: RoadmapPriority.values.map((priority) {
                        String label;
                        switch (priority) {
                          case RoadmapPriority.high:
                            label = 'Haute';
                            break;
                          case RoadmapPriority.medium:
                            label = 'Moyenne';
                            break;
                          case RoadmapPriority.low:
                            label = 'Basse';
                            break;
                        }
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPriority = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: estimatedDate ?? DateTime.now().add(const Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (date != null) {
                          setDialogState(() {
                            estimatedDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        estimatedDate == null
                            ? 'Sélectionner une date estimée'
                            : 'Date: ${DateFormat('dd/MM/yyyy').format(estimatedDate!)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez remplir tous les champs obligatoires'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final tags = tagsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  await _supportService.updateRoadmapItem(
                    item.id,
                    {
                      'title': titleController.text,
                      'description': descriptionController.text,
                      'category': categoryController.text,
                      'tags': tags,
                      'status': selectedStatus.toString().split('.').last,
                      'priority': selectedPriority.toString().split('.').last,
                      'estimatedDate': estimatedDate != null ? Timestamp.fromDate(estimatedDate!) : null,
                      'updatedAt': FieldValue.serverTimestamp(),
                    },
                  );

                  if (!context.mounted) return;
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité mise à jour avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Sauvegarder'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(RoadmapItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${item.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _supportService.deleteRoadmapItem(item.id);
              
              if (!context.mounted) return;
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité supprimée'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
