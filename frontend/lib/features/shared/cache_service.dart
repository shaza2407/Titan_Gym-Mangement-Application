// frontend/lib/features/shared/cache_service.dart 

import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static Future<void> save(String key, String jsonData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonData);
  }

  static Future<String?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}