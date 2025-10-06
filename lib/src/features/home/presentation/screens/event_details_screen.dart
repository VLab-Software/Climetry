import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/event_weather_prediction_service.dart';
import '../../../../core/services/event_sharing_service.dart';
import '../../../weather/domain/entities/weather_alert.dart';
import '../../../activities/presentation/screens/edit_activity_screen.dart';
import '../../../activities/data/repositories/activity_repository.dart';
import '../../../activities/presentation/widgets/custom_alerts_settings.dart';
import '../../../friends/domain/entities/friend.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventWeatherAnalysis analysis;

  const EventDetailsScreen({super.key, required this.analysis});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  Timer? _countdownTimer;
  String _timeRemaining = '';
  final EventSharingService _sharingService = EventSharingService();

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimeRemaining();
      }
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    final eventDate = widget.analysis.activity.date;
    final difference = eventDate.difference(now);

    if (difference.isNegative) {
      setState(() {
        _timeRemaining = 'Ewind passou';
      });
      _countdownTimer?.cancel();
      return;
    }

    final weeks = difference.inDays ~/ 7;
    final days = difference.inDays % 7;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    String result = '';
    if (weeks > 0) {
      result += '$weeks sem ';
    }
    if (days > 0 || weeks > 0) {
      result += '$days d ';
    }
    if (hours > 0 || days > 0 || weeks > 0) {
      result += '$hours h ';
    }
    if (minutes > 0 || hours > 0 || days > 0 || weeks > 0) {
      result += '$minutes min ';
    }
    result += '$seconds seg';

    setState(() {
      _timeRemaining = result.trim();
    });
  }

  void _showShareOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compartilhar Ewind',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_today, color: Color(0xFF3B82F6)),
              ),
              title: const Text('Add to Calendar'),
              subtitle: const Text('Google Calendar ou Apple Calendar'),
              onTap: () async {
                Navigator.pop(context);
                final success = await _sharingService.addToCalendar(widget.analysis.activity);
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
            
            const Divider(),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chat_bubble, color: Color(0xFF25D366)),
              ),
              title: const Text('Compartilhar no WhatsApp'),
              subtitle: const Text('Enviar convite com link'),
              onTap: () async {
                Navigator.pop(context);
                await _sharingService.shareViaWhatsApp(activity: widget.analysis.activity);
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share, color: Color(0xFF8B5CF6)),
              ),
              title: const Text('Compartilhar'),
              subtitle: const Text('Email, SMS, outras apps'),
              onTap: () async {
                Navigator.pop(context);
                await _sharingService.shareEvent(widget.analysis.activity);
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _leaveEvent() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final activity = widget.analysis.activity;

    if (activity.isOwner(currentUserId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Você é o dono deste ewind e cannot sair. Delete o ewind se necessário.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout do Ewind'),
        content: Text('Are you sure you want to leave this event? You will no longer receive updates about it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final updatedActivity = activity.copyWith(
        participants: activity.participants
            .where((p) => p.userId != currentUserId)
            .toList(),
      );

      final repository = ActivityRepository();
      await repository.update(updatedActivity);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Você saiu do ewind com success'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ao sair do ewind: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showCustomAlertsSettings(EventParticipant participant, bool isAdmin) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: CustomAlertsSettings(
          currentSettings: participant.customAlertSettings ?? {},
          isAdmin: isAdmin,
          onSave: (settings) async {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId == null) return;

            try {
              final activity = widget.analysis.activity;
              final applyToAll = settings['applyToAll'] == true;
              settings.remove('applyToAll');

              List<EventParticipant> updatedParticipants;
              
              if (applyToAll && isAdmin) {
                updatedParticipants = activity.participants.map((p) {
                  return p.copyWith(customAlertSettings: settings);
                }).toList();
              } else {
                updatedParticipants = activity.participants.map((p) {
                  if (p.userId == currentUserId) {
                    return p.copyWith(customAlertSettings: settings);
                  }
                  return p;
                }).toList();
              }

              final updatedActivity = activity.copyWith(
                participants: updatedParticipants,
              );

              final repository = ActivityRepository();
              await repository.update(updatedActivity);

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    applyToAll 
                        ? 'Settings applied to all participants'
                        : 'Your alert settings have been saved',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              if (!mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error ao salvar configurações: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'pt_BR');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0F1419) : Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: widget.analysis.riskColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share, color: Colors.white),
                onPressed: () => _showShareOptions(),
                tooltip: 'Compartilhar ewind',
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditActivityScreen(
                        activity: widget.analysis.activity,
                      ),
                    ),
                  );

                  if (result != null && context.mounted) {
                    Navigator.pop(context);
                  }
                },
                tooltip: 'Edit ewind',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.analysis.activity.title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.analysis.riskColor,
                      widget.analysis.riskColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.analysis.activity.type.icon,
                        style: TextStyle(fontSize: 64),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.analysis.riskLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    isDark,
                    icon: Icons.calendar_today,
                    title: 'Date e Time',
                    content:
                        '${dateFormat.format(widget.analysis.activity.date)}\n${timeFormat.format(widget.analysis.activity.date)}',
                  ),
                  SizedBox(height: 16),

                  _buildInfoCard(
                    isDark,
                    icon: Icons.schedule,
                    title: 'Tempo restante',
                    content: _timeRemaining,
                  ),
                  SizedBox(height: 16),

                  _buildInfoCard(
                    isDark,
                    icon: Icons.location_on,
                    title: 'Location',
                    content:
                        '${widget.analysis.activity.coordinates.latitude.toStringAsFixed(4)}, ${widget.analysis.activity.coordinates.longitude.toStringAsFixed(4)}',
                  ),
                  
                  Builder(
                    builder: (context) {
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      final activity = widget.analysis.activity;
                      
                      if (currentUserId != null && 
                          activity.participants.any((p) => p.userId == currentUserId)) {
                        
                        final participant = activity.participants
                            .firstWhere((p) => p.userId == currentUserId);
                        final isAdmin = participant.role == EventRole.owner || 
                                       participant.role == EventRole.admin;
                        
                        return Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showCustomAlertsSettings(participant, isAdmin),
                              icon: Icon(Icons.tune, size: 18),
                              label: Text('Configurar Alertas Personalizados'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xFF3B82F6),
                                side: BorderSide(color: Color(0xFF3B82F6)),
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                  
                  SizedBox(height: 24),

                  _buildSectionTitle('Participants', isDark),
                  SizedBox(height: 12),
                  _buildParticipantsCard(isDark),
                  SizedBox(height: 24),

                  if (widget.analysis.weather != null) ...[
                    _buildSectionTitle('Previsão do Tempo', isDark),
                    SizedBox(height: 12),
                    _buildWeatherCard(isDark),
                    SizedBox(height: 24),
                  ],

                  if (widget.analysis.alerts.isNotEmpty) ...[
                    _buildSectionTitle('Alertas Climáticos', isDark),
                    SizedBox(height: 12),
                    ...widget.analysis.alerts.map(
                      (alert) => _buildAlertCard(alert, isDark),
                    ),
                    SizedBox(height: 24),
                  ],

                  if (widget.analysis.aiInsight != null) ...[
                    _buildSectionTitle('Análise Inteligente', isDark),
                    SizedBox(height: 12),
                    _buildAIInsightCard(isDark),
                    SizedBox(height: 24),
                  ],

                  if (widget.analysis.suggestions.isNotEmpty) ...[
                    _buildSectionTitle('Sugestões', isDark),
                    SizedBox(height: 12),
                    ...widget.analysis.suggestions.map(
                      (suggestion) => _buildSuggestionCard(suggestion, isDark),
                    ),
                    SizedBox(height: 24),
                  ],

                  Builder(
                    builder: (context) {
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      final activity = widget.analysis.activity;
                      
                      final isParticipant = currentUserId != null && 
                          activity.participants.any((p) => p.userId == currentUserId);
                      final isOwner = currentUserId != null && activity.isOwner(currentUserId);
                      
                      if (isParticipant && !isOwner) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _leaveEvent,
                                icon: Icon(Icons.logout, size: 18),
                                label: Text('Logout do Ewind'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                          ],
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildInfoCard(
    bool isDark, {
    required IconDate icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Color(0xFF3B82F6), size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildWeatherMetric(
            Icons.thermostat,
            '${widget.analysis.weather!.maxTemp.toStringAsFixed(0)}°F',
            'Temperature',
            isDark,
          ),
          Container(
            width: 1,
            height: 50,
            color: isDark ? Color(0xFF374151) : Color(0xFFE5E7EB),
          ),
          _buildWeatherMetric(
            Icons.water_drop,
            '${widget.analysis.weather!.precipitation.toStringAsFixed(0)}mm',
            'Rain',
            isDark,
          ),
          Container(
            width: 1,
            height: 50,
            color: isDark ? Color(0xFF374151) : Color(0xFFE5E7EB),
          ),
          _buildWeatherMetric(
            Icons.air,
            '${widget.analysis.weather!.windSpeed.toStringAsFixed(0)}km/h',
            'Wind',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetric(
    IconDate icon,
    String value,
    String label,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF3B82F6), size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAlertCard(alert, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFF59E0B).withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.warning_amber,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getAlertLabel(alert.type),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${alert.value.toStringAsFixed(1)} ${alert.unit}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.psychology, color: Colors.white, size: 20),
              ),
              SizedBox(width: 10),
              Text(
                'Análise IA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            widget.analysis.aiInsight!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(EventSuggestion suggestion, bool isDark) {
    final icon = _getSuggestionIcon(suggestion.type);
    final color = _getSuggestionColor(suggestion.priority);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getSuggestionTypeLabel(suggestion.type),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getPriorityLabel(suggestion.priority),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  suggestion.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconDate _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.reschedule:
        return Icons.event_available;
      case SuggestionType.relocate:
        return Icons.location_on;
      case SuggestionType.prepare:
        return Icons.inwindry_2;
      case SuggestionType.cancel:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getSuggestionColor(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.high:
        return Color(0xFFEF4444);
      case SuggestionPriority.medium:
        return Color(0xFFF59E0B);
      case SuggestionPriority.low:
        return Color(0xFF3B82F6);
    }
  }

  String _getSuggestionTypeLabel(SuggestionType type) {
    switch (type) {
      case SuggestionType.reschedule:
        return 'Reagendar';
      case SuggestionType.relocate:
        return 'Mudar Local';
      case SuggestionType.prepare:
        return 'Preparação';
      case SuggestionType.cancel:
        return 'Considerar Cancelamento';
      default:
        return 'Sugestão';
    }
  }

  String _getPriorityLabel(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.high:
        return 'ALTA';
      case SuggestionPriority.medium:
        return 'MÉDIA';
      case SuggestionPriority.low:
        return 'BAIXA';
    }
  }

  Widget _buildParticipantsCard(bool isDark) {
    final activity = widget.analysis.activity;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId != null && activity.isOwner(currentUserId);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: const Color(0xFF3B82F6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Participants (${activity.participants.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...activity.participants.map((participant) {
            final isCurrentUser = participant.userId == currentUserId;
            final isOwnerParticipant = participant.userId == activity.ownerId;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: participant.photoUrl != null
                        ? NetworkImage(participant.photoUrl!)
                        : null,
                    backgroundColor: const Color(0xFF3B82F6),
                    child: participant.photoUrl == null
                        ? Text(
                            participant.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              participant.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Você',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildRoleBadge(participant.role, isOwnerParticipant),
                            
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(participant.status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getStatusLabel(participant.status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _getStatusColor(participant.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  if (isOwner && !isOwnerParticipant && participant.role != EventRole.admin)
                    IconButton(
                      icon: const Icon(Icons.star_border, size: 20),
                      color: const Color(0xFFFBBF24),
                      onPressed: () {
                        print('Promover ${participant.name} a admin');
                      },
                      tooltip: 'Promover a Admin',
                    ),
                  
                  if (isOwner && !isOwnerParticipant && participant.role == EventRole.admin)
                    IconButton(
                      icon: const Icon(Icons.star, size: 20),
                      color: const Color(0xFFFBBF24),
                      onPressed: () {
                        print('Rebaixar ${participant.name} de admin');
                      },
                      tooltip: 'Remover Admin',
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(EventRole role, bool isOwner) {
    String emoji;
    String label;
    Color color;
    
    if (isOwner) {
      emoji = '👑';
      label = 'Dono';
      color = const Color(0xFFFBBF24);
    } else if (role == EventRole.admin) {
      emoji = '⭐';
      label = 'Admin';
      color = const Color(0xFF3B82F6);
    } else {
      emoji = '👤';
      label = 'Convidado';
      color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.accepted:
        return const Color(0xFF10B981);
      case ParticipantStatus.pending:
        return const Color(0xFFF59E0B);
      case ParticipantStatus.rejected:
        return Colors.red;
      case ParticipantStatus.maybe:
        return const Color(0xFF3B82F6);
    }
  }

  String _getStatusLabel(ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.accepted:
        return 'Confirmado';
      case ParticipantStatus.pending:
        return 'Pendente';
      case ParticipantStatus.rejected:
        return 'Recusou';
      case ParticipantStatus.maybe:
        return 'Maybe';
    }
  }

  String _getAlertLabel(WeatherAlertType type) {
    switch (type) {
      case WeatherAlertType.heavyRain:
        return 'Rain Forte';
      case WeatherAlertType.floodRisk:
        return 'Risco de Alagamento';
      case WeatherAlertType.heatWave:
        return 'Onda de Calor';
      case WeatherAlertType.intenseCold:
        return 'Frio Intenso';
      case WeatherAlertType.frostRisk:
        return 'Risco de Geada';
      case WeatherAlertType.strongWind:
        return 'Wind Forte';
      case WeatherAlertType.severeStorm:
        return 'Tempestade Severa';
      case WeatherAlertType.thermalDiscomfort:
        return 'Desconforto Térmico';
      default:
        return type.toString();
    }
  }
}
