import 'package:poc/common.dart';
import 'package:flutter/material.dart';

class BoundaryNodeInfoPanel extends StatelessWidget {
  final BoundaryNode node;
  final void Function(GraphObject object) deleteObject;
  final void Function() editDescriptor;

  const BoundaryNodeInfoPanel({super.key, required this.node, required this.deleteObject, required this.editDescriptor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withAlpha(75), borderRadius: BorderRadius.all(Radius.circular(20))),
      width: 400,
      height: 260, // TODO responsive / adjust to screen?
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 64.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Descriptor:'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('${node.descriptor}'),
                    ),
                    Tooltip(
                      message: 'Edit descriptor',
                      child: Align(
                        alignment: Alignment.centerLeft, // Adjust alignment as needed
                        child: IconButton(
                          padding: EdgeInsets.zero, // Minimize padding
                          icon: Icon(Icons.edit, size: 16.0), // Adjust icon size as needed
                          onPressed: editDescriptor,
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
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        deleteObject(node);
                      },
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
