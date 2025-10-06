import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/daily_weather.dart';
import '../../../activities/domain/entities/activity.dart';
import 'meteomatics_service.dart';
import '../../../../core/services/openai_service.dart';

class WeatherMonitoringService {
  final MeteomaticsService _meteomaticsService = MeteomaticsService();
  final OpenAIService _openAIService = OpenAIService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> startMonitoring(Activity activity) async {
    try {
      final forecast = await _meteomaticsService.getEventDayForecast(
        activity.coordinates,
        activity.date,
      );

      await _firestore
          .collection('weather_monitoring')
          .doc(activity.id)
          .set({
        'activityId': activity.id,
        'activityTitle': activity.title,
        'eventDate': activity.date.toIso8601String(),
        'location': {
          'latitude': activity.coordinates.latitude,
          'longitude': activity.coordinates.longitude,
        },
        'lastForecast': _forecastToMap(forecast),
        'lastChecked': DateTime.now().toIso8601String(),
        'userId': activity.ownerId,
        'participants': activity.participants.map((p) => p.userId).toList(),
        'monitoring': true,
        'notificationsSent': 0,
      });

      print('✅ Monitoramento iniciado para: ${activity.title}');
    } catch (e) {
      print('❌ Error ao iniciar monitoramento: $e');
    }
  }

  Future<void> checkAllEvents() async {
    try {
      final now = DateTime.now();
      
      final snapshot = await _firestore
          .collection('weather_monitoring')
          .where('monitoring', isEqualTo: true)
          .where('eventDate', isGreaterThan: now.toIso8601String())
          .get();

      print('🔍 Verificando ${snapshot.docs.length} ewinds...');

      for (var doc in snapshot.docs) {
        await _checkEventWeather(doc);
      }

      print('✅ Verificação completa');
    } catch (e) {
      print('❌ Error ao verificar ewinds: $e');
    }
  }

  Future<void> _checkEventWeather(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      final data = doc.data();
      final activityId = data['activityId'] as String;
      final activityTitle = data['activityTitle'] as String;
      final eventDate = DateTime.parse(data['eventDate'] as String);
      final location = data['location'] as Map<String, dynamic>;
      final lastForecastMap = data['lastForecast'] as Map<String, dynamic>;
      
      final lat = location['latitude'] as double;
      final lon = location['longitude'] as double;

      final lastForecast = _mapToForecast(lastForecastMap, eventDate);

      final changes = await _meteomaticsService.detectWeatherChanges(
        location: LatLng(lat, lon),
        eventDate: eventDate,
        previousForecast: lastForecast,
      );

      if (changes['hasChanges'] == true) {
        print('⚠️ Mudanças detectadas em: $activityTitle');

        await doc.reference.update({
          'lastForecast': _forecastToMap(changes['currentForecast']),
          'lastChecked': DateTime.now().toIso8601String(),
          'notificationsSent': FieldValue.increment(1),
        });

        await _generateUpdatedInsights(
          activityId,
          activityTitle,
          changes,
        );

        await _sendChangeNotifications(
          activityId,
          activityTitle,
          eventDate,
          changes,
          data['participants'] as List,
        );
      } else {
        await doc.reference.update({
          'lastChecked': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('❌ Error ao verificar ewind ${doc.id}: $e');
    }
  }

  Future<void> _generateUpdatedInsights(
    String activityId,
    String activityTitle,
    Map<String, dynamic> changes,
  ) async {
    try {
      final significantChanges = changes['significantChanges'] as List;
      final currentForecast = changes['currentForecast'] as DailyWeather;

      final changesDescription = significantChanges.map((c) {
        return '- ${c['message']} (${c['severity']})';
      }).join('\n');

      final prompt = '''
Você é um assistente climático. Houve mudanças significativas na previsão do tempo para o ewind "$activityTitle":

**Mudanças Detectadas:**
$changesDescription

**Nova Previsão:**
- Temperature: ${currentForecast.minTemp.toInt()}-${currentForecast.maxTemp.toInt()}°F
- Rain: ${currentForecast.precipitation.toInt()}mm (${currentForecast.precipitationProbability.toInt()}%)
- Wind: ${currentForecast.windSpeed.toInt()} mph

Forneça recomendações práticas e atualizadas (máximo 5 pontos):
''';

      final insights = await _openAIService.generateEventAnalysis(
        prompt,
        maxTokens: 300,
      );

      await _firestore
          .collection('weather_insights')
          .doc(activityId)
          .set({
        'activityId': activityId,
        'insights': insights,
        'generatedAt': DateTime.now().toIso8601String(),
        'forecast': _forecastToMap(currentForecast),
        'changes': significantChanges,
      }, SetOptions(merge: true));

      print('✅ Insights atualizados para: $activityTitle');
    } catch (e) {
      print('❌ Error ao gerar insights: $e');
    }
  }

  Future<void> _sendChangeNotifications(
    String activityId,
    String activityTitle,
    DateTime eventDate,
    Map<String, dynamic> changes,
    List participants,
  ) async {
    try {
      final significantChanges = changes['significantChanges'] as List;
      final daysUntil = eventDate.difference(DateTime.now()).inDays;

      String getMainChange() {
        if (significantChanges.isEmpty) return 'Previsão atualizada';
        final first = significantChanges.first;
        return first['message'] as String;
      }

      String getIcon() {
        if (significantChanges.isEmpty) return '⛅';
        final first = significantChanges.first;
        return first['icon'] as String;
      }

      final title = '${getIcon()} $activityTitle - Clima Atualizado';
      final body = daysUntil == 0
          ? 'Today: ${getMainChange()}'
          : daysUntil == 1
              ? 'Tomorrow: ${getMainChange()}'
              : 'Em $daysUntil dias: ${getMainChange()}';

      for (var participantId in participants) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(participantId)
              .get();

          if (userDoc.exists) {
            final fcmToken = userDoc.data()?['fcmToken'] as String?;
            
            if (fcmToken != null && fcmToken.isNotEmpty) {
              await _firestore.collection('notifications').add({
                'userId': participantId,
                'activityId': activityId,
                'title': title,
                'body': body,
                'type': 'weather_change',
                'severity': _getHighestSeverity(significantChanges),
                'changes': significantChanges,
                'fcmToken': fcmToken,
                'sentAt': DateTime.now().toIso8601String(),
                'read': false,
              });
            }
          }
        } catch (e) {
          print('❌ Error ao enviar notificação para $participantId: $e');
        }
      }

      print('✅ Notifications sent to ${participants.length} users');
    } catch (e) {
      print('❌ Error ao enviar notificações: $e');
    }
  }

