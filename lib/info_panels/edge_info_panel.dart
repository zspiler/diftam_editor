import 'package:flutter/material.dart';
import '../policy/policy.dart';
import 'object_info_panel.dart';

class EdgeInfoPanel extends StatelessWidget {
  final Edge edge;
  final void Function(GraphObject object) deleteObject;
  final void Function(EdgeType newEdgeType) changeEdgeType;

  const EdgeInfoPanel({super.key, required this.edge, required this.deleteObject, required this.changeEdgeType});

  @override
  Widget build(BuildContext context) {
    const rowPadding = EdgeInsets.symmetric(vertical: 8.0);
    return ObjectInfoPanel(children: [
      Text(
        'Edge',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      SizedBox(height: 8.0),
      Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(2),
        },
        children: [
          TableRow(
            children: [
              Padding(
                padding: rowPadding,
                child: Text('From:'),
              ),
              Padding(
                padding: rowPadding,
                child: Text('${edge.source}'),
              ),
            ],
          ),
          TableRow(
            children: [
              Padding(
                padding: rowPadding,
                child: Text('To:'),
              ),
              Padding(
                padding: rowPadding,
                child: Text('${edge.target}'),
              ),
            ],
          ),
          TableRow(
            children: [
              Padding(
                padding: rowPadding,
                child: Text('Type:'),
              ),
              Padding(
                padding: rowPadding,
                child: Text('${edge.type.value}'),
              ),
            ],
          ),
        ],
      ),
      SizedBox(height: 16.0),
      Column(
        children: [
          SizedBox(width: 8.0),
          Tooltip(
              message: "Change edge type",
              child: IconButton(
                icon: Icon(Icons.arrow_circle_right_outlined),
                onPressed: () {
                  final newEdgeType = edge.type == EdgeType.oblivious ? EdgeType.aware : EdgeType.oblivious;
                  changeEdgeType(newEdgeType);
                },
              )),
          SizedBox(width: 16.0),
          Tooltip(
              message: "Delete edge",
              child: IconButton(
                icon: Icon(Icons.delete_rounded, color: Colors.red),
                onPressed: () {
                  deleteObject(edge);
                },
              )),
        ],
      ),
    ]);
  }
}
