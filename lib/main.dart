import 'package:flutter/material.dart';

import 'app.dart';
import 'preferences_manager.dart';
import 'theme.dart';
import 'ui/snackbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // SharedPreferences requires Flutter engine bindings to be initialized!
  await PreferencesManager.init();

  runApp(MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: darkBlue),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: SnackbarGlobal.key,
      home: const App()));
}
