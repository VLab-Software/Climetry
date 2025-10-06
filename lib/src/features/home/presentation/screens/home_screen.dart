import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/event_weather_prediction_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/providers/event_refresh_notifier.dart';
import '../../../weather/domain/entities/weather_alert.dart';
import '../../../weather/domain/entities/daily_weather.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../activities/data/repositories/activity_repository.dart';
import '../../../activities/presentation/widgets/participants_avatars.dart';
import '../widgets/notifications_sheet.dart';
import 'event_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final ActivityRepository _activityRepository = ActivityRepository();
  final EventWeatherPredictionService _predictionService =
      EventWeatherPredictionService();

  List<EventWeatherAnalysis> _analyses = [];
  List<EventWeatherAnalysis> _filteredAnalyses = [];
  bool _loading = true;

  String _selectedFilter = 'time'; // 'time', 'distance', 'priority'

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadEventsPredictions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventRefreshNotifier = Provider.of<EventRefreshNotifier>(
        context,
        listen: false,
      );
      eventRefreshNotifier.addListener(_onEventsChanged);
    });
  }

  @override
  void dispose() {
    final eventRefreshNotifier = Provider.of<EventRefreshNotifier>(
      context,
      listen: false,
    );
    eventRefreshNotifier.removeListener(_onEventsChanged);
    super.dispose();
  }

  void _onEventsChanged() {
    _loadEventsPredictions();
  }

  Future<void> _loadEventsPredictions() async {
    if (!mounted) return;
    
    try {
      debugPrint('🔄 Iniciando carregamento de ewinds...');
      
      if (mounted) {
        setState(() => _loading = true);
      }
      
      final events = await _activityRepository.getAll()
          .timeout(
            const Duration(seconds: 5), // Reduzido para 5s
            onTimeout: () {
              debugPrint('⚠️ Timeout loading ewinds (5s)');
              return [];
            },
          );

      debugPrint('✅ Ewinds carregados: ${events.length}');

      final now = DateTime.now();
      final sixMonthsLater = now.add(const Duration(days: 180));

      final upcomingEvents = events.where((event) {
        return event.date.isAfter(now) && event.date.isBefore(sixMonthsLater);
      }).toList();

      debugPrint('📅 Ewinds futuros: ${upcomingEvents.length}');

      upcomingEvents.sort((a, b) => a.date.compareTo(b.date));

      if (!mounted) return;
      setState(() {
        _analyses = []; // Vazio por enquanto
        _filteredAnalyses = [];
        _loading = false; // LIBERA A UI IMEDIATAMENTE
      });

      final eventsToAnalyze = upcomingEvents.take(10).toList();
      debugPrint('🌤️ Iniciando análise de ${eventsToAnalyze.length} ewinds em background...');

      final analyses = <EventWeatherAnalysis>[];
      for (final event in eventsToAnalyze) {
        try {
          debugPrint('🌤️ Analisando clima para: ${event.title}');
          final analysis = await _predictionService.analyzeEvent(event)
              .timeout(
                const Duration(seconds: 8), // Timeout por ewind
                onTimeout: () {
                  debugPrint('⏱️ Timeout ao analisar ${event.title}');
                  throw TimeoutException('Análise timeout');
                },
              );
          analyses.add(analysis);
          debugPrint('✅ Análise concluída para: ${event.title}');
          
          if (mounted) {
            setState(() {
              _analyses = List.from(analyses);
              _filteredAnalyses = List.from(analyses);
              _applyFilter();
            });
          }
        } catch (e) {
          debugPrint('⚠️ Error ao analisar ewind ${event.title}: $e');
        }
      }

      debugPrint('✅ Análises completadas: ${analyses.length}');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading previsões: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _analyses = [];
        _filteredAnalyses = [];
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    List<EventWeatherAnalysis> filtered = List.from(_analyses);

    switch (_selectedFilter) {
      case 'time':
        filtered.sort((a, b) => a.activity.date.compareTo(b.activity.date));
        break;
      case 'distance':
        break;
      case 'priority':
        filtered.sort((a, b) {
          final priorityOrder = {
            ActivityPriority.urgent: 0,
            ActivityPriority.high: 1,
            ActivityPriority.medium: 2,
            ActivityPriority.low: 3,
          };
          return (priorityOrder[a.activity.priority] ?? 999).compareTo(
            priorityOrder[b.activity.priority] ?? 999,
          );
        });
        break;
    }

    setState(() {
      _filteredAnalyses = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessário para AutomaticKeepAliveClientMixin

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark =
        themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111827)
          : const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: _loadEventsPredictions,
        color: const Color(0xFF3B82F6),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildModernHeader(isDark, themeProvider),
            ),

            if (_loading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF3B82F6)),
                      SizedBox(height: 16),
                      Text(
                        'Analisando ewinds...',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_analyses.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF1F2937) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_available,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'No upcoming events',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Adicione ewinds na aba Ewinds',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildModernEventCard(
                      _filteredAnalyses[index],
                      isDark,
                    );
                  }, childCount: _filteredAnalyses.length),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isDark, ThemeProvider themeProvider) {
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
                child: Icon(Icons.home, color: Color(0xFF3B82F6), size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Clima sob controle',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              StreamBuilder<int>(
                stream: NotificationService().getUnreadCountStream(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;

                  return Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: isDark ? Colors.white : Color(0xFF1F2937),
                          size: 28,
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const NotificationsSheet(),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 20),

          Row(
            children: [
              Text(
                'Your Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Color(0xFF1F2937),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '${_analyses.length}',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showFilterSheet(isDark),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 18,
                          color: Color(0xFF3B82F6),
                        ),
                        SizedBox(width: 4),
                        Text(
                          _getFilterLabel(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case 'time':
        return 'Tempo';
      case 'distance':
        return 'Distância';
      case 'priority':
        return 'Prioridade';
      default:
        return 'Filtro';
    }
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
                  
                  _buildFilterOption(
                    icon: Icons.access_time,
                    title: 'Proximidade de tempo',
                    subtitle: 'Events closest first',
                    value: 'time',
                    isDark: isDark,
                  ),
                  
                  _buildFilterOption(
                    icon: Icons.location_on,
                    title: 'Proximidade de distância',
                    subtitle: 'Ewinds mais perto de você',
                    value: 'distance',
                    isDark: isDark,
                  ),
                  
                  _buildFilterOption(
                    icon: Icons.priority_high,
                    title: 'Por prioridade',
                    subtitle: 'Ewinds urgentes primeiro',
                    value: 'priority',
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
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isDark,
  }) {
    final isSelected = _selectedFilter == value;
    
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
          _selectedFilter = value;
          _applyFilter();
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildModernEventCard(EventWeatherAnalysis analysis, bool isDark) {
    final event = analysis.activity;
    final riskColor = analysis.riskColor;
    final riskIcon = analysis.riskIcon;
    final riskText = analysis.riskLabel;

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.95, end: 1.0),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(analysis: analysis),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: riskColor.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: riskColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
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
              // Enhanced header with gradient
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      riskColor.withOpacity(0.15),
                      riskColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(riskIcon, color: riskColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      riskText,
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatDaysUntil(event.date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event icon and title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            event.type.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(event.priority).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getPriorityLabel(event.priority),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getPriorityColor(event.priority),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date, time, location with better spacing
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: const Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _formatDate(event.date),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                              if (event.startTime != null) ...[
                                const Spacer(),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 18,
                                  color: const Color(0xFF8B5CF6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  event.startTime!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (event.location.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 18,
                                  color: const Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (analysis.weather != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF3B82F6).withOpacity(0.08),
                              const Color(0xFF8B5CF6).withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.cloud_outlined,
                                  size: 18,
                                  color: const Color(0xFF3B82F6),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Weather Forecast',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 20,
                              runSpacing: 14,
                              children: _buildCustomWeatherMetrics(
                                event,
                                analysis.weather!,
                                isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (analysis.alerts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: analysis.alerts.take(2).map((alert) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: riskColor.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getAlertIcon(alert.type),
                                  size: 14,
                                  color: riskColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getAlertName(alert.type),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: riskColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ParticipantsAvatars(
                          activity: event,
                          maxAvatars: 4,
                          avatarSize: 32,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: riskColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getPriorityColor(ActivityPriority priority) {
    return switch (priority) {
      ActivityPriority.urgent => const Color(0xFFEF4444),
      ActivityPriority.high => const Color(0xFFF59E0B),
      ActivityPriority.medium => const Color(0xFF3B82F6),
      ActivityPriority.low => const Color(0xFF10B981),
    };
  }
  
  String _getPriorityLabel(ActivityPriority priority) {
    return switch (priority) {
      ActivityPriority.urgent => 'URGENT',
      ActivityPriority.high => 'HIGH',
      ActivityPriority.medium => 'MEDIUM',
      ActivityPriority.low => 'LOW',
    };
  }

  List<Widget> _buildCustomWeatherMetrics(
    Activity event,
    DailyWeather weather,
    bool isDark,
  ) {
    final List<Widget> metrics = [];

    for (final condition in event.monitoredConditions) {
      switch (condition) {
        case WeatherCondition.temperature:
          metrics.add(
            _buildWeatherMetric(
              Icons.thermostat,
              '${weather.meanTemp.toStringAsFixed(0)}°F',
              isDark,
            ),
          );
          break;
        case WeatherCondition.rain:
          metrics.add(
            _buildWeatherMetric(
              Icons.water_drop,
              '${weather.precipitation.toStringAsFixed(0)}mm',
              isDark,
            ),
          );
          break;
        case WeatherCondition.wind:
          metrics.add(
            _buildWeatherMetric(
              Icons.air,
              '${weather.windSpeed.toStringAsFixed(0)} mph',
              isDark,
            ),
          );
          break;
        case WeatherCondition.humidity:
          metrics.add(
            _buildWeatherMetric(
              Icons.water,
              '${weather.humidity.toStringAsFixed(0)}%',
              isDark,
            ),
          );
          break;
        case WeatherCondition.uv:
          metrics.add(
            _buildWeatherMetric(
              Icons.wb_sunny,
              'UV ${weather.uvIndex.toStringAsFixed(0)}',
              isDark,
            ),
          );
          break;
      }
    }

    if (metrics.isEmpty) {
      metrics.add(
        _buildWeatherMetric(
          Icons.thermostat,
          '${weather.meanTemp.toStringAsFixed(0)}°F',
          isDark,
        ),
      );
      metrics.add(
        _buildWeatherMetric(
          Icons.water_drop,
          '${weather.precipitation.toStringAsFixed(0)}mm',
          isDark,
        ),
      );
    }

    return metrics;
  }

  Widget _buildWeatherMetric(IconData icon, String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.black54),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  String _formatDaysUntil(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 7) return 'In $difference days';
    if (difference < 30) return 'In ${(difference / 7).floor()} weeks';
    return 'Em ${(difference / 30).floor()} meses';
  }

  IconData _getAlertIcon(WeatherAlertType type) {
    return switch (type) {
      WeatherAlertType.heavyRain => Icons.water_drop,
      WeatherAlertType.severeStorm => Icons.thunderstorm,
      WeatherAlertType.heatWave => Icons.wb_sunny,
      WeatherAlertType.thermalDiscomfort => Icons.hot_tub,
      WeatherAlertType.intenseCold => Icons.ac_unit,
      WeatherAlertType.frostRisk => Icons.ac_unit,
      WeatherAlertType.strongWind => Icons.air,
      WeatherAlertType.floodRisk => Icons.waves,
      WeatherAlertType.hailRisk => Icons.cloud,
    };
  }

  String _getAlertName(WeatherAlertType type) {
    return switch (type) {
      WeatherAlertType.heavyRain => 'Rain Forte',
      WeatherAlertType.severeStorm => 'Tempestade',
      WeatherAlertType.heatWave => 'Onda de Calor',
      WeatherAlertType.thermalDiscomfort => 'Desconforto',
      WeatherAlertType.intenseCold => 'Frio Intenso',
      WeatherAlertType.frostRisk => 'Geada',
      WeatherAlertType.strongWind => 'Wind Forte',
      WeatherAlertType.floodRisk => 'Enchente',
      WeatherAlertType.hailRisk => 'Granizo',
    };
  }

}
