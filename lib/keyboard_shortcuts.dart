import 'package:universal_io/io.dart'; // dart:io's Platform does not work in browser for checking OS
import 'package:flutter/services.dart';

class KeyboardShortcutManager {
  static bool isZoomKeypressed(RawKeyboard rawKeyboard) {
    final zoomKey = Platform.operatingSystem == 'macos' ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft;
    return RawKeyboard.instance.keysPressed.contains(zoomKey);
  }
}
