import 'package:flutter/material.dart';

import 'nodepainter.dart';
import 'edgepainter.dart';
import 'common.dart';

class GraphPainter extends CustomPainter {
  final List<Node> nodes;
  final Map<int, List<int>> edges;
  final (Offset, Offset)? newEdge; // TODO check existing type for this

  GraphPainter(this.nodes, this.edges, this.newEdge);

  @override
  void paint(Canvas canvas, Size size) {
    // NOTE widget rebuilt each time _CanvasViewState changes 😬
    for (var node in nodes) {
      NodePainter.drawNode(canvas, node, snapToGrid: true);
    }

    edges.forEach((fromNodeIndex, toNodeIndexes) {
      for (var toNodeIndex in toNodeIndexes) {
        EdgePainter.drawEdge(canvas, nodes[fromNodeIndex], nodes[toNodeIndex], snapToGrid: true);
      }
    });

    if (newEdge != null) {
      EdgePainter.drawEdgeInProgress(canvas, newEdge!);
      // TODO always use offset vs point
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true; // TODO optimize?
}
