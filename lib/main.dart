import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'graph.dart';
import 'ui/snackbar.dart';

final scaleProvider = Provider<double>((ref) => 1.0);

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: CanvasView()),
      scaffoldMessengerKey: SnackbarGlobal.key,
    );
  }
}
