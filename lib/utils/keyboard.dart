import 'package:universal_io/io.dart';
import 'package:flutter/services.dart';

bool isScrollModifierPresseed() {
  const ctrlKeys = [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight];
  const metaKeys = [LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.meta];
  final scrollModifierKeys = Platform.isMacOS ? metaKeys : ctrlKeys;
  return scrollModifierKeys.any((key) => RawKeyboard.instance.keysPressed.contains(key));
}

bool isShiftPressed() {
  return RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
      RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftRight);
}
