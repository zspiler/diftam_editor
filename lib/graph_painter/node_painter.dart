import 'package:flutter/material.dart';
import 'dart:math';
import '../policy/policy.dart';
import '../grid.dart';
import '../user_preferences.dart';

class NodePainter {
  final Offset canvasPosition;
  final double canvasScale;
  final int strokeWidth;
  final Color tagNodeColor;
  final Color entryNodeColor;
  final Color exitNodeColor;
  final int nodePadding;

  NodePainter({
    required this.canvasPosition,
    required this.canvasScale,
    required Preferences preferences,
  })  : strokeWidth = preferences.nodeStrokeWidth,
        tagNodeColor = preferences.tagNodeColor,
        entryNodeColor = preferences.entryNodeColor,
        exitNodeColor = preferences.exitNodeColor,
        nodePadding = preferences.nodePadding;

  Radius getNodeRadius(Node node) {
    return node.runtimeType == TagNode ? Radius.circular(nodePadding * 8) : const Radius.circular(2);
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
      ..strokeWidth = strokeWidth * canvasScale
      ..color = isSelected ? Colors.white : getNodeColor(node);
  }

  void drawNode(Canvas canvas, Node node, {bool isSelected = false}) {
    final x = (snapToGrid(node.position.dx, gridSize) + canvasPosition.dx) * canvasScale;
    final y = (snapToGrid(node.position.dy, gridSize) + canvasPosition.dy) * canvasScale;

    final nodeSize = calculateNodeSize(node, padding: nodePadding) * canvasScale;

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

  /*
  This method receives padding parameter (and is static) since otherwise we'd have to make sure we're using a NodePainter with up-to-date preferences
  each time we called this from outside. TODO
   */
  static Size calculateNodeSize(Node node, {required int padding}) {
    var width = min(getNodeTextPainter(node.label).width, 100) + 15.0 * padding;
    var height = 25.0 * padding;
    width = snapToGrid(width, gridSize);
    height = snapToGrid(height, gridSize);
    return Size(width, height);
  }

  void drawText(Canvas canvas, double x, double y, String text, Node node) {
    final nodeSize = calculateNodeSize(node, padding: nodePadding) * canvasScale;

    final textPainter = getNodeTextPainter(text, scale: canvasScale);

    textPainter.paint(
        canvas, Offset(x + nodeSize.width / 2 - textPainter.width * 0.5, y + nodeSize.height / 2 - textPainter.height * 0.5));
  }
}
