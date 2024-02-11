import 'package:flutter/material.dart';
import 'dart:math';
import '../common.dart';
import '../utils.dart';

class NodePainter {
  final Offset canvasPosition;
  final double canvasScale;
  final int strokeWidth;
  final Color tagNodeColor;
  final Color entryNodeColor;
  final Color exitNodeColor;

  NodePainter(
      {required this.canvasPosition,
      required this.canvasScale,
      required this.strokeWidth,
      required this.tagNodeColor,
      required this.entryNodeColor,
      required this.exitNodeColor});

  static Radius getNodeRadius(Node node) {
    return node.runtimeType == TagNode ? const Radius.circular(24) : const Radius.circular(2);
  }

  Color getNodeColor(Node node) {
    if (node.runtimeType == TagNode) {
      return tagNodeColor;
    } else if (node.runtimeType == EntryNode) {
      return entryNodeColor;
    } else {
      return exitNodeColor;
    }
  }

  Paint getNodePaintStyle(Node node, {bool isSelected = false}) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth.toDouble() * canvasScale
      ..color = isSelected ? Colors.white : getNodeColor(node);
  }

  void drawNode(Canvas canvas, Node node, {bool isSelected = false}) {
    final x = (Utils.snapToGrid(node.position.dx, gridSize) + canvasPosition.dx) * canvasScale;
    final y = (Utils.snapToGrid(node.position.dy, gridSize) + canvasPosition.dy) * canvasScale;

    final nodeSize = calculateNodeSize(node) * canvasScale;

    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, nodeSize.width, nodeSize.height), getNodeRadius(node) * canvasScale),
        getNodePaintStyle(
          node,
          isSelected: isSelected,
        ));

    drawText(canvas, x, y, node.label, node);
  }

  static TextPainter getNodeTextPainter(String nodeId, {double scale = 1.0}) {
    const textStyle = TextStyle(color: Colors.white, fontSize: 18);
    TextSpan span = TextSpan(style: textStyle, text: nodeId);
    if (nodeId.length > 15) {
      span = TextSpan(style: textStyle, text: nodeId.substring(0, 12) + '...');
    }

    final textPainter = TextPainter(
        text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr, textScaler: TextScaler.linear(scale));
    textPainter.layout();
    return textPainter;
  }

  static Size calculateNodeSize(Node node) {
    var width = min(getNodeTextPainter(node.label).width, 100) + 50.0;
    var height = 75.0;
    width = Utils.snapToGrid(width, gridSize);
    height = Utils.snapToGrid(height, gridSize);
    return Size(width, height);
  }

  void drawText(Canvas canvas, double x, double y, String text, Node node) {
    final nodeSize = calculateNodeSize(node) * canvasScale;

    final textPainter = getNodeTextPainter(text, scale: canvasScale);

    textPainter.paint(
        canvas, Offset(x + nodeSize.width / 2 - textPainter.width * 0.5, y + nodeSize.height / 2 - textPainter.height * 0.5));
  }
}
