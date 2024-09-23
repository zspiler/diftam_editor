import 'package:flutter/material.dart';
import 'dart:math';
import 'package:diftam_editor/d2sc_policy/lib/d2sc_policy.dart';
import '../canvas.dart';

class NodePainter {
  final Color tagNodeColor;
  final Color entryNodeColor;
  final Color exitNodeColor;
  final int strokeWidth;
  final int nodePadding;

  NodePainter({
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
      ..strokeWidth = strokeWidth.toDouble()
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
    final nodePosition = snapPointToGrid(node.position);
    final nodeSize = calculateNodeSize(node, padding: nodePadding);

    final rect = Rect.fromLTWH(nodePosition.x, nodePosition.y, nodeSize.width, nodeSize.height);
    final nodeRadii = getNodeRadii(node);
    final roundedRect = RRect.fromRectAndCorners(rect,
        topLeft: nodeRadii.topLeft,
        bottomLeft: nodeRadii.bottomLeft,
        topRight: nodeRadii.topRight,
        bottomRight: nodeRadii.bottomRight);

    canvas.drawRRect(roundedRect, getNodePaintStyle(node, isSelected: isSelected));

    drawText(canvas, nodePosition.x, nodePosition.y, node.label, node);
  }

  static TextPainter getNodeTextPainter(String nodeId) {
    const textStyle = TextStyle(color: Colors.white, fontSize: 18);
    TextSpan span = TextSpan(style: textStyle, text: nodeId);
    if (nodeId.length > 15) {
      span = TextSpan(style: textStyle, text: '${nodeId.substring(0, 12)}...');
    }

    final textPainter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    textPainter.layout();
    return textPainter;
  }

  /*
  This method receives padding parameter (and is static) since otherwise we'd have to make sure we're using a NodePainter with up-to-date preferences
  each time we called this from outside. TODO
   */
  static Size calculateNodeSize(Node node, {required int padding}) {
    var baseWidth = min(getNodeTextPainter(node.label).width, 100) + 15.0 * padding;

    // Ensure node width is always even number of grid-squares wide.
    // This ensures edges between nodes and nodes right below/above them are straight.
    var snappedWidth = snapToGrid(baseWidth);
    if (snappedWidth % (2 * gridSize) != 0) {
      snappedWidth += gridSize;
    }

    final height = gridSize * padding;

    return Size(snappedWidth, snapToGrid(height));
  }

  void drawText(Canvas canvas, double x, double y, String text, Node node) {
    final nodeSize = calculateNodeSize(node, padding: nodePadding);
    final textPainter = getNodeTextPainter(text);
    textPainter.paint(
        canvas, Offset(x + nodeSize.width / 2 - textPainter.width * 0.5, y + nodeSize.height / 2 - textPainter.height * 0.5));
  }

  static bool isPositionWithinNode(Node node, Offset position, int nodePadding) {
    final nodeSize = NodePainter.calculateNodeSize(node, padding: nodePadding);

    return node.position.x < position.dx &&
        node.position.x + nodeSize.width > position.dx &&
        node.position.y < position.dy &&
        node.position.y + nodeSize.height > position.dy;
  }
}
