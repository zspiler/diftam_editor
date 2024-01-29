import 'package:flutter/material.dart';

import 'nodepainter.dart';
import 'edgepainter.dart';
import 'common.dart';

class GraphPainter extends CustomPainter {
  final List<Node> nodes; // TODO set?
  final List<Edge> edges; // TODO set?
  final (Offset, Offset)? newEdge; // TODO check existing type for this?
  final Function(Map<Edge, Path> pathPerEdge) emitPathPerEdge;
  final GraphObject? selectedObject;

  GraphPainter(this.nodes, this.edges, this.newEdge, this.emitPathPerEdge, this.selectedObject);

  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(canvas, size);
    final pathPerEdge = drawEdges(canvas, edges);
    emitPathPerEdge(pathPerEdge);

    // NOTE widget rebuilt each time _CanvasViewState changes 😬
    for (var node in nodes) {
      NodePainter.drawNode(canvas, node, snapToGrid: true, isSelected: selectedObject == node);
    }

    if (newEdge != null) {
      // TODO always use offset vs point
      EdgePainter.drawEdgeInProgress(canvas, newEdge!);
    }
  }

  /*
    Draws edges and also returns map which contains the drawn path for each edge.
    Because edges can be curved, we need the paths to detect whether an edgeis under cursor (for selection).
   */
  Map<Edge, Path> drawEdges(Canvas canvas, List<Edge> edges) {
    final Map<Edge, Path> pathPerEdge = {};

    for (Edge edge1 in edges) {
      final (fromNode, toNode) = (edge1.source, edge1.target);
      if (fromNode == toNode) {
        final loopEdgesOnNode = edges.where((edge2) => edge2.source == fromNode && edge2.target == fromNode).toList();
        if (loopEdgesOnNode.length == 2) {
          final loop1Path = EdgePainter.drawLoop(canvas, fromNode, EdgeType.aware,
              isSelected: loopEdgesOnNode[0] == selectedObject, snapToGrid: true);
          final loop2Path = EdgePainter.drawLoop(canvas, fromNode, EdgeType.oblivious,
              small: true, isSelected: loopEdgesOnNode[1] == selectedObject, snapToGrid: true);
          pathPerEdge[loopEdgesOnNode[0]] = loop1Path;
          pathPerEdge[loopEdgesOnNode[1]] = loop2Path;
        } else {
          final loopPath =
              EdgePainter.drawLoop(canvas, fromNode, edge1.type, isSelected: edge1 == selectedObject, snapToGrid: true);
          pathPerEdge[edge1] = loopPath;
        }
        // TODO loops!
      } else {
        var areEdgesOfDifferentTypesBetweenSameNodes = edges.any((edge2) =>
            edge1 != edge2 &&
            edge1.type != edge2.type &&
            ((edge1.source == edge2.source && edge1.target == edge2.target) ||
                (edge1.source == edge2.target && edge1.target == edge2.source)));

        final edgeShape = areEdgesOfDifferentTypesBetweenSameNodes
            ? (edge1.type == EdgeType.oblivious ? EdgeShape.curvedUp : EdgeShape.curvedDown)
            : EdgeShape.straight;

        pathPerEdge[edge1] = EdgePainter.drawEdge(canvas, edge1,
            shape: edgeShape, snapToGrid: true, isSelected: edge1 == selectedObject);
      }
    }
    return pathPerEdge;
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
