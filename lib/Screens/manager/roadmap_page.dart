import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../models/roadmap_item.dart';
import '../../services/support_service.dart';

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({Key? key}) : super(key: key);

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> with SingleTickerProviderStateMixin {
  final SupportService _supportService = SupportService();
  late TabController _tabController;
  List<RoadmapItem>? _allItems;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final items = await _supportService.getRoadmapItems().first;
      if (mounted) {
        setState(() {
          _allItems = items;
        });
      }
    } catch (e) {
      debugPrint('Error loading roadmap: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Roadmap', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.construction), text: 'En cours'),
            Tab(icon: Icon(Icons.schedule), text: 'Planifié'),
            Tab(icon: Icon(Icons.check_circle), text: 'Terminé'),
          ],
        ),
      ),
      body: _allItems == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSimpleList(RoadmapStatus.inProgress, isDark),
                _buildSimpleList(RoadmapStatus.planned, isDark),
                _buildSimpleList(RoadmapStatus.completed, isDark),
              ],
            ),
    );
  }

  Widget _buildSimpleList(RoadmapStatus status, bool isDark) {
    final items = _allItems!.where((item) => item.status == status).toList();
    
    // Trier
    if (status == RoadmapStatus.completed) {
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      items.sort((a, b) {
        if (a.estimatedDate == null && b.estimatedDate == null) return 0;
        if (a.estimatedDate == null) return 1;
        if (b.estimatedDate == null) return -1;
        return a.estimatedDate!.compareTo(b.estimatedDate!);
      });
    }

    // Limiter à 5 items max
    final displayItems = items.take(5).toList();

    if (displayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == RoadmapStatus.inProgress
                  ? Icons.construction
                  : status == RoadmapStatus.planned
                      ? Icons.schedule
                      : Icons.check_circle,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun élément',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: displayItems.length + (items.length > 5 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayItems.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '+ ${items.length - 5} autres',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }
          final isFirst = index == 0;
          final isLast = index == displayItems.length - 1 || (items.length > 5 && index == displayItems.length - 1);
          return _buildTimelineCard(displayItems[index], status, isDark, isFirst, isLast);
        },
      ),
    );
  }

  Widget _buildTimelineCard(RoadmapItem item, RoadmapStatus status, bool isDark, bool isFirst, bool isLast) {
    final theme = Theme.of(context);
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case RoadmapStatus.inProgress:
        statusColor = Colors.orange;
        statusIcon = Icons.autorenew_rounded;
        break;
      case RoadmapStatus.planned:
        statusColor = Colors.blue;
        statusIcon = Icons.calendar_today;
        break;
      case RoadmapStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case RoadmapStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      alignment: TimelineAlign.manual,
      lineXY: 0.25,
      indicatorStyle: IndicatorStyle(
        width: 40,
        height: 40,
        indicator: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(statusIcon, color: Colors.white, size: 20),
        ),
      ),
      beforeLineStyle: LineStyle(
        color: statusColor.withOpacity(0.3),
        thickness: 3,
      ),
      afterLineStyle: LineStyle(
        color: statusColor.withOpacity(0.3),
        thickness: 3,
      ),
      endChild: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 16),
        child: Card(
          elevation: 2,
          color: isDark ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
          ),
          child: InkWell(
            onTap: () => _showItemDetails(item),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [statusColor, statusColor.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPriorityBadge(item.priority),
                      const Spacer(),
                      if (item.estimatedDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[700] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM yyyy').format(item.estimatedDate!),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey[300], height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (item.category.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder, size: 14, color: theme.primaryColor),
                              const SizedBox(width: 4),
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
                        const SizedBox(width: 12),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.thumb_up, size: 16, color: theme.primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              '${item.votesCount}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'votes',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleCard(RoadmapItem item, RoadmapStatus status, bool isDark) {
    final theme = Theme.of(context);
    Color statusColor;
    
    switch (status) {
      case RoadmapStatus.inProgress:
        statusColor = Colors.orange;
        break;
      case RoadmapStatus.planned:
        statusColor = Colors.blue;
        break;
      case RoadmapStatus.completed:
        statusColor = Colors.green;
        break;
      case RoadmapStatus.cancelled:
        statusColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () => _showItemDetails(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityBadge(item.priority),
                  const Spacer(),
                  if (item.estimatedDate != null)
                    Text(
                      DateFormat('MMM yyyy').format(item.estimatedDate!),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (item.category.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  Icon(Icons.thumb_up, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '${item.votesCount}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
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

  String _getStatusText(RoadmapStatus status) {
    switch (status) {
      case RoadmapStatus.inProgress:
        return 'EN COURS';
      case RoadmapStatus.planned:
        return 'PLANIFIÉ';
      case RoadmapStatus.completed:
        return 'TERMINÉ';
      case RoadmapStatus.cancelled:
        return 'ANNULÉ';
    }
  }

  Widget _buildPriorityBadge(RoadmapPriority priority) {
    Color color;
    String label;
    
    switch (priority) {
      case RoadmapPriority.low:
        color = Colors.grey;
        label = 'Faible';
        break;
      case RoadmapPriority.medium:
        color = Colors.blue;
        label = 'Moyen';
        break;
      case RoadmapPriority.high:
        color = Colors.red;
        label = 'Élevé';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
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

  void _showItemDetails(RoadmapItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildPriorityBadge(item.priority),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(item.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getStatusText(item.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(item.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (item.category.isNotEmpty) ...[
                      Text(
                        'Catégorie',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (item.estimatedDate != null) ...[
                      Text(
                        'Date estimée',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMMM yyyy', 'fr_FR').format(item.estimatedDate!),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Icon(Icons.thumb_up, size: 20, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          '${item.votesCount} votes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Fermer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _voteForItem(item);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.thumb_up),
                      label: const Text('Voter'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RoadmapStatus status) {
    switch (status) {
      case RoadmapStatus.inProgress:
        return Colors.orange;
      case RoadmapStatus.planned:
        return Colors.blue;
      case RoadmapStatus.completed:
        return Colors.green;
      case RoadmapStatus.cancelled:
        return Colors.red;
    }
  }

  Future<void> _voteForItem(RoadmapItem item) async {
    try {
      // TODO: Récupérer l'ID utilisateur actuel depuis FirebaseAuth
      final userId = 'anonymous'; // Placeholder
      await _supportService.voteForRoadmapItem(item.id, userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci pour votre vote !')),
      );
      _loadData(); // Recharger les données
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}
