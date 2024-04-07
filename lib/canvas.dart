import 'package:flutter/material.dart';

const gridSize = 25.0;

double snapToGrid(double value) {
  return (value / gridSize).round() * gridSize;
}

Offset snapPositionToGrid(Offset position) {
  return Offset(snapToGrid(position.dx), snapToGrid(position.dy));
}

class CanvasTransform {
  final Offset offset;
  final double scale;

  CanvasTransform({this.offset = Offset.zero, this.scale = 1.0});

  CanvasTransform copyWith({Offset? offset, double? scale}) {
    return CanvasTransform(offset: offset ?? this.offset, scale: scale ?? this.scale);
  }

  @override
  toString() {
    return 'CanvasTransform(offset: $offset, scale: $scale)';
  }
}
