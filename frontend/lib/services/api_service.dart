import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base URL of the GlobeTrotter Flask API.
///
/// Override at build/run time, e.g.:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://your-vps-ip:5000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5000',
);

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  final String? token;

  ApiService({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
  }

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? '{}' : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    final message = body is Map && body['error'] != null
        ? body['error'].toString()
        : 'Request failed (${res.statusCode})';
    throw ApiException(message, res.statusCode);
  }

  Future<String> register(String name, String email, String password, List<String> preferences) async {
    final res = await http.post(
      _uri('/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'preferences': preferences,
      }),
    );
    final data = _decode(res);
    return data['email']?.toString() ?? email;
  }

  /// Returns the JWT token and the account holder's display name.
  Future<(String token, String name)> login(String email, String password) async {
    final res = await http.post(
      _uri('/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(res);
    return (data['token'] as String, (data['name'] ?? '').toString());
  }

  /// Exchanges a Google ID token for a GlobeTrotter session. Auto-registers
  /// the account on first sign-in.
  ///
  /// Returns the JWT token and the account holder's display name, same
  /// shape as [login].
  Future<(String token, String name)> loginWithGoogle(String idToken) async {
    final res = await http.post(
      _uri('/auth/google'),
      headers: _headers,
      body: jsonEncode({'credential': idToken}),
    );
    final data = _decode(res);
    return (data['token'] as String, (data['name'] ?? '').toString());
  }

  /// Requests a password reset token for [email].
  ///
  /// Returns the reset token. The backend has no outgoing email
  /// integration, so the token is returned directly instead of being
  /// emailed to the user.
  Future<String> forgotPassword(String email) async {
    final res = await http.post(
      _uri('/forgot-password'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    final data = _decode(res);
    return data['reset_token'] as String;
  }

  /// Consumes a reset [token] and sets [newPassword] as the account's password.
  Future<void> resetPassword(String token, String newPassword) async {
    final res = await http.post(
      _uri('/reset-password'),
      headers: _headers,
      body: jsonEncode({'token': token, 'new_password': newPassword}),
    );
    _decode(res);
  }

  Future<List<dynamic>> searchDestinations({
    String? q,
    String? tag,
    String? quarter,
    int? maxCost,
  }) async {
    final query = <String, String>{};
    if (q != null && q.isNotEmpty) query['q'] = q;
    if (tag != null && tag.isNotEmpty) query['tag'] = tag;
    if (quarter != null && quarter.isNotEmpty) query['quarter'] = quarter;
    if (maxCost != null) query['max_cost'] = maxCost.toString();

    final res = await http.get(_uri('/destinations', query), headers: _headers);
    return _decode(res) as List<dynamic>;
  }

  Future<List<dynamic>> getRecommendations({int limit = 5}) async {
    final res = await http.get(
      _uri('/recommendations', {'limit': limit.toString()}),
      headers: _headers,
    );
    return _decode(res) as List<dynamic>;
  }

  Future<List<dynamic>> getItineraries() async {
    final res = await http.get(_uri('/itineraries'), headers: _headers);
    return _decode(res) as List<dynamic>;
  }

  /// Itineraries other users have shared with the current user.
  Future<List<dynamic>> getSharedItineraries() async {
    final res = await http.get(_uri('/itineraries/shared'), headers: _headers);
    return _decode(res) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createItinerary({
    required String title,
    required List<String> destinations,
    required String startDate,
    required String endDate,
    String notes = '',
  }) async {
    final res = await http.post(
      _uri('/itineraries'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'destinations': destinations,
        'start_date': startDate,
        'end_date': endDate,
        'notes': notes,
      }),
    );
    return _decode(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateItinerary(
    String id, {
    required String title,
    required List<String> destinations,
    required String startDate,
    required String endDate,
    String notes = '',
  }) async {
    final res = await http.put(
      _uri('/itineraries/$id'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'destinations': destinations,
        'start_date': startDate,
        'end_date': endDate,
        'notes': notes,
      }),
    );
    return _decode(res) as Map<String, dynamic>;
  }

  Future<void> deleteItinerary(String id) async {
    final res = await http.delete(_uri('/itineraries/$id'), headers: _headers);
    _decode(res);
  }

  /// Grants [email] view access to the itinerary with [id].
  Future<void> shareItinerary(String id, String email) async {
    final res = await http.post(
      _uri('/itineraries/$id/share'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    _decode(res);
  }

  /// Revokes [email]'s view access to the itinerary with [id].
  Future<void> unshareItinerary(String id, String email) async {
    final res = await http.delete(
      _uri('/itineraries/$id/share'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    _decode(res);
  }
}
