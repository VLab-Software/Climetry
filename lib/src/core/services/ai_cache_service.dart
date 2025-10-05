import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço de cache para insights de IA no Firestore
/// Evita chamadas desnecessárias à API quando as condições climáticas não mudaram
class AICacheService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const Duration _cacheDuration = Duration(hours: 6);

  String? get _userId => _auth.currentUser?.uid;

  /// Gera ID de cache baseado nas condições climáticas
  String _generateCacheId({
    required String eventId,
    required double temperature,
    required double precipitation,
    required double windSpeed,
    required int uvIndex,
  }) {
    // Arredondar valores para criar chaves mais genéricas
    final tempRounded = (temperature / 5).round() * 5;
    final precipRounded = (precipitation / 10).round() * 10;
    final windRounded = (windSpeed / 10).round() * 10;

    return '${eventId}_${tempRounded}_${precipRounded}_${windRounded}_$uvIndex';
  }

  /// Verifica se existe cache válido para as condições atuais
  Future<String?> getCachedInsight({
    required String eventId,
    required double temperature,
    required double precipitation,
    required double windSpeed,
    required int uvIndex,
  }) async {
    try {
      if (_userId == null) return null;

      final cacheId = _generateCacheId(
        eventId: eventId,
        temperature: temperature,
        precipitation: precipitation,
        windSpeed: windSpeed,
        uvIndex: uvIndex,
      );

      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('ai_cache')
          .doc(cacheId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final timestamp = (data['timestamp'] as Timestamp).toDate();

      // Verificar se o cache ainda é válido
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        // Cache expirado, remover
        await doc.reference.delete();
        return null;
      }

      return data['insight'] as String;
    } catch (e) {
      return null;
    }
  }

  /// Salva insight no cache
  Future<void> cacheInsight({
    required String eventId,
    required double temperature,
    required double precipitation,
    required double windSpeed,
    required int uvIndex,
    required String insight,
  }) async {
    try {
      if (_userId == null) return;

      final cacheId = _generateCacheId(
        eventId: eventId,
        temperature: temperature,
        precipitation: precipitation,
        windSpeed: windSpeed,
        uvIndex: uvIndex,
      );

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('ai_cache')
          .doc(cacheId)
          .set({
        'insight': insight,
        'timestamp': FieldValue.serverTimestamp(),
        'eventId': eventId,
      });
    } catch (e) {
      // Falha silenciosa no cache
    }
  }

  /// Limpa todo o cache de insights
  Future<void> clearCache() async {
    try {
      if (_userId == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('ai_cache')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      // Falha silenciosa
    }
  }

  /// Limpa cache de um evento específico
  Future<void> clearEventCache(String eventId) async {
    try {
      if (_userId == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('ai_cache')
          .where('eventId', isEqualTo: eventId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      // Falha silenciosa
    }
  }
}