  Future<void> stopMonitoring(String activityId) async {
    try {
      await _firestore
          .collection('weather_monitoring')
          .doc(activityId)
          .update({'monitoring': false});

      print('✅ Monitoramento parado para: $activityId');
    } catch (e) {
      print('❌ Error ao parar monitoramento: $e');
    }
  }

  Future<void> sendDayOfEventNotification(Activity activity) async {
    try {
      final summary = await _meteomaticsService.getEventWeatherSummary(
        location: activity.coordinates,
        eventDate: activity.date,
        eventName: activity.title,
      );

      if (summary['shouldNotify'] == true) {
        final title = '${summary['emoji']} ${summary['title']}';
        final body = '${summary['body']}\n${summary['recommendation']}';

        final participants = activity.participants.map((p) => p.userId).toList();
        
        for (var userId in participants) {
          await _firestore.collection('notifications').add({
            'userId': userId,
            'activityId': activity.id,
            'title': title,
            'body': body,
            'type': 'day_of_event',
            'forecast': _forecastToMap(summary['forecast']),
            'alerts': (summary['alerts'] as List).map((a) => {
              'type': a.type.label,
              'message': a.type.description,
            }).toList(),
            'sentAt': DateTime.now().toIso8601String(),
            'read': false,
          });
        }

        print('✅ Day notification sent to: ${activity.title}');
      }
    } catch (e) {
      print('❌ Error sending day notification: $e');
    }
  }


  Map<String, dynamic> _forecastToMap(DailyWeather forecast) {
    return {
      'date': forecast.date.toIso8601String(),
      'minTemp': forecast.minTemp,
      'maxTemp': forecast.maxTemp,
      'meanTemp': forecast.meanTemp,
      'precipitation': forecast.precipitation,
      'precipitationProbability': forecast.precipitationProbability,
      'windSpeed': forecast.windSpeed,
      'windGust': forecast.windGust,
      'humidity': forecast.humidity,
      'uvIndex': forecast.uvIndex,
      'cape': forecast.cape,
      'hail': forecast.hail,
    };
  }

  DailyWeather _mapToForecast(Map<String, dynamic> map, DateTime date) {
    return DailyWeather(
      date: date,
      minTemp: (map['minTemp'] as num).toDouble(),
      maxTemp: (map['maxTemp'] as num).toDouble(),
      meanTemp: (map['meanTemp'] as num).toDouble(),
      precipitation: (map['precipitation'] as num).toDouble(),
      precipitationProbability:
          (map['precipitationProbability'] as num).toDouble(),
      windSpeed: (map['windSpeed'] as num).toDouble(),
      windGust: (map['windGust'] as num?)?.toDouble(),
      humidity: (map['humidity'] as num).toDouble(),
      uvIndex: (map['uvIndex'] as num).toDouble(),
      cape: (map['cape'] as num?)?.toDouble(),
      hail: (map['hail'] as num?)?.toDouble(),
    );
  }

  String _getHighestSeverity(List changes) {
    for (var change in changes) {
      if (change['severity'] == 'high') return 'high';
    }
    for (var change in changes) {
      if (change['severity'] == 'medium') return 'medium';
    }
    return 'low';
  }
}
