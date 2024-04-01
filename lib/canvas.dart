import 'package:flutter/material.dart';

const gridSize = 25.0;

double snapToGrid(double value) {
  return (value / gridSize).round() * gridSize;
}

Offset snapPositionToGrid(Offset position) {
  return Offset(snapToGrid(position.dx), snapToGrid(position.dy));
}

class CanvasState {
  final Offset position;
  final double scale;

  CanvasState({this.position = Offset.zero, this.scale = 1.0});

  CanvasState copyWith({Offset? position, double? scale}) {
    return CanvasState(position: position ?? this.position, scale: scale ?? this.scale);
  }

  @override
  toString() {
    return 'CanvasState(position: $position, scale: $scale)';
  }
}
