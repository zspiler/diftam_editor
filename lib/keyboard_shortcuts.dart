import 'package:universal_io/io.dart'; // dart:io's Platform does not work in browser for checking OS
import 'package:flutter/services.dart';

class KeyboardShortcutManager {
  static get zoomKeys => Platform.operatingSystem == 'macos' ? [LogicalKeyboardKey.metaLeft] : [LogicalKeyboardKey.controlLeft];
  static get deleteKeys => [LogicalKeyboardKey.delete, LogicalKeyboardKey.backspace];

  static bool isZoomKeypressed(RawKeyboard rawKeyboard) {
    return zoomKeys.any((key) => RawKeyboard.instance.keysPressed.contains(key));
  }

  static bool isDeleteKeyPressed(RawKeyboard rawKeyboard) {
    return deleteKeys.any((key) => RawKeyboard.instance.keysPressed.contains(key));
  }
}
