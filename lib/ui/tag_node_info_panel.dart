import 'package:poc/common.dart';
import 'package:flutter/material.dart';

class TagNodeInfoPanel extends StatelessWidget {
  final TagNode node;
  final void Function(GraphObject object) deleteObject;
  final void Function() editLabel;

  const TagNodeInfoPanel({super.key, required this.node, required this.deleteObject, required this.editLabel});

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
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('ID:'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('${node.id}'),
                    ),
                    Container() //
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Label:'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('${node.name ?? '/'}'),
                    ),
                    Tooltip(
                      message: 'Edit label',
                      child: Align(
                        alignment: Alignment.centerLeft, // Adjust alignment as needed
                        child: IconButton(
                          padding: EdgeInsets.zero, // Minimize padding
                          icon: Icon(Icons.edit, size: 16.0), // Adjust icon size as needed
                          onPressed: editLabel,
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
