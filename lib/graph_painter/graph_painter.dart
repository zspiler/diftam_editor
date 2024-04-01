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
      tagNodeColor: preferences.tagNodeColor,
      entryNodeColor: preferences.entryNodeColor,
      exitNodeColor: preferences.exitNodeColor,
      strokeWidth: preferences.nodeStrokeWidth,
      nodePadding: preferences.nodePadding,
    );

    edgePainter = EdgePainter(
      canvasState: canvasState,
      obliviousEdgeColor: preferences.obliviousEdgeColor,
      awareEdgeColor: preferences.awareEdgeColor,
      boundaryEdgeColor: preferences.boundaryEdgeColor,
      strokeWidth: preferences.edgeStrokeWidth,
      nodePadding: preferences.nodePadding,
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
    final pathPerRegularEdge = drawRegularEdges(canvas, edges);
    final pathPerLoopEdge = drawLoopEdges(canvas, edges);

    return edges.map((edge) => pathPerRegularEdge[edge] ?? pathPerLoopEdge[edge] ?? Path()).toList();
  }

  Map<Edge, Path> drawRegularEdges(Canvas canvas, List<Edge> edges) {
    final Map<Edge, Path> edgePaths = {};

    final regularEdges = edges.where((edge) => edge.source != edge.target).toList();

    for (Edge edge in regularEdges) {
      final edgeShape = edge.type != EdgeType.boundary && anyEdgeOfDifferentTypeBetweenSameNodes(edges, edge)
          ? (edge.type == EdgeType.oblivious ? EdgeShape.curvedUp : EdgeShape.curvedDown)
          : EdgeShape.straight;

      final siblingEdge = getSiblingEdge(edges, edge);
      edgePaths[edge] = edgePainter.drawEdge(canvas, edge,
          shape: edgeShape, isSelected: edge == selectedObject || (siblingEdge != null && siblingEdge == selectedObject));
    }

    return edgePaths;
  }

  Map<Edge, Path> drawLoopEdges(Canvas canvas, List<Edge> edges) {
    final Map<Edge, Path> edgePaths = {};

    getLoopEdgesByNode(edges).forEach((sourceNode, loopEdges) {
      if (loopEdges.length == 1) {
        edgePaths[loopEdges.first] =
            edgePainter.drawLoop(canvas, sourceNode, loopEdges.first.type, isSelected: loopEdges.first == selectedObject);
      } else {
        for (final edge in loopEdges) {
          edgePaths[edge] = edgePainter.drawLoop(canvas, sourceNode, edge.type,
              isSelected: edge == selectedObject, small: loopEdges.indexOf(edge) > 0);
        }
      }
    });

    return edgePaths;
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) {
    return nodes.toString() != oldDelegate.nodes.toString() ||
        edges.toString() != oldDelegate.edges.toString() ||
        selectedObject.toString() != oldDelegate.selectedObject.toString() ||
        canvasState.toString() != oldDelegate.canvasState.toString() ||
        previewEdge != oldDelegate.previewEdge ||
        oldDelegate.preferences != preferences;
  }
}
