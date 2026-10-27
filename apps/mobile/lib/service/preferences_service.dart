//lib/service/preferences_service.dart

//import 'package:shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String languageKey = 'language_is_bengali';

  static Future<bool> getLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(languageKey) ?? false;
  }

  static Future<void> setLanguagePreference(bool isBengali) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(languageKey, isBengali);
  }
}
