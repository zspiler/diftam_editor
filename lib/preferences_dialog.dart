import 'package:flutter/material.dart';
import 'user_preferences.dart';
import 'ui/number_input.dart';

class PreferencesDialog extends StatefulWidget {
  final Function(Preferences newPreferences) onChange;

  const PreferencesDialog({super.key, required this.onChange});

  @override
  _PreferencesDialogState createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<PreferencesDialog> {
  int _strokeWidth = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final strokeWidth = await PreferencesManager.getStrokeWidth();
    setState(() {
      _strokeWidth = strokeWidth;
    });
  }

  void _updateStrokeWidth(int newValue) async {
    await PreferencesManager.setStrokeWidth(newValue);
    await _loadPreferences();
    final updatedPreferences = Preferences(strokeWidth: _strokeWidth);
    widget.onChange(updatedPreferences);
  }

  void _clearPreferences() async {
    await PreferencesManager.clear();
    await _loadPreferences();
    widget.onChange(Preferences());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 300,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
              SizedBox(
                height: 30,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Stroke width', style: Theme.of(context).textTheme.titleLarge),
                  NumberInput(
                    value: _strokeWidth,
                    onChange: _updateStrokeWidth,
                    max: 10,
                    min: 1,
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  TextButton(
                    child: Text("Reset"),
                    onPressed: _clearPreferences,
                  ),
                  TextButton(
                    child: Text("Close"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
