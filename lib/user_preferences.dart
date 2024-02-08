import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

const defaultStrokeWidth = 4;
const defaultTagNodeColor = Colors.lime;
const defaultEntryNodeColor = Colors.grey;
const defaultExitNodeColor = Color.fromARGB(255, 96, 96, 96);

enum PreferenceKey {
  strokeWidth,
  tagNodeColor,
  entryNodeColor,
  exitNodeColor,
}

Color getDefaultColor(PreferenceKey key) {
  switch (key) {
    case PreferenceKey.tagNodeColor:
      return defaultTagNodeColor;
    case PreferenceKey.entryNodeColor:
      return defaultEntryNodeColor;
    case PreferenceKey.exitNodeColor:
      return defaultExitNodeColor;
    case PreferenceKey.strokeWidth:
      throw '${PreferenceKey.strokeWidth.name} has no default color!';
  }
}

class PreferencesManager {
  static Future<Preferences> getPreferences() async {
    final (strokeWidth, tagNodeColor, entryNodeColor, exitNodeColor) =
        await (getStrokeWidth(), getTagNodeColor(), getEntryNodeColor(), getExitNodeColor()).wait;

    return Preferences(
      strokeWidth: strokeWidth,
      tagNodeColor: tagNodeColor,
      entryNodeColor: entryNodeColor,
      exitNodeColor: exitNodeColor,
    );
  }

  static Future<void> setStrokeWidth(int value) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(PreferenceKey.strokeWidth.name, value);
  }

  static Future<int> getStrokeWidth() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getInt(PreferenceKey.strokeWidth.name) ?? defaultStrokeWidth;
  }

  static Future<void> setTagNodeColor(Color color) async {
    await setColor(PreferenceKey.tagNodeColor, color);
  }

  static Future<Color> getTagNodeColor() async {
    return await getColor(PreferenceKey.tagNodeColor);
  }

  static Future<void> setEntryNodeColor(Color color) async {
    await setColor(PreferenceKey.entryNodeColor, color);
  }

  static Future<Color> getEntryNodeColor() async {
    return await getColor(PreferenceKey.entryNodeColor);
  }

  static Future<void> setExitNodeColor(Color color) async {
    await setColor(PreferenceKey.exitNodeColor, color);
  }

  static Future<Color> getExitNodeColor() async {
    return await getColor(PreferenceKey.exitNodeColor);
  }

  static Future<Color> getColor(PreferenceKey key) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    int colorValue = preferences.getInt(key.name) ?? getDefaultColor(key).value;
    return Color(colorValue);
  }

  static Future<void> setColor(PreferenceKey key, Color color) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(key.name, color.value);
  }

  static Future<void> clear() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }
}

class Preferences {
  final int strokeWidth;
  Color tagNodeColor;
  Color entryNodeColor;
  Color exitNodeColor;

  Preferences({int? strokeWidth, Color? tagNodeColor, Color? entryNodeColor, Color? exitNodeColor})
      : strokeWidth = strokeWidth ?? defaultStrokeWidth,
        tagNodeColor = tagNodeColor ?? defaultTagNodeColor,
        entryNodeColor = entryNodeColor ?? defaultEntryNodeColor,
        exitNodeColor = exitNodeColor ?? defaultExitNodeColor;

  @override
  String toString() {
    return 'Preferences{strokeWidth: $strokeWidth, tagNodeColor: $tagNodeColor, entryNodeColor: $entryNodeColor, exitNodeColor: $exitNodeColor}';
  }
}
