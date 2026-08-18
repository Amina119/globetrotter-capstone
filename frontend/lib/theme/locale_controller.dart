import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's language choice (English/French) and persists it
/// on-device. Null means "follow the device's system language".
class LocaleController extends ChangeNotifier {
  static const _key = 'locale_code';

  Locale? locale;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    locale = saved == null ? null : Locale(saved);
    notifyListeners();
  }

  Future<void> setLocale(Locale? newLocale) async {
    locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    if (newLocale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, newLocale.languageCode);
    }
    notifyListeners();
  }
}
