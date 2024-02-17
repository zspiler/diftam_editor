import 'package:flutter/material.dart';
import 'dart:math';

import '../policy/policy.dart';
import '../grid.dart';
import '../user_preferences.dart';
import 'node_painter.dart';

enum EdgeShape {
  straight,
  curvedUp,
  curvedDown,
}

class EdgePainter {
  final Offset canvasPosition;
  final double canvasScale;
  final int strokeWidth;
  final Color obliviousEdgeColor;
  final Color awareEdgeColor;
  final int nodePadding;

  EdgePainter({required this.canvasPosition, required this.canvasScale, required Preferences preferences})
      : strokeWidth = preferences.edgeStrokeWidth,
        obliviousEdgeColor = preferences.obliviousEdgeColor,
        awareEdgeColor = preferences.awareEdgeColor,
        nodePadding = preferences.nodePadding;

  Paint getEdgePaintStyle(EdgeType edgeType, {bool isSelected = false}) {
    const selectedEdgeColor = Colors.white;
    final obliviousColor = isSelected ? selectedEdgeColor : obliviousEdgeColor;
    final awareColor = isSelected ? selectedEdgeColor : awareEdgeColor;
    final color = edgeType == EdgeType.oblivious ? obliviousColor : awareColor;

    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * canvasScale
      ..color = color;
  }

  void drawEdgeInProgress(Canvas canvas, (Offset, Offset) points) {
    var (sourcePoint, targetPoint) = points;
    sourcePoint = Offset((sourcePoint.dx + canvasPosition.dx) * canvasScale, (sourcePoint.dy + canvasPosition.dy) * canvasScale);
    targetPoint = Offset((targetPoint.dx + canvasPosition.dx) * canvasScale, (targetPoint.dy + canvasPosition.dy) * canvasScale);

    final paintStyleFaded = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * canvasScale
      ..color = Colors.grey.withOpacity(0.7);

    canvas.drawLine(sourcePoint, targetPoint, paintStyleFaded);
    drawArrowhead(canvas, targetPoint, sourcePoint, paintStyleFaded);
  }

  Path drawEdge(Canvas canvas, Edge edge, {shape = EdgeShape.straight, bool isSelected = false}) {
    List<Offset> intersectionPoints = calculateIntersectionPoints(edge.source, edge.target);

    Offset startPoint = intersectionPoints[0];
    Offset endPoint = intersectionPoints[1];

    final paintStyle = getEdgePaintStyle(edge.type, isSelected: isSelected);

    if (shape != EdgeShape.straight) {
      return drawCurvedEdge(canvas, startPoint, endPoint, shape, paintStyle);
    }

    final path = drawStraightLine(canvas, startPoint, endPoint, paintStyle);
    drawArrowhead(canvas, endPoint, startPoint, paintStyle);
    return path;
  }

  Path drawCurvedEdge(Canvas canvas, Offset start, Offset end, EdgeShape shape, Paint paintStyle) {
    const baseVerticalAlignmentThreshold = 70;
    const baseDisplacementValue = 50;
    final verticalAlignmentThreshold = baseVerticalAlignmentThreshold * canvasScale;
    final displacementValue = baseDisplacementValue * canvasScale;

    bool areNodesVerticallyAligned = (start.dx - end.dx).abs() < verticalAlignmentThreshold;

    Offset controlPoint;
    if (areNodesVerticallyAligned) {
      double horizontalDisplacement = shape == EdgeShape.curvedUp ? -displacementValue : displacementValue;
      controlPoint = Offset((start.dx + end.dx) / 2 + horizontalDisplacement, (start.dy + end.dy) / 2);
    } else {
      double verticalDisplacement = shape == EdgeShape.curvedUp ? displacementValue : -displacementValue;
      controlPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 + verticalDisplacement);
    }

