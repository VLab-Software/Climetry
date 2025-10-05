import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/event_weather_prediction_service.dart';
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
        _timeRemaining = 'Evento passou';
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

  Future<void> _leaveEvent() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final activity = widget.analysis.activity;

    // Check if user is the owner (owners cannot leave)
    if (activity.isOwner(currentUserId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Você é o dono deste evento e não pode sair. Delete o evento se necessário.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sair do Evento'),
        content: Text('Tem certeza que deseja sair deste evento? Você não receberá mais atualizações sobre ele.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Remove participant from activity
      final updatedActivity = activity.copyWith(
        participants: activity.participants
            .where((p) => p.userId != currentUserId)
            .toList(),
      );

      // Update in repository
      final repository = ActivityRepository();
      await repository.update(updatedActivity);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Você saiu do evento com sucesso'),
          backgroundColor: Colors.green,
        ),
      );

      // Go back to previous screen
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao sair do evento: $e'),
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

              // Update participant settings
              List<EventParticipant> updatedParticipants;
              
              if (applyToAll && isAdmin) {
                // Admin applying to all participants
                updatedParticipants = activity.participants.map((p) {
                  return p.copyWith(customAlertSettings: settings);
                }).toList();
              } else {
                // Update only current user
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
                        ? 'Configurações aplicadas para todos os participantes'
                        : 'Suas configurações de alerta foram salvas',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              if (!mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao salvar configurações: $e'),
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
          // App Bar
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
                    // Evento atualizado, voltar para tela anterior
                    Navigator.pop(context);
                  }
                },
                tooltip: 'Editar evento',
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

          // Conteúdo
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info básica
                  _buildInfoCard(
                    isDark,
                    icon: Icons.calendar_today,
                    title: 'Data e Hora',
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
                    title: 'Localização',
                    content:
                        '${widget.analysis.activity.coordinates.latitude.toStringAsFixed(4)}, ${widget.analysis.activity.coordinates.longitude.toStringAsFixed(4)}',
                  ),
                  
                  // Custom Alerts Configuration Button
                  Builder(
                    builder: (context) {
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      final activity = widget.analysis.activity;
                      
                      // Show button only for participants
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

                  // Previsão do tempo
                  if (widget.analysis.weather != null) ...[
                    _buildSectionTitle('Previsão do Tempo', isDark),
                    SizedBox(height: 12),
                    _buildWeatherCard(isDark),
                    SizedBox(height: 24),
                  ],

                  // Alertas
                  if (widget.analysis.alerts.isNotEmpty) ...[
                    _buildSectionTitle('Alertas Climáticos', isDark),
                    SizedBox(height: 12),
                    ...widget.analysis.alerts.map(
                      (alert) => _buildAlertCard(alert, isDark),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Insight da IA
                  if (widget.analysis.aiInsight != null) ...[
                    _buildSectionTitle('Análise Inteligente', isDark),
                    SizedBox(height: 12),
                    _buildAIInsightCard(isDark),
                    SizedBox(height: 24),
                  ],

                  // Sugestões
                  if (widget.analysis.suggestions.isNotEmpty) ...[
                    _buildSectionTitle('Sugestões', isDark),
                    SizedBox(height: 12),
                    ...widget.analysis.suggestions.map(
                      (suggestion) => _buildSuggestionCard(suggestion, isDark),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Botão Sair do Evento (apenas para participantes, não para donos)
                  Builder(
                    builder: (context) {
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      final activity = widget.analysis.activity;
                      
                      // Show button only if user is a participant but not the owner
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
                                label: Text('Sair do Evento'),
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
    required IconData icon,
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
            '${widget.analysis.weather!.maxTemp.toStringAsFixed(0)}°C',
            'Temperatura',
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
            'Chuva',
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
            'Vento',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetric(
    IconData icon,
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

  IconData _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.reschedule:
        return Icons.event_available;
      case SuggestionType.relocate:
        return Icons.location_on;
      case SuggestionType.prepare:
        return Icons.inventory_2;
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

  String _getAlertLabel(WeatherAlertType type) {
    switch (type) {
      case WeatherAlertType.heavyRain:
        return 'Chuva Forte';
      case WeatherAlertType.floodRisk:
        return 'Risco de Alagamento';
      case WeatherAlertType.heatWave:
        return 'Onda de Calor';
      case WeatherAlertType.intenseCold:
        return 'Frio Intenso';
      case WeatherAlertType.frostRisk:
        return 'Risco de Geada';
      case WeatherAlertType.strongWind:
        return 'Vento Forte';
      case WeatherAlertType.severeStorm:
        return 'Tempestade Severa';
      case WeatherAlertType.thermalDiscomfort:
        return 'Desconforto Térmico';
      default:
        return type.toString();
    }
  }
}
