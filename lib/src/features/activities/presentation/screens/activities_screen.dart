import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/event_weather_prediction_service.dart';
import 'new_activity_screen.dart';
import '../../../home/presentation/screens/event_details_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> with AutomaticKeepAliveClientMixin {
  final UserDataService _userDataService = UserDataService();
  final EventWeatherPredictionService _predictionService = EventWeatherPredictionService();
  
  List<Activity> _allActivities = [];
  List<Activity> _filteredActivities = [];
  Map<String, EventWeatherAnalysis> _analyses = {};
  String _selectedFilter = 'all'; // all, upcoming, past
  bool _isLoading = true;
  bool _isAnalyzing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    if (FirebaseAuth.instance.currentUser == null) {
      if (!mounted) return;
      setState(() {
        _allActivities = [];
        _filteredActivities = [];
        _isLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final loadedActivities = await _userDataService.getActivities();
      
      // Analisar eventos futuros
      final now = DateTime.now();
      final futureEvents = loadedActivities.where((a) => a.date.isAfter(now)).toList();
      
      if (!mounted) return;
      setState(() {
        _allActivities = loadedActivities;
        _filteredActivities = loadedActivities;
        _isLoading = false;
      });
      
      // Analisar clima em background
      if (futureEvents.isNotEmpty) {
        _analyzeActivities(futureEvents);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
        debugPrint('Erro ao analisar ${activity.title}: $e');
      }
    }
    
    if (!mounted) return;
    setState(() => _isAnalyzing = false);
  }

  void _applyFilters() {
    final now = DateTime.now();
    List<Activity> filtered = List.from(_allActivities);
    
    // Filtro de tempo
    if (_selectedFilter == 'upcoming') {
      filtered = filtered.where((a) => a.date.isAfter(now)).toList();
    } else if (_selectedFilter == 'past') {
      filtered = filtered.where((a) => a.date.isBefore(now)).toList();
    }
    
    // Ordenar por data
    filtered.sort((a, b) => b.date.compareTo(a.date));
    
    setState(() => _filteredActivities = filtered);
  }

  Future<void> _deleteActivity(Activity activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1F2937),
        title: Text('Excluir Evento', style: TextStyle(color: Colors.white)),
        content: Text(
          'Deseja realmente excluir "${activity.title}"?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userDataService.deleteActivity(activity.id);
        if (!mounted) return;
        setState(() {
          _allActivities.removeWhere((a) => a.id == activity.id);
          _analyses.remove(activity.id);
        });
        _applyFilters();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Evento excluído'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
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
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(isDark),
          ),

          // Filtros
          SliverToBoxAdapter(
            child: _buildFilters(isDark),
          ),

          // Loading
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF3B82F6)),
                    SizedBox(height: 16),
                    Text(
                      'Carregando eventos...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          // Empty State
          else if (_filteredActivities.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(isDark),
            )
          // Lista de eventos
          else
            SliverPadding(
              padding: EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final activity = _filteredActivities[index];
                    final analysis = _analyses[activity.id];
                    return _buildActivityCard(activity, analysis, isDark);
                  },
                  childCount: _filteredActivities.length,
                ),
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // FAB só aparece quando NÃO está no filtro "Passados"
      floatingActionButton: _selectedFilter == 'past' 
          ? null 
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push<Activity>(
                  context,
                  MaterialPageRoute(builder: (_) => const NewActivityScreen()),
                );
                if (result != null) {
                  // Salvar no Firebase
                  await _userDataService.saveActivity(result);
                  // Recarregar lista
                  _loadActivities();
                  // Mostrar sucesso
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('✅ Evento "${result.title}" criado com sucesso!'),
                          ],
                        ),
                        backgroundColor: Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              backgroundColor: Color(0xFF3B82F6),
              icon: Icon(Icons.add, color: Colors.white),
              label: Text('Novo Evento', style: TextStyle(color: Colors.white)),
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
                      'Agenda',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      '${_allActivities.length} eventos',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isAnalyzing)
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrar por',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12),
          // Filtro de tempo
          Row(
            children: [
              _buildFilterChip('Todos', 'all', isDark),
              SizedBox(width: 8),
              _buildFilterChip('Próximos', 'upcoming', isDark),
              SizedBox(width: 8),
              _buildFilterChip('Passados', 'past', isDark),
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

  Widget _buildActivityCard(Activity activity, EventWeatherAnalysis? analysis, bool isDark) {
    final dateFormat = DateFormat('dd MMM', 'pt_BR');
    final timeFormat = DateFormat('HH:mm');
    final now = DateTime.now();
    final isPast = activity.date.isBefore(now);
    final daysUntil = activity.date.difference(now).inDays;

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
                    // Ícone
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isPast
                            ? Colors.grey.withOpacity(0.1)
                            : (analysis?.riskColor.withOpacity(0.1) ?? Color(0xFF3B82F6).withOpacity(0.1)),
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
                    // Info
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
                          if (!isPast && daysUntil >= 0) ...[
                            SizedBox(height: 4),
                            Text(
                              daysUntil == 0
                                  ? 'Hoje'
                                  : daysUntil == 1
                                      ? 'Amanhã'
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
                    // Status/Ações
                    Column(
                      children: [
                        if (!isPast && analysis != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Excluir', style: TextStyle(color: Colors.red)),
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
                
                // Alertas
                if (!isPast && analysis != null && analysis.alerts.isNotEmpty) ...[
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
                
                // Sugestões da IA
                if (!isPast && analysis != null && analysis.suggestions.isNotEmpty) ...[
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
                        Icon(
                          Icons.psychology,
                          size: 16,
                          color: Colors.white,
                        ),
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
                
                // Badge de passado
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
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Evento concluído',
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
              child: Icon(
                Icons.event_available,
                size: 64,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Nenhum evento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 8),
            Text(
              _selectedFilter == 'all'
                  ? 'Adicione seu primeiro evento'
                  : _selectedFilter == 'past'
                      ? 'Nenhum evento passado ainda'
                      : 'Nenhum evento nesta categoria',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            // Botão só aparece se NÃO for filtro "Passados"
            if (_selectedFilter != 'past') ...[
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<Activity>(
                    context,
                    MaterialPageRoute(builder: (_) => const NewActivityScreen()),
                  );
                  if (result != null) {
                    // Salvar no Firebase
                    await _userDataService.saveActivity(result);
                    // Recarregar lista
                    _loadActivities();
                    // Mostrar sucesso
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('✅ Evento "${result.title}" criado!'),
                            ],
                          ),
                          backgroundColor: Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  }
                },
                icon: Icon(Icons.add),
                label: Text('Criar Evento'),
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
