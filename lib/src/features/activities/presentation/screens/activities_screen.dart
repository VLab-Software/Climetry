import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../../core/services/event_weather_prediction_service.dart';
import '../../../../core/services/event_sharing_service.dart';
import '../../data/services/event_notification_service.dart';
import '../../data/repositories/activity_repository.dart';
import 'new_activity_screen.dart';
import '../../../home/presentation/screens/event_details_screen.dart';
import '../../../friends/domain/entities/friend.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with AutomaticKeepAliveClientMixin {
  final ActivityRepository _activityRepository = ActivityRepository();
  final EventWeatherPredictionService _predictionService =
      EventWeatherPredictionService();
  final EventSharingService _sharingService = EventSharingService();

  List<Activity> _allActivities = [];
  List<Activity> _filteredActivities = [];
  Map<String, EventWeatherAnalysis> _analyses = {};
  String _selectedFilter = 'time'; // time, distance, priority
  String _recurrenceFilter = 'all'; // all, single, recurring
  bool _isAnalyzing = false;
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  Future<void> _analyzeActivities(List<Activity> activities) async {
    if (!mounted) return;
    setState(() => _isAnalyzing = true);

    for (final activity in activities.take(10)) {
      try {
        final analysis = await _predictionService.analyzeEvent(activity);
        if (!mounted) return;
        setState(() {
          _analyses[activity.id] = analysis;
        });
      } catch (e) {
        debugPrint('Error ao analisar ${activity.title}: $e');
      }
    }

    if (!mounted) return;
    setState(() => _isAnalyzing = false);
  }

  void _applyFilters() {
    _filterActivities();
  }

  void _filterActivities() {
    final now = DateTime.now();
    List<Activity> filtered = List.from(_allActivities);

    filtered = filtered.where((a) => a.date.isAfter(now)).toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) {
        final matchesTitle = a.title.toLowerCase().contains(_searchQuery);
        final matchesTags = a.tags.any(
          (tag) => tag.toLowerCase().contains(_searchQuery),
        );
        return matchesTitle || matchesTags;
      }).toList();
    }

    if (_recurrenceFilter == 'single') {
      filtered = filtered
          .where((a) => a.recurrence == RecurrenceType.none)
          .toList();
    } else if (_recurrenceFilter == 'recurring') {
      filtered = filtered
          .where((a) => a.recurrence != RecurrenceType.none)
          .toList();
    }

    switch (_selectedFilter) {
      case 'time':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      
      case 'distance':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      
      case 'priority':
        filtered.sort((a, b) {
          final priorityOrder = {
            ActivityPriority.urgent: 0,
            ActivityPriority.high: 1,
            ActivityPriority.medium: 2,
            ActivityPriority.low: 3,
          };
          final priorityCompare = (priorityOrder[a.priority] ?? 999)
              .compareTo(priorityOrder[b.priority] ?? 999);
          
          if (priorityCompare == 0) {
            return a.date.compareTo(b.date);
          }
          return priorityCompare;
        });
        break;
    }

    setState(() => _filteredActivities = filtered);
  }

  Future<void> _deleteActivity(Activity activity) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1F2937) : Colors.white,
        title: Text(
          'Delete Ewind',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Do you really want to delete "${activity.title}"?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _activityRepository.delete(activity.id);
        if (!mounted) return;
        setState(() {
          _allActivities.removeWhere((a) => a.id == activity.id);
          _analyses.remove(activity.id);
        });
        _applyFilters();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Ewind excluído'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0F1419) : Color(0xFFF8FAFC),
      body: StreamBuilder<List<Activity>>(
        stream: _activityRepository.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasDate) {
            final newActivities = snapshot.data!;
            
            if (_allActivities.length != newActivities.length ||
                !_allActivities.every((a) => newActivities.any((n) => n.id == a.id))) {
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _allActivities = newActivities;
                _filterActivities();
                
                if (!_isAnalyzing) {
                  final now = DateTime.now();
                  final futureEvents = _allActivities
                      .where((a) => a.date.isAfter(now))
                      .toList();
                  if (futureEvents.isNotEmpty) {
                    _analyzeActivities(futureEvents);
                  }
                }
              });
            }
          }

          final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
          final bool hasDate = snapshot.hasDate && _filteredActivities.isNotEmpty;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(isDark)),

              SliverToBoxAdapter(child: _buildFilters(isDark)),

              if (isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF3B82F6)),
                        SizedBox(height: 16),
                        Text(
                          'Loading ewinds...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!hasDate)
                SliverFillRemaining(child: _buildEmptyState(isDark))
              else
                SliverPadding(
                  padding: EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final activity = _filteredActivities[index];
                      final analysis = _analyses[activity.id];
                      return _buildActivityCard(activity, analysis, isDark);
                    }, childCount: _filteredActivities.length),
                  ),
                ),

              SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F2937) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ewinds',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      '${_allActivities.length} ewinds',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _selectedFilter == 'past'
                        ? null
                        : () async {
                            final result = await Navigator.push<Activity>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NewActivityScreen(),
                              ),
                            );
                            if (result != null) {
                              await _activityRepository.save(result);
                              
                              if (result.participants.isNotEmpty) {
                                final notificationService = EventNotificationService();
                                await notificationService.notifyEventInvitation(
                                  activity: result,
                                  newParticipants: result.participants,
                                );
                              }
                              
                              if (mounted) {
                                _showEventCreatedDialog(result);
                              }
                            }
                          },
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
              if (_isAnalyzing) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Analisando...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
                _filterActivities();
              });
            },
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search por nome ou tags...',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Color(0xFF3B82F6)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _filterActivities();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? Color(0xFF374151) : Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showFilterSheet(isDark),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (isDark ? Color(0xFF374151) : Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF3B82F6).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _getFilterLabel(),
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel() {
    final time = _selectedFilter == 'all' ? 'All' : (_selectedFilter == 'upcoming' ? 'Upcoming' : 'Past');
    final recurrence = _recurrenceFilter == 'all' ? 'All' : (_recurrenceFilter == 'single' ? 'Single' : 'Recurring');
    return '$time • $recurrence';
  }

  void _showFilterSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort events',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  Text(
                    'Sort by',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  _buildFilterOption(
                    icon: Icons.access_time,
                    title: 'Proximidade de tempo',
                    subtitle: 'Events closest first',
                    value: 'time',
                    filterType: 'sort',
                    isDark: isDark,
                  ),
                  
                  _buildFilterOption(
                    icon: Icons.location_on,
                    title: 'Proximidade de distância',
                    subtitle: 'Events closest to you',
                    value: 'distance',
                    filterType: 'sort',
                    isDark: isDark,
                  ),
                  
                  _buildFilterOption(
                    icon: Icons.flag,
                    title: 'Prioridade',
                    subtitle: 'Mais urgentes primeiro',
                    value: 'priority',
                    filterType: 'sort',
                    isDark: isDark,
                  ),
                  
                  SizedBox(height: 20),
                  Divider(color: Colors.grey[300]),
                  SizedBox(height: 12),
                  
                  Text(
                    'Tipo de recorrência',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  _buildFilterOption(
                    icon: Icons.all_inclusive,
                    title: 'All',
                    subtitle: 'Únicos e recorrentes',
                    value: 'all',
                    filterType: 'recurrence',
                    isDark: isDark,
                  ),
                  
                  _buildFilterOption(
                    icon: Icons.event,
                    title: 'Apenas únicos',
                    subtitle: 'Ewinds sem recorrência',
                    value: 'single',
                    filterType: 'recurrence',
                    isDark: isDark,
                  ),
                  
                  _buildFilterOption(
                    icon: Icons.repeat,
                    title: 'Apenas recorrentes',
                    subtitle: 'Ewinds que se repetem',
                    value: 'recurring',
                    filterType: 'recurrence',
                    isDark: isDark,
                  ),
                  
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption({
    required IconDate icon,
    required String title,
    required String subtitle,
    required String value,
    required String filterType,
    required bool isDark,
  }) {
    final isSelected = filterType == 'sort' 
        ? _selectedFilter == value 
        : _recurrenceFilter == value;
    
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF3B82F6).withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? Color(0xFF3B82F6) : Colors.grey,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isDark ? Colors.white : Color(0xFF1F2937),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Color(0xFF3B82F6))
          : null,
      onTap: () {
        setState(() {
          if (filterType == 'sort') {
            _selectedFilter = value;
          } else {
            _recurrenceFilter = value;
          }
          _filterActivities();
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildFilterChip('All', 'all', isDark),
              SizedBox(width: 8),
              _buildFilterChip('Upcoming', 'upcoming', isDark),
              SizedBox(width: 8),
              _buildFilterChip('Past', 'past', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedFilter == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        _applyFilters();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF3B82F6)
              : (isDark ? Color(0xFF1F2937) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Color(0xFF3B82F6)
                : (isDark ? Color(0xFF374151) : Color(0xFFE5E7EB)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Color(0xFF1F2937)),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    Activity activity,
    EventWeatherAnalysis? analysis,
    bool isDark,
  ) {
    final dateFormat = DateFormat('dd MMM', 'pt_BR');
    final timeFormat = DateFormat('HH:mm');
    final now = DateTime.now();
    final isPast = activity.date.isBefore(now);
    final daysUntil = activity.date.difference(now).inDays;
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = activity.isOwner(currentUserId ?? '');
    final participant = activity.participants
        .where((p) => p.userId == currentUserId)
        .firstOrNull;
    
    String? roleLabel;
    Color? roleColor;
    String? roleEmoji;
    
    if (isOwner) {
      roleLabel = 'Dono';
      roleColor = const Color(0xFFFFD700); // Dourado
      roleEmoji = '🏆';
    } else if (participant != null) {
      switch (participant.role) {
        case EventRole.admin:
          roleLabel = 'Admin';
          roleColor = const Color(0xFFFF6B6B);
          roleEmoji = '👑';
          break;
        case EventRole.moderator:
          roleLabel = 'Moderador';
          roleColor = const Color(0xFF4ECDC4);
          roleEmoji = '🎖️';
          break;
        case EventRole.participant:
          roleLabel = 'Convidado';
          roleColor = const Color(0xFF95E1D3);
          roleEmoji = '👤';
          break;
        default:
          break;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (analysis != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailsScreen(analysis: analysis),
                ),
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isPast
                            ? Colors.grey.withOpacity(0.1)
                            : (analysis?.riskColor.withOpacity(0.1) ??
                                  Color(0xFF3B82F6).withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          activity.type.icon,
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${dateFormat.format(activity.date)} • ${timeFormat.format(activity.date)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          if (roleLabel != null && roleColor != null) ...[
                            SizedBox(height: 6),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: roleColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    roleEmoji!,
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    roleLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: roleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (!isPast && daysUntil >= 0) ...[
                            SizedBox(height: 4),
                            Text(
                              daysUntil == 0
                                  ? 'Today'
                                  : daysUntil == 1
                                  ? 'Tomorrow'
                                  : 'Em $daysUntil dias',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        if (!isPast && analysis != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: analysis.riskColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: analysis.riskColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              analysis.riskIcon,
                              size: 16,
                              color: analysis.riskColor,
                            ),
                          ),
                        SizedBox(height: 8),
                        PopupMenuButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey,
                            size: 20,
                          ),
                          color: isDark ? Color(0xFF374151) : Colors.white,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                              onTap: () => Future.delayed(
                                Duration.zero,
                                () => _deleteActivity(activity),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                if (!isPast &&
                    analysis != null &&
                    analysis.alerts.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFF59E0B).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${analysis.alerts.length} alerta${analysis.alerts.length > 1 ? 's' : ''} climático${analysis.alerts.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (!isPast &&
                    analysis != null &&
                    analysis.suggestions.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.psychology, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            analysis.suggestions.first.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (isPast) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(
                          'Ewind concluído',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEventCreatedDialog(Activity activity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ewind Criado!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ "${activity.title}" foi criado com success!',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'O que você gostaria de fazer?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildActionButton(
              icon: Icons.calendar_today,
              label: 'Add to Calendar',
              color: const Color(0xFF3B82F6),
              isDark: isDark,
              onTap: () async {
                Navigator.pop(context);
                final success = await _sharingService.addToCalendar(activity);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? '✅ Ewind adicionado ao calendário!'
                            : '❌ Error adding to calendar',
                      ),
                      backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            
            _buildActionButton(
              icon: Icons.chat_bubble,
              label: 'Compartilhar no WhatsApp',
              color: const Color(0xFF25D366),
              isDark: isDark,
              onTap: () async {
                Navigator.pop(context);
                await _sharingService.shareViaWhatsApp(activity: activity);
              },
            ),
            const SizedBox(height: 12),
            
            _buildActionButton(
              icon: Icons.share,
              label: 'Compartilhar',
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
              onTap: () async {
                Navigator.pop(context);
                await _sharingService.shareEvent(activity);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fechar',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconDate icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1F2937) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_available, size: 64, color: Colors.grey),
            ),
            SizedBox(height: 24),
            Text(
              'No events',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 8),
            Text(
              _selectedFilter == 'all'
                  ? 'Add your first event'
                  : _selectedFilter == 'past'
                  ? 'No events passado ainda'
                  : 'No events nesta categoria',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (_selectedFilter != 'past') ...[
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<Activity>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NewActivityScreen(),
                    ),
                  );
                  if (result != null) {
                    await _activityRepository.save(result);
                    if (mounted) {
                      _showEventCreatedDialog(result);
                    }
                  }
                },
                icon: Icon(Icons.add),
                label: Text('Create Ewind'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
