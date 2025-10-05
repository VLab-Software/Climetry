import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client _client;
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> get(
      Uri uri, {
        Map<String, String>? headers,
      }) async {
    final res = await _client.get(uri, headers: headers);
    _throwIfError(res);
    return res;
  }

  static void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ApiException(
      statusCode: res.statusCode,
      body: res.body,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException({required this.statusCode, required this.body});
  @override
  String toString() => 'ApiException(statusCode: $statusCode, body: $body)';
}