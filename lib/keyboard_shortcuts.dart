import 'package:universal_io/io.dart'; // dart:io's Platform does not work in browser for checking OS
import 'package:flutter/services.dart';

class KeyboardShortcutManager {
  static get zoomKeys => Platform.operatingSystem == 'macos' ? [LogicalKeyboardKey.metaLeft] : [LogicalKeyboardKey.controlLeft];
  static get deleteKeys => [LogicalKeyboardKey.delete, LogicalKeyboardKey.backspace];
  static get deselectKeys => [LogicalKeyboardKey.escape];
  static get cancelDrawingKeys => [LogicalKeyboardKey.escape];

  static bool isZoomKeypressed(RawKeyboard rawKeyboard) {
    return zoomKeys.any((key) => RawKeyboard.instance.keysPressed.contains(key));
  }

  static bool isDeleteKeyPressed(RawKeyboard rawKeyboard) {
    return deleteKeys.any((key) => RawKeyboard.instance.keysPressed.contains(key));
  }

  static bool isDeselectKeyPressed(RawKeyboard rawKeyboard) {
    return deselectKeys.any((key) => RawKeyboard.instance.keysPressed.contains(key));
  }

  static bool isCancelDrawingKeyPressed(RawKeyboard rawKeyboard) {
    return cancelDrawingKeys.any((key) => RawKeyboard.instance.keysPressed.contains(key));
  }
}
