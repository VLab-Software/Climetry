import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../../core/services/user_data_service.dart';
import 'new_activity_screen.dart';
import 'activity_details_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final UserDataService _userDataService = UserDataService();
  List<Activity> activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    // Verificar se está autenticado
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() {
        activities = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final loadedActivities = await _userDataService.getActivities();
      if (mounted) {
        setState(() {
          activities = loadedActivities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar atividades: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteActivity(Activity activity) async {
    try {
      await _userDataService.deleteActivity(activity.id);
      if (mounted) {
        setState(() {
          activities.removeWhere((a) => a.id == activity.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atividade removida'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A3A),
        elevation: 0,
        title: const Text('Atividades'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : activities.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadActivities,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  100,
                ), // Padding para floating tab bar
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  return _buildActivityCard(activities[index]);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewActivityScreen()),
          );
          if (result != null && result is Activity) {
            try {
              await _userDataService.saveActivity(result);
              await _loadActivities();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Atividade salva com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao salvar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
        backgroundColor: const Color(0xFF4A9EFF),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.white38,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma atividade agendada',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para adicionar uma nova',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    final dateFormat = DateFormat('d MMM, yyyy', 'pt_BR');
    final timeStr = activity.startTime ?? '--:--';

    return Card(
      color: const Color(0xFF2A3A4D),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivityDetailsScreen(activity: activity),
            ),
          );
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Remover Atividade'),
              content: Text('Deseja remover "${activity.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteActivity(activity);
                  },
                  child: const Text(
                    'Remover',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9EFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    activity.type.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.location,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${dateFormat.format(activity.date)} • $timeStr',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
