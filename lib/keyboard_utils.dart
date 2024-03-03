import 'package:universal_io/io.dart';
import 'package:flutter/services.dart';

const _ctrlKeys = [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight];
const _metaKeys = [LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.meta];

class KeyboardUtils {
  static final _scrollModifierKeys = Platform.isMacOS ? _metaKeys : _ctrlKeys;

  static bool isScrollModifierPresseed() {
    return _scrollModifierKeys.any((key) => RawKeyboard.instance.keysPressed.contains(key));
  }

  static bool isShiftPressed() {
    return RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
        RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftRight);
  }
}
