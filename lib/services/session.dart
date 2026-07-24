import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the logged-in user's session (JWT token + identity) and notifies
/// listeners so the app can react to login/logout without manual routing.
class Session extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _emailKey = 'auth_email';
  static const _nameKey = 'auth_name';

  String? token;
  String? email;
  String? name;

  bool get isLoggedIn => token != null;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    email = prefs.getString(_emailKey);
    name = prefs.getString(_nameKey);
    notifyListeners();
  }

  Future<void> login({required String email, required String token, String? name}) async {
    this.email = email;
    this.token = token;
    this.name = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_nameKey, name ?? '');
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    email = null;
    name = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    notifyListeners();
  }
}
