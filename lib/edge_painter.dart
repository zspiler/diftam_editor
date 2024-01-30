import 'package:flutter/material.dart';
import 'dart:math';

import 'node_painter.dart';
import 'common.dart';

enum EdgeShape {
  straight,
  curvedUp,
  curvedDown,
}

class EdgePainter {
  static const strokeWidth = 4.0;

  static Paint getEdgePaintStyle(EdgeType edgeType, {bool isSelected = false}) {
    final color = isSelected
        ? Colors.white.withAlpha(222)
        : (edgeType == EdgeType.aware ? Colors.green.withAlpha(200) : Colors.red.withAlpha(200));
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
  }

  static void drawEdgeInProgress(Canvas canvas, (Offset, Offset) points) {
    final paintStyleFaded = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.lime.withOpacity(0.7);

    final (sourcePoint, targetPoint) = points;
    canvas.drawLine(sourcePoint, targetPoint, paintStyleFaded);
    drawArrowhead(canvas, targetPoint, sourcePoint, paintStyleFaded);
  }

  static Path drawEdge(Canvas canvas, Edge edge, {shape = EdgeShape.straight, bool isSelected = false}) {
    List<Offset> intersectionPoints = calculateIntersectionPoints(edge.source, edge.target);

    Offset startPoint = intersectionPoints[0];
    Offset endPoint = intersectionPoints[1];

    final paintStyle = getEdgePaintStyle(edge.type, isSelected: isSelected);

    if (shape != EdgeShape.straight) {
      return drawCurvedEdge(canvas, edge, startPoint, endPoint, shape, paintStyle);
    }

    final path = drawStraightLine(canvas, startPoint, endPoint, paintStyle);
    drawArrowhead(canvas, endPoint, startPoint, paintStyle);
    return path;
  }

  static Path drawCurvedEdge(Canvas canvas, Edge edge, Offset start, Offset end, EdgeShape shape, Paint paintStyle) {
    const verticalAlignmentThreshold = 70;
    bool areNodesVerticallyAligned = (start.dx - end.dx).abs() < verticalAlignmentThreshold;

    const displacementValue = 50.0;

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
  static Path drawLoop(Canvas canvas, Node node, EdgeType edgeType, {bool small = false, bool isSelected = false}) {
    final paintStyle = getEdgePaintStyle(edgeType, isSelected: isSelected);

    final loopWidth = 60.0 / (small ? 1.5 : 1);
    final loopHeight = 70.0 / (small ? 1.5 : 1);

    final nodeX = Utils.snapToGrid(node.position.dx, gridSize);
    final nodeY = Utils.snapToGrid(node.position.dy, gridSize);

    final (nodeWidth, _) = NodePainter.calculateNodeBoxSize(node.id);

    final boxTopCenterX = nodeX + nodeWidth / 2;
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

  static List<Offset> calculateIntersectionPoints(Node node1, Node node2) {
    final x1 = Utils.snapToGrid(node1.position.dx, gridSize);
    final y1 = Utils.snapToGrid(node1.position.dy, gridSize);
    final x2 = Utils.snapToGrid(node2.position.dx, gridSize);
    final y2 = Utils.snapToGrid(node2.position.dy, gridSize);

    final (node1Width, node1Height) = NodePainter.calculateNodeBoxSize(node1.id);
    final (node2Width, node2Height) = NodePainter.calculateNodeBoxSize(node2.id);

    final node1Offset = Offset(x1 + node1Width / 2, y1 + node1Height / 2);
    final node2Offset = Offset(x2 + node2Width / 2, y2 + node2Height / 2);

    final node1Center = Offset(node1Offset.dx, node1Offset.dy);
    final node2Center = Offset(node2Offset.dx, node2Offset.dy);

    Offset intersect1 = intersectionPoint(node1Center, node2Center, node1Width, node1Height);
    Offset intersect2 = intersectionPoint(node2Center, node1Center, node2Width, node2Height);

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

  static void drawArrowhead(Canvas canvas, Offset point, Offset direction, Paint paint, {double arrowLength = 20}) {
    double arrowAngle = pi / 6;

    double edgeAngle = atan2(direction.dy - point.dy, direction.dx - point.dx);

    Offset arrowPoint1 = Offset(
      point.dx + arrowLength * cos(edgeAngle + arrowAngle),
      point.dy + arrowLength * sin(edgeAngle + arrowAngle),
    );
    Offset arrowPoint2 = Offset(
      point.dx + arrowLength * cos(edgeAngle - arrowAngle),
      point.dy + arrowLength * sin(edgeAngle - arrowAngle),
    );

    canvas.drawLine(point, arrowPoint1, paint);
    canvas.drawLine(point, arrowPoint2, paint);
  }
}
