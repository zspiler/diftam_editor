import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

const defaultNodePadding = 3;
const defaultNodeStrokeWidth = 4;
const defaultEdgeStrokeWidth = 4;
const defaultTagNodeColor = Colors.lime;
const defaultEntryNodeColor = Colors.grey;
const defaultExitNodeColor = Colors.grey;
const defaultObliviousEdgeColor = Colors.red;
const defaultAwareEdgeColor = Colors.green;

enum PreferenceKey {
  nodePadding,
  nodeStrokeWidth,
  edgeStrokeWidth,
  tagNodeColor,
  entryNodeColor,
  exitNodeColor,
  obliviousEdgeColor,
  awareEdgeColor
}

class PreferencesManager {
  static late final SharedPreferences preferences;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) {
      return;
    }
    preferences = await SharedPreferences.getInstance();
    _initialized = true;
  }

  static void clear() {
    preferences.clear();
  }

  static Preferences getPreferences() {
    return Preferences(
      nodePadding: getNodePadding(),
      nodeStrokeWidth: getNodeStrokeWidth(),
      edgeStrokeWidth: getEdgeStrokeWidth(),
      tagNodeColor: getTagNodeColor(),
      entryNodeColor: getEntryNodeColor(),
      exitNodeColor: getExitNodeColor(),
      obliviousEdgeColor: getObliviousEdgeColor(),
      awareEdgeColor: getAwareEdgeColor(),
    );
  }

  static void setNodePadding(int value) {
    preferences.setInt(PreferenceKey.nodePadding.name, value);
  }

  static int getNodePadding() {
    return preferences.getInt(PreferenceKey.nodePadding.name) ?? defaultNodePadding;
  }

  static int getNodeStrokeWidth() {
    return preferences.getInt(PreferenceKey.nodeStrokeWidth.name) ?? defaultNodeStrokeWidth;
  }

  static int getEdgeStrokeWidth() {
    return preferences.getInt(PreferenceKey.edgeStrokeWidth.name) ?? defaultEdgeStrokeWidth;
  }

  static Color getTagNodeColor() {
    return _getColor(PreferenceKey.tagNodeColor) ?? defaultTagNodeColor;
  }

  static Color getEntryNodeColor() {
    return _getColor(PreferenceKey.entryNodeColor) ?? defaultEntryNodeColor;
  }

  static Color getExitNodeColor() {
    return _getColor(PreferenceKey.exitNodeColor) ?? defaultExitNodeColor;
  }

  static Color getObliviousEdgeColor() {
    return _getColor(PreferenceKey.obliviousEdgeColor) ?? defaultObliviousEdgeColor;
  }

  static Color getAwareEdgeColor() {
    return _getColor(PreferenceKey.awareEdgeColor) ?? defaultAwareEdgeColor;
  }

  static void setNodeStrokeWidth(int value) {
    preferences.setInt(PreferenceKey.nodeStrokeWidth.name, value);
  }

  static void setEdgeStrokeWidth(int value) {
    preferences.setInt(PreferenceKey.edgeStrokeWidth.name, value);
  }

  static void setTagNodeColor(Color color) {
    _setColor(PreferenceKey.tagNodeColor, color);
  }

  static void setEntryNodeColor(Color color) {
    _setColor(PreferenceKey.entryNodeColor, color);
  }

  static void setExitNodeColor(Color color) {
    _setColor(PreferenceKey.exitNodeColor, color);
  }

  static void setObliviousEdgeColor(Color color) async {
    _setColor(PreferenceKey.obliviousEdgeColor, color);
  }

  static void setAwareEdgeColor(Color color) async {
    _setColor(PreferenceKey.awareEdgeColor, color);
  }

  static Color? _getColor(PreferenceKey key) {
    int? colorValue = preferences.getInt(key.name);
    return colorValue == null ? null : Color(colorValue);
  }

  static void _setColor(PreferenceKey key, Color color) {
    preferences.setInt(key.name, color.value);
  }
}

class Preferences {
  final int nodePadding;
  final int nodeStrokeWidth;
  final int edgeStrokeWidth;
  Color tagNodeColor;
  Color entryNodeColor;
  Color exitNodeColor;
  Color obliviousEdgeColor;
  Color awareEdgeColor;

  Preferences(
      {int? nodePadding,
      int? nodeStrokeWidth,
      int? edgeStrokeWidth,
      Color? tagNodeColor,
      Color? entryNodeColor,
      Color? exitNodeColor,
      Color? obliviousEdgeColor,
      Color? awareEdgeColor})
      : nodePadding = nodePadding ?? defaultNodePadding,
        nodeStrokeWidth = nodeStrokeWidth ?? defaultNodeStrokeWidth,
        edgeStrokeWidth = edgeStrokeWidth ?? defaultEdgeStrokeWidth,
        tagNodeColor = tagNodeColor ?? defaultTagNodeColor,
        entryNodeColor = entryNodeColor ?? defaultEntryNodeColor,
        exitNodeColor = exitNodeColor ?? defaultExitNodeColor,
        obliviousEdgeColor = obliviousEdgeColor ?? defaultObliviousEdgeColor,
        awareEdgeColor = awareEdgeColor ?? defaultAwareEdgeColor;

  @override
  String toString() {
    return 'Preferences{nodePadding: $nodePadding nodeStrokeWidth: $nodeStrokeWidth, edgeStrokeWidth: $edgeStrokeWidth, tagNodeColor: $tagNodeColor, entryNodeColor: $entryNodeColor, exitNodeColor: $exitNodeColor} obliviousEdgeColor: $obliviousEdgeColor, awareEdgeColor: $awareEdgeColor';
  }
}