    // draw bezier curve
    Path path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);
    canvas.drawPath(path, paintStyle);

    // draw  arrowhead
    Offset tangentDirection = Offset(end.dx - controlPoint.dx, end.dy - controlPoint.dy);
    drawArrowhead(canvas, end, end - tangentDirection, paintStyle);

    return path;
  }

  static Path drawStraightLine(Canvas canvas, Offset start, Offset end, Paint paintStyle) {
    final Path path = Path();
    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, end.dy);

    canvas.drawPath(path, paintStyle);
    return path;
  }

  // TODO: dynamic, avoid other edges
  Path drawLoop(Canvas canvas, Node node, EdgeType edgeType, {bool small = false, bool isSelected = false}) {
    final paintStyle = getEdgePaintStyle(edgeType, isSelected: isSelected);

    final loopWidth = 60.0 / (small ? 1.5 : 1) * canvasScale;
    final loopHeight = 70.0 / (small ? 1.5 : 1) * canvasScale;

    final nodeX = (snapToGrid(node.position.dx, gridSize) + canvasPosition.dx) * canvasScale;
    final nodeY = (snapToGrid(node.position.dy, gridSize) + canvasPosition.dy) * canvasScale;

    final nodeSize = NodePainter.calculateNodeSize(node, padding: nodePadding) * canvasScale;

    final boxTopCenterX = nodeX + nodeSize.width / 2;
    final boxTopCenterY = nodeY;

    final Offset boxTopCenter = Offset(boxTopCenterX, boxTopCenterY);

    // control points for the Bezier curve
    final Offset controlPoint1 = boxTopCenter.translate(loopWidth, -loopHeight);
    final Offset controlPoint2 = boxTopCenter.translate(-loopWidth, -loopHeight);

    // start and end points
    final Offset loopPoint = boxTopCenter.translate(0, -paintStyle.strokeWidth * 2);

    final Path path = Path();
    path.moveTo(loopPoint.dx, loopPoint.dy);
    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      loopPoint.dx,
      loopPoint.dy,
    );

    canvas.drawPath(path, paintStyle);

    final double angle = atan2(controlPoint2.dy - loopPoint.dy, controlPoint2.dx - loopPoint.dx) + pi / 2;
    drawArrowhead(canvas, loopPoint, Offset(loopPoint.dx + cos(angle), loopPoint.dy + sin(angle)), paintStyle, arrowLength: 15);

    return path;
  }

  List<Offset> calculateIntersectionPoints(Node node1, Node node2) {
    final x1 = (snapToGrid(node1.position.dx, gridSize) + canvasPosition.dx) * canvasScale;
    final y1 = (snapToGrid(node1.position.dy, gridSize) + canvasPosition.dy) * canvasScale;
    final x2 = (snapToGrid(node2.position.dx, gridSize) + canvasPosition.dx) * canvasScale;
    final y2 = (snapToGrid(node2.position.dy, gridSize) + canvasPosition.dy) * canvasScale;

    final node1Size = NodePainter.calculateNodeSize(node1, padding: nodePadding) * canvasScale;
    final node2Size = NodePainter.calculateNodeSize(node2, padding: nodePadding) * canvasScale;

    final node1Offset = Offset(x1 + node1Size.width / 2, y1 + node1Size.height / 2);
    final node2Offset = Offset(x2 + node2Size.width / 2, y2 + node2Size.height / 2);

    final node1Center = Offset(node1Offset.dx, node1Offset.dy);
    final node2Center = Offset(node2Offset.dx, node2Offset.dy);

    Offset intersect1 = intersectionPoint(node1Center, node2Center, node1Size.width, node1Size.height);
    Offset intersect2 = intersectionPoint(node2Center, node1Center, node2Size.width, node2Size.height);

    return [intersect1, intersect2];
  }

  static Offset intersectionPoint(Offset center1, Offset center2, double width, double height) {
    double dx = center2.dx - center1.dx;
    double dy = center2.dy - center1.dy;

    double absDx = dx.abs();
    double absDy = dy.abs();

    double scaleX = absDx > 0 ? (width / 2) / absDx : 1.0;
    double scaleY = absDy > 0 ? (height / 2) / absDy : 1.0;

    double scale = min(scaleX, scaleY);

    return Offset(center1.dx + dx * scale, center1.dy + dy * scale);
  }

  void drawArrowhead(Canvas canvas, Offset point, Offset direction, Paint paint, {double arrowLength = 20}) {
    double arrowAngle = pi / 6;

    double edgeAngle = atan2(direction.dy - point.dy, direction.dx - point.dx);

    Offset arrowPoint1 = Offset(
      point.dx + arrowLength * cos(edgeAngle + arrowAngle) * canvasScale,
      point.dy + arrowLength * sin(edgeAngle + arrowAngle) * canvasScale,
    );
    Offset arrowPoint2 = Offset(
      point.dx + arrowLength * cos(edgeAngle - arrowAngle) * canvasScale,
      point.dy + arrowLength * sin(edgeAngle - arrowAngle) * canvasScale,
    );

    canvas.drawLine(point, arrowPoint1, paint);
    canvas.drawLine(point, arrowPoint2, paint);
  }
}
