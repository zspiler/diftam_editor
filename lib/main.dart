import 'package:flutter/material.dart';
import 'graph.dart';
import 'snackbar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: CanvasView()),
      scaffoldMessengerKey: SnackbarGlobal.key,
    );
  }
}
