import 'package:flutter/material.dart';
import 'package:D2SC_editor/d2sc_policy/lib/d2sc_policy.dart';
import 'object_info_panel.dart';
import '../ui/custom_dialog.dart';

class BoundaryNodeInfoPanel extends StatelessWidget {
  final BoundaryNode node;
  final List<Node> nodes;
  final void Function(GraphObject object) deleteObject;
  final void Function(String) editDescriptor;

  const BoundaryNodeInfoPanel(
      {super.key, required this.node, required this.nodes, required this.deleteObject, required this.editDescriptor});

  @override
  Widget build(BuildContext context) {
    const rowPadding = EdgeInsets.symmetric(vertical: 8.0);
    return ObjectInfoPanel(children: [
      Text(
        '${node is ExitNode ? 'Exit' : 'Entry'} node',
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
                child: Text('Descriptor:'),
              ),
              Padding(
                padding: rowPadding,
                child: Text(node.descriptor),
              ),
              Tooltip(
                message: 'Edit descriptor',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.edit, size: 16.0),
                    onPressed: () {
                      CustomDialog.showInputDialog(context,
                          title: 'Edit descriptor',
                          hint: 'Enter new descriptor',
                          initialText: node.descriptor,
                          onConfirm: (String inputText) {
                            editDescriptor(inputText);
                          },
                          isInputValid: (String inputText) =>
                              inputText.isNotEmpty && node is EntryNode && !entryNodeWithDescriptorExists(nodes, inputText) ||
                              node is ExitNode && !exitNodeWithDescriptorExists(nodes, inputText),
                          errorMessage: '${node is EntryNode ? 'Entry' : 'Exit'} node with this descriptor already exists!');
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
              message: "Delete node",
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
