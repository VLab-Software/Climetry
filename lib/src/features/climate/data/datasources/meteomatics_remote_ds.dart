import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/weather_payload.dart';

class MeteomaticsRemoteDataSource {
  final ApiClient client;
  // 🔐 injete via construtor/secure storage no app real
  final String username;
  final String password;

  MeteomaticsRemoteDataSource({
    required this.client,
    this.username = 'soares_rodrigo',
    this.password = 'Jv37937j7LF8noOrpK1c',
  });

  Future<WeatherPayload> fetch({
    required String timeRange,
    required String variables,
    required String location,
  }) async {
    final uri = Uri.parse('https://api.meteomatics.com/$timeRange/$variables/$location/json');
    final creds = base64Encode(utf8.encode('$username:$password'));
    final res = await client.get(uri, headers: {
      'Authorization': 'Basic $creds',
      'Accept': 'application/json',
    });
    return WeatherPayload(json.decode(res.body) as Map<String, dynamic>);
  }
}
