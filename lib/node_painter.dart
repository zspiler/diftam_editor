import 'package:flutter/material.dart';
import 'dart:math';
import 'common.dart';
import 'utils.dart';

class NodePainter {
  static const textStyle = TextStyle(color: Colors.white, fontSize: 18);

  final int strokeWidth;

  NodePainter({int? strokeWidth}) : strokeWidth = strokeWidth ?? 4; // TODO default!

  static Radius getNodeRadius(Node node) {
    return node.runtimeType == TagNode ? const Radius.circular(24) : const Radius.circular(2);
  }

  static Color getNodeColor(Node node) {
    final Color nodeColor;
    if (node.runtimeType == TagNode) {
      nodeColor = Colors.lime;
    } else if (node.runtimeType == EntryNode) {
      nodeColor = Colors.grey;
    } else {
      nodeColor = const Color.fromARGB(255, 96, 96, 96);
    }
    return nodeColor;
  }

  Paint getNodePaintStyle(Node node, {bool isSelected = false}) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth.toDouble()
      ..color = isSelected ? Colors.white : getNodeColor(node);
  }

  void drawNode(Canvas canvas, Node node, {bool isSelected = false}) {
    var (x, y) = (node.position.dx, node.position.dy);

    x = Utils.snapToGrid(x, gridSize);
    y = Utils.snapToGrid(y, gridSize);

    final (boxWidth, boxHeight) = calculateNodeBoxSize(node);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, boxWidth, boxHeight), getNodeRadius(node)),
        getNodePaintStyle(node, isSelected: isSelected));

    drawText(canvas, x, y, node.label, node);
  }

  static TextPainter getNodeTextPainter(String nodeId) {
    TextSpan span = TextSpan(style: textStyle, text: nodeId);
    if (nodeId.length > 15) {
      span = TextSpan(style: textStyle, text: nodeId.substring(0, 12) + '...');
    }

    final textPainter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    textPainter.layout();
    return textPainter;
  }

  static (double width, double height) calculateNodeBoxSize(Node node) {
    var boxWidth = min(getNodeTextPainter(node.label).width, 100) + 50.0;
    var boxHeight = 75.0;

    boxWidth = Utils.snapToGrid(boxWidth, gridSize);
    boxHeight = Utils.snapToGrid(boxHeight, gridSize);
    return (boxWidth, boxHeight);
  }

  static void drawText(Canvas canvas, double x, double y, String text, Node node) {
    final (boxWidth, boxHeight) = calculateNodeBoxSize(node);

    final textPainter = getNodeTextPainter(text);

    textPainter.paint(canvas, Offset(x + boxWidth / 2 - textPainter.width * 0.5, y + boxHeight / 2 - textPainter.height * 0.5));
  }
}
