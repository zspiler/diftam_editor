import 'package:flutter/material.dart';

import 'node_painter.dart';
import 'edge_painter.dart';
import '../common.dart';
import '../user_preferences.dart';

class GraphPainter extends CustomPainter {
  final List<Node> nodes;
  final List<Edge> edges;
  final (Offset, Offset)? newEdge;
  final Function(Map<Edge, Path> pathPerEdge) emitPathPerEdge;
  final GraphObject? selectedObject;
  final Preferences preferences;
  final NodePainter nodePainter;
  final EdgePainter edgePainter;

  GraphPainter(this.nodes, this.edges, this.newEdge, this.emitPathPerEdge, this.selectedObject, this.preferences)
      : nodePainter = NodePainter(
            strokeWidth: preferences.nodeStrokeWidth,
            tagNodeColor: preferences.tagNodeColor,
            entryNodeColor: preferences.entryNodeColor,
            exitNodeColor: preferences.exitNodeColor),
        edgePainter = EdgePainter(
            strokeWidth: preferences.edgeStrokeWidth,
            obliviousEdgeColor: preferences.obliviousEdgeColor,
            awareEdgeColor: preferences.awareEdgeColor);

  // NOTE widget rebuilt each time _CanvasViewState changes 😬
  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(canvas, size);
    final pathPerEdge = drawEdges(canvas, edges);
    emitPathPerEdge(pathPerEdge);

    for (var node in nodes) {
      nodePainter.drawNode(canvas, node, isSelected: selectedObject == node);
    }

    if (newEdge != null) {
      edgePainter.drawEdgeInProgress(canvas, newEdge!);
    }
  }

  /*
    Draws edges and also returns map which contains the drawn path for each edge.
    Because edges can be curved, we need the paths to detect whether an edge is under cursor (for selection).
   */
  Map<Edge, Path> drawEdges(Canvas canvas, List<Edge> edges) {
    final Map<Edge, Path> pathPerEdge = {};

    final loopEdges = edges.where((edge) => edge.source == edge.target).toList();
    final nonLoopEdges = edges.where((edge) => edge.source != edge.target).toList();

    for (Edge edge in loopEdges) {
      final sourceNode = edge.source;
      final loopEdgesOnNode = edges.where((edge2) => edge2.source == sourceNode && edge2.target == sourceNode).toList();
      if (loopEdgesOnNode.length == 2) {
        pathPerEdge[loopEdgesOnNode[0]] =
            edgePainter.drawLoop(canvas, sourceNode, EdgeType.aware, isSelected: loopEdgesOnNode[0] == selectedObject);
        pathPerEdge[loopEdgesOnNode[1]] = edgePainter.drawLoop(canvas, sourceNode, EdgeType.oblivious,
            small: true, isSelected: loopEdgesOnNode[1] == selectedObject);
      } else {
        pathPerEdge[edge] = edgePainter.drawLoop(canvas, sourceNode, edge.type, isSelected: edge == selectedObject);
      }
    }

    for (Edge edge in nonLoopEdges) {
      var areEdgesOfDifferentTypesBetweenSameNodes = edges.any((otherEdge) =>
          edge != otherEdge &&
          edge.type != otherEdge.type &&
          ((edge.source == otherEdge.source && edge.target == otherEdge.target) ||
              (edge.source == otherEdge.target && edge.target == otherEdge.source)));

      final edgeShape = areEdgesOfDifferentTypesBetweenSameNodes
          ? (edge.type == EdgeType.oblivious ? EdgeShape.curvedUp : EdgeShape.curvedDown)
          : EdgeShape.straight;

      pathPerEdge[edge] = edgePainter.drawEdge(canvas, edge, shape: edgeShape, isSelected: edge == selectedObject);
    }

    return pathPerEdge;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true; // TODO optimize?

  void drawGrid(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha(50)
      ..strokeWidth = 1;

    for (var i = 0; i < canvasSize.width; i += gridSize) {
      canvas.drawLine(Offset(i * 1.0, 0), Offset(i * 1.0, canvasSize.height), paint);
    }

    for (var i = 0; i < canvasSize.height; i += gridSize) {
      canvas.drawLine(Offset(0, i * 1.0), Offset(canvasSize.width, i * 1.0), paint);
    }
  }
}
