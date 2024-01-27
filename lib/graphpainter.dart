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
    drawGrid(canvas, size);

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

  void drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha(50)
      ..strokeWidth = 1;

    final (canvasWidth, canvasHeight) = (size.width, size.height);

    for (var i = 0; i < canvasWidth; i += gridSize) {
      canvas.drawLine(Offset(i * 1.0, 0), Offset(i * 1.0, canvasHeight), paint);
    }

    for (var i = 0; i < canvasHeight; i += gridSize) {
      canvas.drawLine(Offset(0, i * 1.0), Offset(canvasWidth, i * 1.0), paint);
    }
  }
}
