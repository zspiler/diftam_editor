import 'package:flutter/material.dart';

class SnackbarGlobal {
  static GlobalKey<ScaffoldMessengerState> key = GlobalKey<ScaffoldMessengerState>();

  static void info(String message) {
    key.currentState!
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          backgroundColor: Color.fromARGB(255, 47, 47, 47),
          content: Text(
            message,
            style: TextStyle(color: Colors.white),
          )));
  }

  static void success(String message) {
    key.currentState!
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          backgroundColor: Color.fromARGB(255, 53, 154, 56),
          content: Text(
            message,
            style: TextStyle(color: Colors.white),
          )));
  }

  static void error(String message) {
    key.currentState!
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            message,
            style: TextStyle(color: Colors.white),
          )));
  }
}
