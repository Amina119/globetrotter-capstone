import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the logged-in user's session (JWT token + identity) and notifies
/// listeners so the app can react to login/logout without manual routing.
class Session extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _emailKey = 'auth_email';
  static const _nameKey = 'auth_name';
  static const _preferencesKey = 'auth_preferences';
  static const _isAdminKey = 'auth_is_admin';

  String? token;
  String? email;
  String? name;
  bool isAdmin = false;

  /// The interest tags this user chose when creating their account (e.g.
  /// `food`, `culture`), used to personalize the home dashboard's
  /// "Recommended for you" section. Remembered on this device across
  /// logins, since there's no "fetch my profile" endpoint yet.
  List<String> preferences = [];

  bool get isLoggedIn => token != null;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    email = prefs.getString(_emailKey);
    name = prefs.getString(_nameKey);
    isAdmin = prefs.getBool(_isAdminKey) ?? false;
    preferences = prefs.getStringList(_preferencesKey) ?? [];
    notifyListeners();
  }

  /// Logs in with [email]/[token]/[name]/[isAdmin]. Pass [preferences] right
  /// after registration (they're only known client-side at that moment);
  /// omit it for a plain login and the previously remembered preferences
  /// (if any) on this device are kept.
  Future<void> login({
    required String email,
    required String token,
    String? name,
    bool isAdmin = false,
    List<String>? preferences,
  }) async {
    this.email = email;
    this.token = token;
    this.name = name;
    this.isAdmin = isAdmin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_nameKey, name ?? '');
    await prefs.setBool(_isAdminKey, isAdmin);
    if (preferences != null) {
      this.preferences = preferences;
      await prefs.setStringList(_preferencesKey, preferences);
    } else {
      this.preferences = prefs.getStringList(_preferencesKey) ?? [];
    }
    notifyListeners();
  }

  /// Updates the locally-held name/preferences (and persists them) after a
  /// successful `PUT /profile` call, so every widget watching [Session] —
  /// anywhere in the app — reflects the change immediately, without needing
  /// to log out and back in.
  Future<void> updateProfile({String? name, List<String>? preferences}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      this.name = name;
      await prefs.setString(_nameKey, name);
    }
    if (preferences != null) {
      this.preferences = preferences;
      await prefs.setStringList(_preferencesKey, preferences);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    email = null;
    name = null;
    isAdmin = false;
    preferences = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_isAdminKey);
    await prefs.remove(_preferencesKey);
    notifyListeners();
  }
}
