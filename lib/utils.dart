import 'dart:math';
import 'package:flutter/material.dart';
import 'policy/policy.dart';
import 'graph_painter/node_painter.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../canvas.dart';

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

Offset mapScreenPositionToCanvas(Offset position, CanvasTransform canvasTransform) {
  Matrix4 inverseTransformation = Matrix4.identity()
    ..scale(canvasTransform.scale, canvasTransform.scale)
    ..translate(canvasTransform.offset.dx, canvasTransform.offset.dy)
    ..invert();

  final positionVector = vector.Vector3(position.dx, position.dy, 0);
  final transformedPositionVector = inverseTransformation.transform3(positionVector);
  return Offset(transformedPositionVector.x, transformedPositionVector.y);
}
