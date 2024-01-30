import 'package:flutter/material.dart';
import 'dart:math';

import 'common.dart';

class NodePainter {
  static const strokeWidth = 4.0;
  static const textStyle = TextStyle(color: Colors.white, fontSize: 18);

  static Radius getNodeRadius(NodeType nodeType) {
    return nodeType == NodeType.tag ? const Radius.circular(24) : const Radius.circular(2);
  }

  static Paint getNodePaintStyle(NodeType nodeType, {bool isSelected = false}) {
    final color = isSelected
        ? Colors.white
        : switch (nodeType) {
            NodeType.tag => Colors.lime,
            NodeType.entry => Colors.grey,
            NodeType.exit => const Color.fromARGB(255, 96, 96, 96),
          };

    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
  }

  static void drawNode(Canvas canvas, Node node, {bool isSelected = false}) {
    var (x, y) = (node.position.x as double, node.position.y as double);

    x = Utils.snapToGrid(x, gridSize);
    y = Utils.snapToGrid(y, gridSize);

    final (boxWidth, boxHeight) = calculateNodeBoxSize(node.id);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, boxWidth, boxHeight), getNodeRadius(node.type)),
        getNodePaintStyle(node.type, isSelected: isSelected));

    drawText(canvas, x, y, node.id, node);
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

  static (double width, double height) calculateNodeBoxSize(String nodeId) {
    var boxWidth = min(getNodeTextPainter(nodeId).width, 100) + 50 as double;
    var boxHeight = 75 as double;

    boxWidth = Utils.snapToGrid(boxWidth, gridSize);
    boxHeight = Utils.snapToGrid(boxHeight, gridSize);
    return (boxWidth, boxHeight);
  }

  static void drawText(Canvas canvas, double x, double y, String text, Node node) {
    final (boxWidth, boxHeight) = calculateNodeBoxSize(node.id);

    final textPainter = getNodeTextPainter(node.id);

    textPainter.paint(
        canvas, Offset(x + boxWidth / 2 - textPainter.width * 0.5, y + boxHeight / 2 - textPainter.height * 0.5));
  }
}
