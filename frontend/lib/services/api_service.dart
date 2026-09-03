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

  /// Returns the JWT token, the account holder's display name, and whether
  /// the account is an admin.
  Future<(String token, String name, bool isAdmin)> login(String email, String password) async {
    final res = await http.post(
      _uri('/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(res);
    return (data['token'] as String, (data['name'] ?? '').toString(), data['is_admin'] == true);
  }

  /// Exchanges a Google ID token for a GlobeTrotter session. Auto-registers
  /// the account on first sign-in.
  ///
  /// Returns the same shape as [login].
  Future<(String token, String name, bool isAdmin)> loginWithGoogle(String idToken) async {
    final res = await http.post(
      _uri('/auth/google'),
      headers: _headers,
      body: jsonEncode({'credential': idToken}),
    );
    final data = _decode(res);
    return (data['token'] as String, (data['name'] ?? '').toString(), data['is_admin'] == true);
  }

  /// Returns the current user's own profile: `{email, name, preferences, is_admin}`.
  Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(_uri('/profile'), headers: _headers);
    return _decode(res) as Map<String, dynamic>;
  }

  /// Updates the current user's name and/or preferences. Pass only the
  /// fields that changed.
  Future<Map<String, dynamic>> updateProfile({String? name, List<String>? preferences}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (preferences != null) body['preferences'] = preferences;
    final res = await http.put(_uri('/profile'), headers: _headers, body: jsonEncode(body));
    return _decode(res) as Map<String, dynamic>;
  }

  /// Returns `{average, count, entries}` for a single place — every user's
  /// rating/comment on it, so it's visible to everyone, not just the
  /// submitter.
  Future<Map<String, dynamic>> getPlaceReviews(String placeId) async {
    final res = await http.get(_uri('/places/$placeId/reviews'), headers: _headers);
    return _decode(res) as Map<String, dynamic>;
  }

  /// Creates or replaces the current user's rating/comment on a place.
  Future<Map<String, dynamic>> submitPlaceReview(String placeId, {required int rating, String comment = ''}) async {
    final res = await http.post(
      _uri('/places/$placeId/reviews'),
      headers: _headers,
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );
    return _decode(res) as Map<String, dynamic>;
  }

  Future<void> deletePlaceReview(String placeId) async {
    final res = await http.delete(_uri('/places/$placeId/reviews'), headers: _headers);
    _decode(res);
  }

  Future<List<dynamic>> getPlaceComments(String placeId) async {
    final res = await http.get(_uri('/places/$placeId/comments'), headers: _headers);
    final data = _decode(res) as Map<String, dynamic>;


    return data['entries'] as List<dynamic>;
  }

    Future<Map<String, dynamic>> postPlaceComment(String placeId, {required String text, String? parentId}) async {
    final res = await http.post(
      _uri('/places/$placeId/comments'),
      headers: _headers,
      body: jsonEncode({'text': text, 'parent_id': parentId}),
    );
    return _decode(res) as Map<String, dynamic>;
  }

  Future<void> deletePlaceComment(String placeId, String commentId) async {
    final res = await http.delete(_uri('/places/$placeId/comments/$commentId'), headers: _headers);
    _decode(res);
  }

  Future<List<dynamic>> getChatMessages() async {
    final res = await http.get(_uri('/chat'), headers: _headers);
    final data = _decode(res) as Map<String, dynamic>;
    return data['entries'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> postChatMessage({required String text, String? parentId}) async {
    final res = await http.post(
      _uri('/chat'),
      headers: _headers,
      body: jsonEncode({'text': text, 'parent_id': parentId}),
    );
    return _decode(res) as Map<String, dynamic>;
  }

  Future<void> deleteChatMessage(String messageId) async {
    final res = await http.delete(_uri('/chat/$messageId'), headers: _headers);
    _decode(res);
  }





  /// Requests a password reset token for [email].
  ///
  /// Returns the reset token. The backend has no outgoing email
  /// integration, so the token is returned directly instead of being
  /// emailed to the user.
  /// Requests a password reset token for [email].
  ///
  /// The backend never returns the token here — it's emailed to the user
  /// (or logged server-side if email isn't configured) so this endpoint
  /// can't be used to check whether an email is registered. The caller
  /// must have the user enter the token manually on the next screen.
  Future<void> forgotPassword(String email) async {
    final res = await http.post(
      _uri('/forgot-password'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    _decode(res);
  }

  /// Consumes a reset [token] for [email] and sets [newPassword] as the account's password.
  Future<void> resetPassword(String email, String token, String newPassword) async {
    final res = await http.post(
      _uri('/reset-password'),
      headers: _headers,
      body: jsonEncode({'email': email, 'token': token, 'password': newPassword}),
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

  /// Returns `{average, count, entries}` — every user's submitted app
  /// rating/comment, so the average shown is genuinely computed from real
  /// submissions rather than hardcoded.
  Future<Map<String, dynamic>> getFeedback() async {
    final res = await http.get(_uri('/feedback'), headers: _headers);
    return _decode(res) as Map<String, dynamic>;
  }

  /// Creates or replaces the current user's app rating/comment.
  Future<Map<String, dynamic>> submitFeedback({required int rating, String comment = ''}) async {
    final res = await http.post(
      _uri('/feedback'),
      headers: _headers,
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );
    return _decode(res) as Map<String, dynamic>;
  }

  Future<void> deleteFeedback() async {
    final res = await http.delete(_uri('/feedback'), headers: _headers);
    _decode(res);
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

  /// Adds a destination to the catalogue. Admin only.
  Future<Map<String, dynamic>> adminCreateDestination({
    required String name,
    required String town,
    required String quarter,
    required String sector,
    required List<String> tags,
    int? avgCostPerDay,
    double? latitude,
    double? longitude,
  }) async {
    final res = await http.post(
      _uri('/admin/destinations'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'Town': town,
        'quarter': quarter,
        'sector': sector,
        'tags': tags,
        'avg_cost_per_day': avgCostPerDay,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return _decode(res) as Map<String, dynamic>;
  }

  /// Edits a destination in the catalogue, including its map position. Admin only.
  Future<Map<String, dynamic>> adminUpdateDestination(
    String id, {
    required String name,
    required String town,
    required String quarter,
    required String sector,
    required List<String> tags,
    int? avgCostPerDay,
    double? latitude,
    double? longitude,
  }) async {
    final res = await http.put(
      _uri('/admin/destinations/$id'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'Town': town,
        'quarter': quarter,
        'sector': sector,
        'tags': tags,
        'avg_cost_per_day': avgCostPerDay,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return _decode(res) as Map<String, dynamic>;
  }

  /// Removes a destination from the catalogue. Admin only.
  Future<void> adminDeleteDestination(String id) async {
    final res = await http.delete(_uri('/admin/destinations/$id'), headers: _headers);
    _decode(res);
  }
}
