import 'package:flutter/material.dart';

class SnackbarGlobal {
  static GlobalKey<ScaffoldMessengerState> key = GlobalKey<ScaffoldMessengerState>();

  // TODO style
  static void show(String message) {
    key.currentState!
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          backgroundColor: Color.fromARGB(255, 47, 47, 47),
          content: Text(
            message,
            style: TextStyle(color: Colors.white),
          )));
  }
}
