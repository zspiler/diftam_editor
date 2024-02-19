import 'package:flutter/material.dart';

import 'node_painter.dart';
import 'edge_painter.dart';
import '../policy/policy.dart';
import '../grid.dart';
import '../preferences_manager.dart';

class GraphPainter extends CustomPainter {
  late final List<Node> nodes;
  late final List<Edge> edges;
  late final GraphObject? selectedObject;
  late final NodePainter nodePainter;
  late final EdgePainter edgePainter;
  final (Offset, Offset)? newEdge;
  final Function(List<Path> edgePaths) emitEdgePaths;
  final Offset canvasPosition;
  final double canvasScale;

  GraphPainter(List<Node> originalNodes, List<Edge> originalEdges, this.newEdge, this.emitEdgePaths,
      GraphObject? originalSelectedObject, this.canvasPosition, this.canvasScale, Preferences preferences) {
    /*
    We clone 'nodes' and 'edges' to simplify calculation of graph diff which is required to optimize repaints with ('shouldRepaint' method).
    Without cloning, diff is not detected since we modify graph object properties without replacing objects themselves and
    oldDelegate holds object references which do not change unless objects are added/removed.
    An alternative would be to always replace graph objects when modifying them (TODO).
    */
    nodes = GraphObject.cloneObjects(originalNodes);
    edges = GraphObject.cloneObjects(originalEdges);

    if (originalSelectedObject != null) {
      if (originalSelectedObject is Node) {
        selectedObject = nodes[originalNodes.indexOf(originalSelectedObject)];
      } else {
        selectedObject = edges[originalEdges.indexOf(originalSelectedObject as Edge)];
      }
    } else {
      selectedObject = null;
    }

    nodePainter = NodePainter(
      canvasPosition: canvasPosition,
      canvasScale: canvasScale,
      preferences: preferences,
    );
    edgePainter = EdgePainter(
      canvasPosition: canvasPosition,
      canvasScale: canvasScale,
      preferences: preferences,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(canvas, size);
    final edgePaths = drawEdges(canvas, edges);
    emitEdgePaths(edgePaths);

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
  List<Path> drawEdges(Canvas canvas, List<Edge> edges) {
    final List<Path> edgePaths = List.generate(edges.length, (_) => Path());

    final loopEdges = edges.where((edge) => edge.source == edge.target).toList();
    final nonLoopEdges = edges.where((edge) => edge.source != edge.target).toList();

    for (Edge edge in loopEdges) {
      final sourceNode = edge.source;
      final loopEdges = edges.where((edge2) => edge2.source == sourceNode && edge2.target == sourceNode).toList();
      if (loopEdges.length == 2) {
        final firstLoopEdgeIndex = edges.indexOf(loopEdges[0]);
        edgePaths[firstLoopEdgeIndex] =
            edgePainter.drawLoop(canvas, sourceNode, EdgeType.aware, isSelected: loopEdges[0] == selectedObject);

        final secondLoopEdgeIndex = edges.indexOf(loopEdges[1]);
        edgePaths[secondLoopEdgeIndex] =
            edgePainter.drawLoop(canvas, sourceNode, EdgeType.oblivious, small: true, isSelected: loopEdges[1] == selectedObject);
      } else {
        final edgeIndex = edges.indexOf(edge);
        edgePaths[edgeIndex] = edgePainter.drawLoop(canvas, sourceNode, edge.type, isSelected: edge == selectedObject);
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

      final siblingEdge = getSiblingEdge(edges, edge);

      final edgeIndex = edges.indexOf(edge);
      edgePaths[edgeIndex] = edgePainter.drawEdge(canvas, edge,
          shape: edgeShape, isSelected: edge == selectedObject || (siblingEdge != null && siblingEdge == selectedObject));
    }

    return edgePaths;
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) {
    return nodes.toString() != oldDelegate.nodes.toString() ||
        edges.toString() != oldDelegate.edges.toString() ||
        newEdge != oldDelegate.newEdge ||
        selectedObject.toString() != oldDelegate.selectedObject.toString() ||
        canvasPosition != oldDelegate.canvasPosition ||
        canvasScale != oldDelegate.canvasScale;
  }

  void drawGrid(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha(50)
      ..strokeWidth = canvasScale;

    final scaledGridSize = gridSize * canvasScale;

    final startX = ((canvasPosition.dx * canvasScale) % scaledGridSize) - scaledGridSize;
    final startY = ((canvasPosition.dy * canvasScale) % scaledGridSize) - scaledGridSize;

    final numberOfHorizontalLines = (canvasSize.width / scaledGridSize).ceil() + 1;
    final numberOfVerticalLines = (canvasSize.height / scaledGridSize).ceil() + 1;

    for (var i = 0; i < numberOfHorizontalLines; i++) {
      final x = startX + i * scaledGridSize;
      canvas.drawLine(Offset(x, 0), Offset(x, canvasSize.height), paint);
    }

    for (var i = 0; i < numberOfVerticalLines; i++) {
      final y = startY + i * scaledGridSize;
      canvas.drawLine(Offset(0, y), Offset(canvasSize.width, y), paint);
    }
  }
}
