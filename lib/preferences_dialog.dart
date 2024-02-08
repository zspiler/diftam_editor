import 'package:flutter/material.dart';
import 'user_preferences.dart';
import 'ui/number_input.dart';
import 'ui/color_picker.dart';

class PreferencesDialog extends StatefulWidget {
  final Function(Preferences newPreferences) onChange;

  const PreferencesDialog({super.key, required this.onChange});

  @override
  _PreferencesDialogState createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<PreferencesDialog> {
  int _strokeWidth = 0;
  Color _tagNodeColor = Colors.white;
  Color _entryNodeColor = Colors.white;
  Color _exitNodeColor = Colors.white;
  Color _obliviousEdgeColor = Colors.white;
  Color _awareEdgeColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await PreferencesManager.getPreferences();
    setState(() {
      _strokeWidth = preferences.strokeWidth;
      _tagNodeColor = preferences.tagNodeColor;
      _entryNodeColor = preferences.entryNodeColor;
      _exitNodeColor = preferences.exitNodeColor;
      _obliviousEdgeColor = preferences.obliviousEdgeColor;
      _awareEdgeColor = preferences.awareEdgeColor;
    });
  }

  void _updateStrokeWidth(int newValue) async {
    await PreferencesManager.setStrokeWidth(newValue);
    await _updatePreferences();
  }

  void _updateTagNodeColor(Color newColor) async {
    await PreferencesManager.setTagNodeColor(newColor);
    await _updatePreferences();
  }

  void _updateEntryNodeColor(Color newColor) async {
    await PreferencesManager.setEntryNodeColor(newColor);
    await _updatePreferences();
  }

  void _updateExitNodeColor(Color newColor) async {
    await PreferencesManager.setExitNodeColor(newColor);
    await _updatePreferences();
  }

  void _updateObliviousEdgeColor(Color newColor) async {
    await PreferencesManager.setObliviousEdgeColor(newColor);
    await _updatePreferences();
  }

  void _updateAwareEdgeColor(Color newColor) async {
    await PreferencesManager.setAwareEdgeColor(newColor);
    await _updatePreferences();
  }

  Future<void> _updatePreferences() async {
    await _loadPreferences();
    final updatedPreferences = await PreferencesManager.getPreferences();
    widget.onChange(updatedPreferences);
  }

  void _clearPreferences() async {
    await PreferencesManager.clear();
    await _loadPreferences();
    widget.onChange(Preferences());
  }

  @override
  Widget build(BuildContext context) {
    final nodeColorPreferencesRows = [
      ('Tag node', _tagNodeColor, _updateTagNodeColor),
      ('Entry node', _entryNodeColor, _updateEntryNodeColor),
      ('Exit node', _exitNodeColor, _updateExitNodeColor),
      ('Oblivious edge', _obliviousEdgeColor, _updateObliviousEdgeColor),
      ('Aware edge', _awareEdgeColor, _updateAwareEdgeColor),
    ];

    List<TableRow> buildColorPreferencesTableRows() {
      const tableSpacer = TableRow(children: [SizedBox(height: 8), SizedBox(height: 8)]);
      List<TableRow> rowsWithSpacers = nodeColorPreferencesRows.fold<List<TableRow>>([], (List<TableRow> accumulator, row) {
        final description = row.$1;
        final color = row.$2;
        final onChange = row.$3;

        accumulator.add(TableRow(children: [
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Text(description, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          ),
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: SizedBox(height: 40, width: 40, child: MyColorPicker(color: color, onChange: onChange)),
          ),
        ]));

        if (row != nodeColorPreferencesRows.last) {
          accumulator.add(tableSpacer);
        }

        return accumulator;
      });

      return rowsWithSpacers;
    }

    return Dialog(
      child: Container(
        width: 400,
        height: 1000,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
              SizedBox(height: 30),
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
                  SizedBox(height: 30),
                  Text('Colors', style: Theme.of(context).textTheme.titleLarge),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
                    child: Table(columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: IntrinsicColumnWidth(),
                    }, children: buildColorPreferencesTableRows()),
                  ),
                  SizedBox(height: 30),
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
