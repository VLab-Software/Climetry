import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/activity.dart';

class ActivityRepository {
  static const String _activitiesKey = 'activities';
  
  Future<List<Activity>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_activitiesKey) ?? [];
      
      return jsonList.map((jsonStr) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return Activity.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar atividades: $e');
    }
  }

  Future<Activity?> getById(String id) async {
    final activities = await getAll();
    try {
      return activities.firstWhere((activity) => activity.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> save(Activity activity) async {
    try {
      final activities = await getAll();
      activities.add(activity);
      await _saveAll(activities);
    } catch (e) {
      throw Exception('Erro ao salvar atividade: $e');
    }
  }

  Future<void> update(Activity activity) async {
    try {
      final activities = await getAll();
      final index = activities.indexWhere((a) => a.id == activity.id);
      
      if (index == -1) {
        throw Exception('Atividade não encontrada');
      }
      
      activities[index] = activity;
      await _saveAll(activities);
    } catch (e) {
      throw Exception('Erro ao atualizar atividade: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final activities = await getAll();
      activities.removeWhere((activity) => activity.id == id);
      await _saveAll(activities);
    } catch (e) {
      throw Exception('Erro ao deletar atividade: $e');
    }
  }

  Future<void> _saveAll(List<Activity> activities) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = activities.map((activity) {
      return jsonEncode(activity.toJson());
    }).toList();
    
    await prefs.setStringList(_activitiesKey, jsonList);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activitiesKey);
  }
}
