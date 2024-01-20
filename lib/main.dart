import 'package:flutter/material.dart';
import 'dart:math';

final Color darkBlue = Color.fromARGB(255, 18, 32, 47);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: darkBlue),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: CustomPaint(
          painter: RectangularFlowerPainter(),
        ),
      ),
    );
  }
}

class RectangularFlowerPainter extends CustomPainter {
  Paint green_paint = Paint()..color = Color(0xff00ff00);
  Paint yellow_paint = Paint()..color = Color(0xffebe834);
  Paint white_paint = Paint()..color = Color(0xffFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    // canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), white_paint);

    canvas.translate(0, 300); // starting pint

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.lime;

    final radius = Radius.circular(20);

    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(20, 40, 100, 100), radius),
        paint);

    canvas.drawLine(Offset(120, 90), Offset(200, 90), paint);

    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(200, 40, 100, 100), radius),
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
