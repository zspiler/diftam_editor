import 'package:flutter/material.dart';

class KeyboardShortcutsDialog extends StatelessWidget {
  const KeyboardShortcutsDialog({super.key});

  static const iconSize = 20.0;
  static const shortcuts = [
    ShortcutInfo(description: 'Deselect', icons: [Text('Esc')]),
    ShortcutInfo(description: 'Delete', icons: [Text('Delete'), Icon(Icons.backspace, size: iconSize)]),
    ShortcutInfo(description: 'Zoom in', icons: [Icon(Icons.add, size: iconSize)], meta: true),
    ShortcutInfo(description: 'Zoom out', icons: [Icon(Icons.remove, size: iconSize)], meta: true),
    ShortcutInfo(description: 'Reset zoom', icons: [Icon(Icons.exposure_zero, size: iconSize)], meta: true),
    ShortcutInfo(
        description: 'Move nodes',
        icons: [
          Icon(Icons.keyboard_arrow_up, size: iconSize),
          Icon(Icons.keyboard_arrow_down, size: iconSize),
          Icon(Icons.keyboard_arrow_left, size: iconSize),
          Icon(Icons.keyboard_arrow_right, size: iconSize)
        ],
        meta: true),
  ];

  TableRow buildTableSpacer(double height) => TableRow(children: [
        SizedBox(height: height),
        SizedBox(height: height),
      ]);

  List<TableRow> buildShortcutTableRows(BuildContext context) {
    List<TableRow> rowsWithSpacers = shortcuts.fold<List<TableRow>>([], (List<TableRow> accumulator, shortcut) {
      final description = shortcut.description;
      final meta = shortcut.meta ?? false;
      final icons = shortcut.icons;

      final row = TableRow(children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Text(description, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.left),
        ),
        TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Align(
              alignment: Alignment.center,
              child: Row(
                children: [
                  if (meta) ...[
                    KeyIcon(child: Icon(Icons.keyboard_command_key, size: iconSize)),
                    Text(' + ', style: TextStyle(fontSize: 20))
                  ],
                  for (var i = 0; i < icons.length; i++) ...[
                    KeyIcon(child: icons[i]),
                    if (i < icons.length - 1) Text(' / ', style: TextStyle(fontSize: 20)),
                  ],
                ],
              ),
            )),
      ]);

      accumulator.add(row);

      if (shortcut != shortcuts.last) {
        accumulator.add(buildTableSpacer(10));
      }

      return accumulator;
    });

    return rowsWithSpacers;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 500,
        height: 450,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Keyboard shortcuts', style: Theme.of(context).textTheme.headlineLarge),
              SizedBox(height: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    SizedBox(
                      width: 350,
                      child: Table(children: buildShortcutTableRows(context), columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: IntrinsicColumnWidth(),
                      }),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                child: Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShortcutInfo {
  final String description;
  final List<Widget> icons;
  final bool? meta;

  const ShortcutInfo({
    required this.description,
    required this.icons,
    this.meta,
  });
}

class KeyIcon extends StatelessWidget {
  final Widget child;

  const KeyIcon({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Color.fromARGB(255, 25, 24, 36), borderRadius: BorderRadius.all(Radius.circular(4))),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Center(child: child),
      ),
    );
  }
}