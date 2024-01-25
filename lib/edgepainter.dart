import 'package:flutter/material.dart';
import 'dart:math';

import 'nodepainter.dart';
import 'common.dart';

class EdgePainter {
  static const strokeWidth = 4.0;

  static final paintStyle = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = Colors.lime;

  static void drawEdgeInProgress(Canvas canvas, (Offset, Offset) points) {
    final paintStyleFaded = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.lime.withOpacity(0.7);

    final (fromPoint, toPoint) = points;
    canvas.drawLine(fromPoint, toPoint, paintStyleFaded);
    drawArrowhead(canvas, toPoint, fromPoint, paintStyleFaded);
  }

  static void drawEdge(Canvas canvas, Node fromNode, Node toNode, {bool snapToGrid = false}) {
    if (fromNode == toNode) {
      drawLoop(canvas, fromNode, snapToGrid: true);
      return;
    }

    List<Point> points = calculateIntersectionPoints(fromNode, toNode, snapToGrid: true);

    canvas.drawLine(Offset(points[0].x as double, points[0].y as double),
        Offset(points[1].x as double, points[1].y as double), paintStyle);

    drawArrowhead(canvas, Offset(points[1].x as double, points[1].y as double),
        Offset(points[0].x as double, points[0].y as double), paintStyle);
  }

  // TODO: dynamic, avoid other edges
  static void drawLoop(Canvas canvas, Node node, {bool snapToGrid = false}) {
    const loopWidth = 60.0;
    const loopHeight = 70.0;

    var nodeX = node.position.x as double;
    var nodeY = node.position.y as double;

    if (snapToGrid) {
      nodeX = Utils.snapToGrid(nodeX, gridSize);
      nodeY = Utils.snapToGrid(nodeY, gridSize);
    }

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

    // arrow is rotated by 90 degrees to make the arrow point downwards
    final double angle = atan2(controlPoint2.dy - loopPoint.dy, controlPoint2.dx - loopPoint.dx) + pi / 2;

    drawArrowhead(canvas, loopPoint, Offset(loopPoint.dx + cos(angle), loopPoint.dy + sin(angle)), paintStyle,
        arrowLength: 15);
  }

  static List<Point> calculateIntersectionPoints(Node node1, Node node2, {bool snapToGrid = false}) {
    var (fromX, fromY) = (node1.position.x as double, node1.position.y as double);
    var (toX, toY) = (node2.position.x as double, node2.position.y as double);

    if (snapToGrid) {
      fromX = Utils.snapToGrid(fromX, gridSize);
      fromY = Utils.snapToGrid(fromY, gridSize);
      toX = Utils.snapToGrid(toX, gridSize);
      toY = Utils.snapToGrid(toY, gridSize);
    }

    final (fromNodeWidth, fromNodeHeight) = NodePainter.calculateNodeBoxSize(node1.id);
    final (toNodeWidth, toNodeHeight) = NodePainter.calculateNodeBoxSize(node2.id);

    final fromOffset = Offset(fromX + fromNodeWidth / 2, fromY + fromNodeHeight / 2);
    final toOffset = Offset(toX + toNodeWidth / 2, toY + toNodeHeight / 2);

    final node1Center = Point(fromOffset.dx, fromOffset.dy);
    final node2Center = Point(toOffset.dx, toOffset.dy);

    Point intersect1 = intersectionPoint(node1Center, node2Center, fromNodeWidth, fromNodeHeight);
    Point intersect2 = intersectionPoint(node2Center, node1Center, toNodeWidth, toNodeHeight);

    return [intersect1, intersect2];
  }

  static Point intersectionPoint(Point center1, Point center2, double width, double height) {
    double dx = center2.x - center1.x as double;
    double dy = center2.y - center1.y as double;

    double absDx = dx.abs();
    double absDy = dy.abs();

    double scaleX = 1.0, scaleY = 1.0;

    if (absDx > 0) scaleX = (width / 2) / absDx;
    if (absDy > 0) scaleY = (height / 2) / absDy;

    double scale = min(scaleX, scaleY);

    return Point(center1.x + dx * scale, center1.y + dy * scale);
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