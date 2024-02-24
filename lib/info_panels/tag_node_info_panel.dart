import 'package:flutter/material.dart';
import '../policy/policy.dart';
import 'object_info_panel.dart';
import '../ui/custom_dialog.dart';

class TagNodeInfoPanel extends StatelessWidget {
  final TagNode node;
  final List<Node> nodes;
  final void Function(GraphObject object) deleteObject;
  final void Function(String?) editName;

  const TagNodeInfoPanel(
      {super.key, required this.node, required this.nodes, required this.deleteObject, required this.editName});

  @override
  Widget build(BuildContext context) {
    const rowPadding = EdgeInsets.symmetric(vertical: 8.0);
    return ObjectInfoPanel(children: [
      Text(
        'Tag node',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      SizedBox(height: 8.0),
      Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            children: [
              Padding(
                padding: rowPadding,
                child: Text('ID:'),
              ),
              Padding(
                padding: rowPadding,
                child: Text(node.id),
              ),
              Container() //
            ],
          ),
          TableRow(
            children: [
              Padding(
                padding: rowPadding,
                child: Text('Label:'),
              ),
              Padding(
                padding: rowPadding,
                child: Text(node.name ?? '/'),
              ),
              Tooltip(
                message: 'Edit label',
                child: Align(
                  alignment: Alignment.centerLeft, // Adjust alignment as needed
                  child: IconButton(
                    padding: EdgeInsets.zero, // Minimize padding
                    icon: Icon(Icons.edit, size: 16.0), // Adjust icon size as needed
                    onPressed: () {
                      CustomDialog.showInputDialog(
                        context,
                        title: 'Edit label',
                        hint: 'Enter new label',
                        acceptEmptyInput: true,
                        initialText: node.name,
                        onConfirm: (String inputText) {
                          // NOTE we could also edit 'node' here and emit generic onChange event (to rerender)
                          editName(inputText.isNotEmpty ? inputText : null);
                        },
                        isInputValid: (String inputText) =>
                            !nodes.any((node) => node != node && node is TagNode && node.name == inputText),
                        errorMessage: 'Please choose a unique tag label',
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      SizedBox(height: 16.0),
      Column(
        children: [
          SizedBox(width: 16.0),
          Tooltip(
              message: "Delete tag",
              child: IconButton(
                icon: Icon(Icons.delete_rounded, color: Colors.red),
                onPressed: () {
                  deleteObject(node);
                },
              )),
        ],
      ),
    ]);
  }
}
