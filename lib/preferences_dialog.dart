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
  int _nodeStrokeWidth = 0;
  int _edgeStrokeWidth = 0;
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
      _nodeStrokeWidth = preferences.nodeStrokeWidth;
      _edgeStrokeWidth = preferences.edgeStrokeWidth;
      _tagNodeColor = preferences.tagNodeColor;
      _entryNodeColor = preferences.entryNodeColor;
      _exitNodeColor = preferences.exitNodeColor;
      _obliviousEdgeColor = preferences.obliviousEdgeColor;
      _awareEdgeColor = preferences.awareEdgeColor;
    });
  }

  void _updateNodeStrokeWidth(int newValue) async {
    await PreferencesManager.setNodeStrokeWidth(newValue);
    await _updatePreferences();
  }

  void _updateEdgeStrokeWidth(int newValue) async {
    await PreferencesManager.setEdgeStrokeWidth(newValue);
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

    TableRow buildTableSpacer(double height) => TableRow(children: [SizedBox(height: height), SizedBox(height: height)]);

    List<TableRow> buildColorPreferencesTableRows() {
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
            child: Align(alignment: Alignment.center, child: MyColorPicker(color: color, onChange: onChange)),
          ),
        ]));

        if (row != nodeColorPreferencesRows.last) {
          accumulator.add(buildTableSpacer(10));
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
                  SizedBox(height: 16),
                  Table(columnWidths: const {
                    0: FixedColumnWidth(110),
                    1: FixedColumnWidth(110),
                  }, children: [
                    TableRow(children: [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text('Node', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Align(
                          alignment: Alignment.center,
                          child: NumberInput(
                            value: _nodeStrokeWidth,
                            onChange: _updateNodeStrokeWidth,
                            max: 10,
                            min: 1,
                          ),
                        ),
                      ),
                    ]),
                    buildTableSpacer(8),
                    TableRow(children: [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text('Edge', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Align(
                          alignment: Alignment.center,
                          child: NumberInput(
                            value: _edgeStrokeWidth,
                            onChange: _updateEdgeStrokeWidth,
                            max: 8,
                            min: 1,
                          ),
                        ),
                      ),
                    ])
                  ]),
                  SizedBox(height: 30),
                  Text('Colors', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 16),
                  Table(columnWidths: const {
                    0: FixedColumnWidth(110),
                    1: FixedColumnWidth(110),
                  }, children: buildColorPreferencesTableRows()),
                  SizedBox(height: 30),
                  TextButton(
                    child: Text("Reset"),
                    onPressed: _clearPreferences,
                  ),
                  SizedBox(height: 10),
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
