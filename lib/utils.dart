import 'dart:math';
import 'package:flutter/material.dart';
import 'policy/policy.dart';
import 'graph_painter/node_painter.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

String generateRandomString([len = 5]) {
  var r = Random();
  const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  return List.generate(len, (index) => chars[r.nextInt(chars.length)]).join();
}

bool isPointNearBezierPath(Offset point, Path path) {
  const step = 0.05;
  const threshold = 15;
  // approximate the Bezier curve with line segments
  final pathMetrics = path.computeMetrics();
  for (final pathMetric in pathMetrics) {
    for (double t = 0.0; t < 1.0; t += step) {
      var tangent = pathMetric.getTangentForOffset(pathMetric.length * t);
      if (tangent != null) {
        double distance = (tangent.position - point).distance;
        if (distance < threshold) {
          return true;
        }
      }
    }
  }
  return false;
}

T? firstOrNull<T>(List<T> list, bool Function(T element) predicate) {
  final elements = list.where(predicate);
  if (elements.isEmpty) {
    return null;
  } else {
    return elements.first;
  }
}

bool isNodeHit(Node node, Offset position, int nodePadding) {
  final nodeSize = NodePainter.calculateNodeSize(node, padding: nodePadding);

  return node.position.dx < position.dx &&
      node.position.dx + nodeSize.width > position.dx &&
      node.position.dy < position.dy &&
      node.position.dy + nodeSize.height > position.dy;
}

Offset adjustPositionForCanvasTransform(Offset position, Offset canvasPosition, double canvasScale) {
  Matrix4 inverseTransformation = Matrix4.identity()
    ..scale(canvasScale, canvasScale)
    ..translate(canvasPosition.dx, canvasPosition.dy)
    ..invert();

  vector.Vector3 transformedPositionVector = inverseTransformation.transform3(vector.Vector3(position.dx, position.dy, 0));
  return Offset(transformedPositionVector.x, transformedPositionVector.y);
}

// void createEdge(Node sourceNode, Node targetNode, EdgeType edgeType) {
//   try {
//     final newEdge = Edge(sourceNode, targetNode, edgeType);
//     final equivalentEdgeExists =
//         edges.any((edge) => edge.source == newEdge.source && edge.target == newEdge.target && edge.type == newEdge.type);
//     if (!equivalentEdgeExists) {
//       setState(() {
//         edges.add(newEdge);
//       });
//     }
//   } on ArgumentError catch (e) {
//     SnackbarGlobal.info(e.message);
//   }
// }

// void createNode(Offset position, NodeType nodeType, {String? nameOrDescriptor}) {
//   final tempPosition = Offset(0, 0);
//   final Node newNode = nodeType == NodeType.tag
//       ? TagNode(tempPosition, generateRandomString(), nameOrDescriptor)
//       : BoundaryNode.create(nodeType, tempPosition, nameOrDescriptor!);

//   final nodeSize = NodePainter.calculateNodeSize(newNode, padding: widget.preferences.nodePadding) * canvasScale;
//   newNode.position = Offset(position.dx - nodeSize.width / 2, position.dy - nodeSize.height / 2);

//   setState(() {
//     nodes.add(newNode);
//   });
// }
