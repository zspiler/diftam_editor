import 'package:flutter/material.dart';
import 'dart:math';
import '../policy/policy.dart';
import '../canvas.dart';

class NodePainter {
  final CanvasState canvasState;
  final Color tagNodeColor;
  final Color entryNodeColor;
  final Color exitNodeColor;
  final int strokeWidth;
  final int nodePadding;

  NodePainter({
    required this.canvasState,
    required this.tagNodeColor,
    required this.entryNodeColor,
    required this.exitNodeColor,
    required this.strokeWidth,
    required this.nodePadding,
  });

  Color getNodeColor(Node node) {
    if (node is TagNode) {
      return tagNodeColor;
    } else if (node is EntryNode) {
      return entryNodeColor;
    } else {
      return exitNodeColor;
    }
  }

  Paint getNodePaintStyle(Node node, {bool isSelected = false}) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * canvasState.scale
      ..color = isSelected ? Colors.white : getNodeColor(node);
  }

  ({Radius topLeft, Radius bottomLeft, Radius topRight, Radius bottomRight}) getNodeRadii(Node node) {
    final largeRadius = Radius.circular(nodePadding * 8);
    final defaultRadius = Radius.circular(nodePadding * 2);

    return (
      topLeft: node is TagNode || node is EntryNode ? largeRadius : defaultRadius,
      bottomLeft: node is TagNode || node is EntryNode ? largeRadius : defaultRadius,
      topRight: node is TagNode || node is ExitNode ? largeRadius : defaultRadius,
      bottomRight: node is TagNode || node is ExitNode ? largeRadius : defaultRadius
    );
  }

  void drawNode(Canvas canvas, Node node, {bool isSelected = false}) {
    final x = (snapToGrid(node.position.dx) + canvasState.position.dx) * canvasState.scale;
    final y = (snapToGrid(node.position.dy) + canvasState.position.dy) * canvasState.scale;

    final nodeSize = calculateNodeSize(node, padding: nodePadding) * canvasState.scale;

    final nodeRadii = getNodeRadii(node);

    canvas.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(x, y, nodeSize.width, nodeSize.height),
            topLeft: nodeRadii.topLeft * canvasState.scale,
            bottomLeft: nodeRadii.bottomLeft * canvasState.scale,
            topRight: nodeRadii.topRight * canvasState.scale,
            bottomRight: nodeRadii.bottomRight * canvasState.scale),
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
      span = TextSpan(style: textStyle, text: '${nodeId.substring(0, 12)}...');
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
    width = snapToGrid(width);
    height = snapToGrid(height);
    return Size(width, height);
  }

  void drawText(Canvas canvas, double x, double y, String text, Node node) {
    final nodeSize = calculateNodeSize(node, padding: nodePadding) * canvasState.scale;

    final textPainter = getNodeTextPainter(text, scale: canvasState.scale);

    textPainter.paint(
        canvas, Offset(x + nodeSize.width / 2 - textPainter.width * 0.5, y + nodeSize.height / 2 - textPainter.height * 0.5));
  }
}
