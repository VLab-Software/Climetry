import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Serviço de cache para insights de IA
/// Evita chamadas desnecessárias à API quando as condições climáticas não mudaram
class AICacheService {
  static const String _cachePrefix = 'ai_cache_';
  static const Duration _cacheDuration = Duration(
    hours: 6,
  ); // Cache válido por 6 horas

  /// Gera chave de cache baseada nas condições climáticas
  String _generateCacheKey({
    required String eventId,
    required double temperature,
    required double precipitation,
    required double windSpeed,
    required int uvIndex,
  }) {
    // Arredondar valores para criar chaves mais genéricas
    final tempRounded = (temperature / 5).round() * 5; // Intervalos de 5°C
    final precipRounded =
        (precipitation / 10).round() * 10; // Intervalos de 10mm
    final windRounded = (windSpeed / 10).round() * 10; // Intervalos de 10 km/h

    return '${_cachePrefix}${eventId}_${tempRounded}_${precipRounded}_${windRounded}_$uvIndex';
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
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(
        eventId: eventId,
        temperature: temperature,
        precipitation: precipitation,
        windSpeed: windSpeed,
        uvIndex: uvIndex,
      );

      final cachedData = prefs.getString(cacheKey);
      if (cachedData == null) return null;

      final data = json.decode(cachedData) as Map<String, dynamic>;
      final timestamp = DateTime.parse(data['timestamp'] as String);

      // Verificar se o cache ainda é válido
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        // Cache expirado, remover
        await prefs.remove(cacheKey);
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
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(
        eventId: eventId,
        temperature: temperature,
        precipitation: precipitation,
        windSpeed: windSpeed,
        uvIndex: uvIndex,
      );

      final data = {
        'insight': insight,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString(cacheKey, json.encode(data));
    } catch (e) {
      // Falha silenciosa no cache
    }
  }

  /// Limpa todo o cache de insights
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Falha silenciosa
    }
  }

  /// Limpa cache de um evento específico
  Future<void> clearEventCache(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith('${_cachePrefix}$eventId')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Falha silenciosa
    }
  }
}
