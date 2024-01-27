import 'package:flutter/material.dart';

import 'nodepainter.dart';
import 'edgepainter.dart';
import 'common.dart';

class GraphPainter extends CustomPainter {
  final List<Node> nodes; // TODO set?
  final List<Edge> edges; // TODO set?
  final (Offset, Offset)? newEdge; // TODO check existing type for this?

  GraphPainter(this.nodes, this.edges, this.newEdge);

  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(canvas, size);
    drawEdges(canvas, edges);

    // NOTE widget rebuilt each time _CanvasViewState changes 😬
    for (var node in nodes) {
      NodePainter.drawNode(canvas, node, snapToGrid: true);
    }

    if (newEdge != null) {
      // TODO always use offset vs point
      EdgePainter.drawEdgeInProgress(canvas, newEdge!);
    }
  }

  void drawEdges(Canvas canvas, List<Edge> edges) {
    for (Edge edge1 in edges) {
      final (fromNode, toNode) = (edge1.source, edge1.target);
      if (fromNode == toNode) {
        final loopEdgesOnNode = edges.where((edge2) => edge2.source == fromNode && edge2.target == fromNode);
        if (loopEdgesOnNode.length == 2) {
          EdgePainter.drawLoop(canvas, fromNode, EdgeType.aware, snapToGrid: true);
          EdgePainter.drawLoop(canvas, fromNode, EdgeType.oblivious, small: true, snapToGrid: true);
        } else {
          EdgePainter.drawLoop(canvas, fromNode, edge1.type, snapToGrid: true);
        }
      } else {
        var areEdgesOfDifferentTypesBetweenSameNodes = edges.any((edge2) =>
            edge1 != edge2 &&
            edge1.type != edge2.type &&
            ((edge1.source == edge2.source && edge1.target == edge2.target) ||
                (edge1.source == edge2.target && edge1.target == edge2.source)));

        final edgeShape = areEdgesOfDifferentTypesBetweenSameNodes
            ? (edge1.type == EdgeType.oblivious ? EdgeShape.curvedUp : EdgeShape.curvedDown)
            : EdgeShape.straight;

        EdgePainter.drawEdge(canvas, edge1, shape: edgeShape, snapToGrid: true);
      }
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
