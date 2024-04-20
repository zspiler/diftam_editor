import 'package:flutter/material.dart';
import 'dart:math';

const gridSize = 25.0;

double snapToGrid(double value) {
  return (value / gridSize).round() * gridSize;
}

Point<double> snapPointToGrid(Point<double> position) {
  return Point(snapToGrid(position.x), snapToGrid(position.y));
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
