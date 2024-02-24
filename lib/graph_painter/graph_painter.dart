import 'package:flutter/material.dart';

import 'node_painter.dart';
import 'edge_painter.dart';
import 'grid_painter.dart';
import '../policy/policy.dart';
import '../preferences_manager.dart';
import '../canvas.dart';

class GraphPainter extends CustomPainter {
  late final List<Node> nodes;
  late final List<Edge> edges;
  late final GraphObject? selectedObject;
  late final NodePainter nodePainter;
  late final EdgePainter edgePainter;
  late final GridPainter gridPainter;
  final (Offset, Offset)? previewEdge;
  final Function(List<Path> edgePaths) emitEdgePaths;
  final CanvasState canvasState;
  final Preferences preferences;

  GraphPainter(List<Node> originalNodes, List<Edge> originalEdges, this.previewEdge, this.emitEdgePaths,
      GraphObject? originalSelectedObject, this.canvasState, this.preferences) {
    /*
    We clone 'nodes' and 'edges' to simplify calculation of graph diff which is required to optimize repaints (with 'shouldRepaint' method).
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
      canvasState: canvasState,
      preferences: preferences,
    );
    edgePainter = EdgePainter(
      canvasState: canvasState,
      preferences: preferences,
    );
    gridPainter = GridPainter(
      canvasState: canvasState,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    gridPainter.drawGrid(canvas, size);

    emitEdgePaths(drawEdges(canvas, edges));

    for (var node in nodes) {
      nodePainter.drawNode(canvas, node, isSelected: selectedObject == node);
    }

    if (previewEdge != null) {
      edgePainter.drawPreviewEdge(canvas, previewEdge!);
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
        previewEdge != oldDelegate.previewEdge ||
        selectedObject.toString() != oldDelegate.selectedObject.toString() ||
        canvasState.toString() != oldDelegate.canvasState.toString() ||
        oldDelegate.preferences != preferences;
  }
}
