import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

const defaultStrokeWidth = 4;
const defaultTagNodeColor = Colors.lime;
const defaultEntryNodeColor = Colors.grey;
const defaultExitNodeColor = Color.fromARGB(255, 96, 96, 96);
final defaultObliviousEdgeColor = Colors.red;
final defaultAwareEdgeColor = Colors.green;

enum PreferenceKey { strokeWidth, tagNodeColor, entryNodeColor, exitNodeColor, obliviousEdgeColor, awareEdgeColor }

Color getDefaultColor(PreferenceKey key) {
  switch (key) {
    case PreferenceKey.tagNodeColor:
      return defaultTagNodeColor;
    case PreferenceKey.entryNodeColor:
      return defaultEntryNodeColor;
    case PreferenceKey.exitNodeColor:
      return defaultExitNodeColor;
    case PreferenceKey.obliviousEdgeColor:
      return defaultObliviousEdgeColor;
    case PreferenceKey.awareEdgeColor:
      return defaultAwareEdgeColor;
    case PreferenceKey.strokeWidth:
      throw '${PreferenceKey.strokeWidth.name} has no default color!';
  }
}

class PreferencesManager {
  static Future<Preferences> getPreferences() async {
    final (strokeWidth, tagNodeColor, entryNodeColor, exitNodeColor, obliviousEdgeColor, awareEdgeColor) = await (
      getStrokeWidth(),
      getTagNodeColor(),
      getEntryNodeColor(),
      getExitNodeColor(),
      getObliviousEdgeColor(),
      getAwareEdgeColor()
    ).wait;

    return Preferences(
      strokeWidth: strokeWidth,
      tagNodeColor: tagNodeColor,
      entryNodeColor: entryNodeColor,
      exitNodeColor: exitNodeColor,
      obliviousEdgeColor: obliviousEdgeColor,
      awareEdgeColor: awareEdgeColor,
    );
  }

  static Future<void> clear() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
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
    await _setColor(PreferenceKey.tagNodeColor, color);
  }

  static Future<Color> getTagNodeColor() async {
    return await _getColor(PreferenceKey.tagNodeColor);
  }

  static Future<void> setEntryNodeColor(Color color) async {
    await _setColor(PreferenceKey.entryNodeColor, color);
  }

  static Future<Color> getEntryNodeColor() async {
    return await _getColor(PreferenceKey.entryNodeColor);
  }

  static Future<void> setExitNodeColor(Color color) async {
    await _setColor(PreferenceKey.exitNodeColor, color);
  }

  static Future<Color> getExitNodeColor() async {
    return await _getColor(PreferenceKey.exitNodeColor);
  }

  static Future<void> setObliviousEdgeColor(Color color) async {
    await _setColor(PreferenceKey.obliviousEdgeColor, color);
  }

  static Future<Color> getObliviousEdgeColor() async {
    return await _getColor(PreferenceKey.obliviousEdgeColor);
  }

  static Future<void> setAwareEdgeColor(Color color) async {
    await _setColor(PreferenceKey.awareEdgeColor, color);
  }

  static Future<Color> getAwareEdgeColor() async {
    return await _getColor(PreferenceKey.awareEdgeColor);
  }

  static Future<Color> _getColor(PreferenceKey key) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    int colorValue = preferences.getInt(key.name) ?? getDefaultColor(key).value;
    return Color(colorValue);
  }

  static Future<void> _setColor(PreferenceKey key, Color color) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(key.name, color.value);
  }
}

class Preferences {
  final int strokeWidth;
  Color tagNodeColor;
  Color entryNodeColor;
  Color exitNodeColor;
  Color obliviousEdgeColor;
  Color awareEdgeColor;

  Preferences(
      {int? strokeWidth,
      Color? tagNodeColor,
      Color? entryNodeColor,
      Color? exitNodeColor,
      Color? obliviousEdgeColor,
      Color? awareEdgeColor})
      : strokeWidth = strokeWidth ?? defaultStrokeWidth,
        tagNodeColor = tagNodeColor ?? defaultTagNodeColor,
        entryNodeColor = entryNodeColor ?? defaultEntryNodeColor,
        exitNodeColor = exitNodeColor ?? defaultExitNodeColor,
        obliviousEdgeColor = obliviousEdgeColor ?? defaultObliviousEdgeColor,
        awareEdgeColor = awareEdgeColor ?? defaultAwareEdgeColor;

  @override
  String toString() {
    return 'Preferences{strokeWidth: $strokeWidth, tagNodeColor: $tagNodeColor, entryNodeColor: $entryNodeColor, exitNodeColor: $exitNodeColor}';
  }
}
