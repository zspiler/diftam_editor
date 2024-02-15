import 'dart:math';
import 'package:flutter/material.dart';

String generateRandomString(int len) {
  var r = Random();
  const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  return List.generate(len, (index) => _chars[r.nextInt(_chars.length)]).join();
}

bool isPointNearBezierPath(Offset point, Path path) {
  const step = 0.05;
  const threshold = 15;
  // approximate the Bezier curve with line segments
  final pathMetrics = path.computeMetrics();
  for (final pathMetric in pathMetrics) {
    for (double t = 0.0; t < 1.0; t += step) {
      var tangent = pathMetric.getTangentForOffset(pathMetric.length * t);
      if (tangent != null) {
        double distance = (tangent.position - point).distance;
        if (distance < threshold) {
          return true;
        }
      }
    }
  }
  return false;
}
