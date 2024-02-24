import 'package:flutter/material.dart';
import '../canvas.dart';

class GridPainter {
  final CanvasState canvasState;

  GridPainter({
    required this.canvasState,
  });

  void drawGrid(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha(50)
      ..strokeWidth = canvasState.scale;

    final scaledGridSize = gridSize * canvasState.scale;

    final startX = ((canvasState.position.dx * canvasState.scale) % scaledGridSize) - scaledGridSize;
    final startY = ((canvasState.position.dy * canvasState.scale) % scaledGridSize) - scaledGridSize;

    final numberOfHorizontalLines = (canvasSize.width / scaledGridSize).ceil() + 1;
    final numberOfVerticalLines = (canvasSize.height / scaledGridSize).ceil() + 1;

    for (var i = 0; i < numberOfHorizontalLines; i++) {
      final x = startX + i * scaledGridSize;
      canvas.drawLine(Offset(x, 0), Offset(x, canvasSize.height), paint);
    }

    for (var i = 0; i < numberOfVerticalLines; i++) {
      final y = startY + i * scaledGridSize;
      canvas.drawLine(Offset(0, y), Offset(canvasSize.width, y), paint);
    }
  }
}
