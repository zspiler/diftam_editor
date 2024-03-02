import 'package:flutter/material.dart';
import '../preferences_manager.dart';
import '../ui/number_input.dart';
import '../ui/color_picker.dart';

class PreferencesDialog extends StatefulWidget {
  final Function(Preferences newPreferences) onChange;

  const PreferencesDialog({super.key, required this.onChange});

  @override
  State<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<PreferencesDialog> {
  int _nodePadding = 0;
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

  void _loadPreferences() async {
    final preferences = PreferencesManager.getPreferences();
    setState(() {
      _nodePadding = preferences.nodePadding;
      _nodeStrokeWidth = preferences.nodeStrokeWidth;
      _edgeStrokeWidth = preferences.edgeStrokeWidth;
      _tagNodeColor = preferences.tagNodeColor;
      _entryNodeColor = preferences.entryNodeColor;
      _exitNodeColor = preferences.exitNodeColor;
      _obliviousEdgeColor = preferences.obliviousEdgeColor;
      _awareEdgeColor = preferences.awareEdgeColor;
    });
  }

  void setPreference<T>(Function(T) setter, T newValue) {
    setter(newValue);
    _updatePreferences();
  }

  void _updatePreferences() {
    _loadPreferences();
    widget.onChange(PreferencesManager.getPreferences());
  }

  void _clearPreferences() async {
    PreferencesManager.clear();
    _loadPreferences();
    widget.onChange(Preferences());
  }

  @override
  Widget build(BuildContext context) {
    final nodeColorPreferencesRows = [
      ('Tag node', _tagNodeColor, (Color newColor) => setPreference(PreferencesManager.setTagNodeColor, newColor)),
      ('Entry node', _entryNodeColor, (Color newColor) => setPreference(PreferencesManager.setEntryNodeColor, newColor)),
      ('Exit node', _exitNodeColor, (Color newColor) => setPreference(PreferencesManager.setExitNodeColor, newColor)),
      (
        'Oblivious edge',
        _obliviousEdgeColor,
        (Color newColor) => setPreference(PreferencesManager.setObliviousEdgeColor, newColor)
      ),
      ('Aware edge', _awareEdgeColor, (Color newColor) => setPreference(PreferencesManager.setAwareEdgeColor, newColor)),
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
      child: SizedBox(
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
                  Text('Sizing', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 16),
                  Table(columnWidths: const {
                    0: FixedColumnWidth(150),
                    1: FixedColumnWidth(150),
                  }, children: [
                    TableRow(children: [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text('Node padding', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Align(
                          alignment: Alignment.center,
                          child: NumberInput(
                            value: _nodePadding,
                            onChange: (newPadding) => setPreference(PreferencesManager.setNodePadding, newPadding),
                            max: 5,
                            min: 1,
                          ),
                        ),
                      ),
                    ]),
                    buildTableSpacer(6),
                    TableRow(children: [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text('Node stroke width',
                            style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Align(
                          alignment: Alignment.center,
                          child: NumberInput(
                            value: _nodeStrokeWidth,
                            onChange: (newStrokeWidth) => setPreference(PreferencesManager.setNodeStrokeWidth, newStrokeWidth),
                            max: 10,
                            min: 1,
                          ),
                        ),
                      ),
                    ]),
                    buildTableSpacer(6),
                    TableRow(children: [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text('Edge stroke width',
                            style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Align(
                          alignment: Alignment.center,
                          child: NumberInput(
                            value: _edgeStrokeWidth,
                            onChange: (newStrokeWidth) => setPreference(PreferencesManager.setEdgeStrokeWidth, newStrokeWidth),
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
                    onPressed: _clearPreferences,
                    child: Text("Reset"),
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
