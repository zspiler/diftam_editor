import 'package:shared_preferences/shared_preferences.dart';

const defaultStrokeWidth = 4;

class PreferencesManager {
  static const _strokeWidthKey = 'strokeWidth';

  static Future<void> setStrokeWidth(int value) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_strokeWidthKey, value);
  }

  static Future<int> getStrokeWidth() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_strokeWidthKey) ?? defaultStrokeWidth;
  }

  static Future<void> clear() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }
}

class Preferences {
  final int strokeWidth;

  Preferences({int? strokeWidth}) : strokeWidth = strokeWidth ?? defaultStrokeWidth;
}
