import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../../canvas.dart';

Offset transformScreenToCanvasPosition(Offset position, CanvasTransform canvasTransform) {
  Matrix4 inverseTransformation = Matrix4.identity()
    ..scale(canvasTransform.scale, canvasTransform.scale)
    ..translate(canvasTransform.offset.dx, canvasTransform.offset.dy)
    ..invert();

  final positionVector = vector.Vector3(position.dx, position.dy, 0);
  final transformedPositionVector = inverseTransformation.transform3(positionVector);
  return Offset(transformedPositionVector.x, transformedPositionVector.y);
}
