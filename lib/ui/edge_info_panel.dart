import 'package:poc/common.dart';
import 'package:flutter/material.dart';

class EdgeInfoPanel extends StatelessWidget {
  final Edge edge;
  final void Function(GraphObject object) deleteObject;
  final void Function(EdgeType newEdgeType) changeEdgeType;

  const EdgeInfoPanel({super.key, required this.edge, required this.deleteObject, required this.changeEdgeType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withAlpha(75), borderRadius: BorderRadius.all(Radius.circular(20))),
      width: 400,
      height: 300, // TODO responsive / adjust to screen?
      child: Padding(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 64.0, vertical: 16.0), // Equal padding on all sides (16.0 pixels)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Edge',
              style: Theme.of(context).textTheme.headline5, // Larger title style
            ),
            SizedBox(height: 8.0), // Spacing below the title
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('From:'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('${edge.source}'),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('To:'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('${edge.target}'),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Type:'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('${edge.type.value}'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.0), // Additional spacing before the subtitleing below the subtitle
            Column(
              children: [
                SizedBox(width: 8.0),
                Tooltip(
                    message: "Change edge type",
                    child: IconButton(
                      icon: Icon(Icons.arrow_circle_right_outlined),
                      // color: edge.type == EdgeType.oblivious ? Colors.green : Colors.red),
                      onPressed: () {
                        final newEdgeType = edge.type == EdgeType.oblivious ? EdgeType.aware : EdgeType.oblivious;
                        changeEdgeType(newEdgeType);
                      },
                      // style: IconButton.styleFrom(backgroundColor: edge.type == EdgeType.oblivious ? Colors.white : null),
                    )),
                SizedBox(width: 16.0),
                Tooltip(
                    message: "Delete edge",
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        deleteObject(edge);
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
