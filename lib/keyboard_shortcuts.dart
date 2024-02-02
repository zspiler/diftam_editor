import 'package:universal_io/io.dart'; // dart:io's Platform does not work in browser for checking OS
import 'package:flutter/services.dart';

const ctrlKeys = [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight];
const metaKeys = [LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.meta];

class KeyboardShortcutManager {
  static get scrollKeys => Platform.operatingSystem == 'macos' ? metaKeys : ctrlKeys;
  static get deleteKeys => [LogicalKeyboardKey.delete, LogicalKeyboardKey.backspace];
  static get deselectKeys => [LogicalKeyboardKey.escape];
  static get cancelDrawingKeys => [LogicalKeyboardKey.escape];

  static bool isMetaPressed(RawKeyboard rawKeyboard) {
    return metaKeys.any((key) => RawKeyboard.instance.keysPressed.contains(key));
  }

  static bool isCtrlPressed(RawKeyboard rawKeyboard) {
    return ctrlKeys.any((key) => RawKeyboard.instance.keysPressed.contains(key));
  }

  static bool isScrollKeyPresseed(RawKeyboard rawKeyboard) {
    return scrollKeys.any((key) => RawKeyboard.instance.keysPressed.contains(key));
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
