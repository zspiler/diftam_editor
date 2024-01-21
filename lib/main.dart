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
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: CanvasView(),
      ),
    );
  }
}

class CanvasView extends StatefulWidget {
  const CanvasView({
    super.key,
  });

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

const boxSize = 100.0;

class _CanvasViewState extends State<CanvasView> {
  var nodes = <Node>[];
  var edges = Map<int, List<int>>();

  int? nodeBeingDraggedIndex;

  @override
  void initState() {
    super.initState();
    // TODO why cant just do this above?
    setState(() {
      nodes.add(Node(Point(150, 150)));
      nodes.add(Node(Point(300, 300)));

      edges[0] = [1];
    });
  }

  bool isHit(Node node, Offset offset) {
    return node.position.x < offset.dx &&
        node.position.x + boxSize > offset.dx &&
        node.position.y < offset.dy &&
        node.position.y + boxSize > offset.dy;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        for (var (i, node) in nodes.indexed) {
          if (isHit(node, details.localPosition)) {
            setState(() {
              nodeBeingDraggedIndex = i;
            });
            break;
          }
        }
      },
      onPanUpdate: (details) {
        if (nodeBeingDraggedIndex != null) {
          final node = nodes[nodeBeingDraggedIndex!];
          final newNode = Node(Point(node.position.x + details.delta.dx,
              node.position.y + details.delta.dy));
          setState(() {
            nodes[nodeBeingDraggedIndex!] = newNode;
          });
        }
      },
      onPanEnd: (details) {
        nodeBeingDraggedIndex = null;
      },
      child: Container(
        color: darkBlue,
        height: 1000,
        width: 1000,
        child: CustomPaint(
          painter: MyCustomPainter(nodes, edges),
        ),
      ),
    );
  }
}

class MyCustomPainter extends CustomPainter {
  final List<Node> nodes;
  final Map<int, List<int>> edges;

  MyCustomPainter(this.nodes, this.edges);

  @override
  void paint(Canvas canvas, Size size) {
    // NOTE widget rebuilt each time _CanvasViewState changes 😬
    for (var node in nodes) {
      NodeDrawer.drawNode(
          canvas, node.position.x as double, node.position.y as double);
    }

    edges.forEach((fromNodeIndex, toNodeIndexes) {
      for (var toNodeIndex in toNodeIndexes) {
        EdgeDrawer.drawEdge(
            canvas, nodes[fromNodeIndex].position, nodes[toNodeIndex].position);
      }
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class NodeDrawer {
  static void drawNode(Canvas canvas, double x, double y) {
    final radius = Radius.circular(20);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.lime;

    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, boxSize, boxSize), radius),
        paint);
  }
}

class EdgeDrawer {
  static void drawEdge(Canvas canvas, Point fromPoint, Point toPoint) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.lime;

    final fromOffset =
        Offset(fromPoint.x + boxSize / 2, fromPoint.y + boxSize / 2);
    final toOffset = Offset(toPoint.x + boxSize / 2, toPoint.y + boxSize / 2);

    List<Point> points = calculateIntersectionPoints(
        Point(fromOffset.dx, fromOffset.dy), Point(toOffset.dx, toOffset.dy));

    canvas.drawLine(Offset(points[0].x as double, points[0].y as double),
        Offset(points[1].x as double, points[1].y as double), paint);

    drawArrowhead(canvas, Offset(points[1].x as double, points[1].y as double),
        Offset(points[0].x as double, points[0].y as double), paint);
  }

  static List<Point> calculateIntersectionPoints(Point center1, Point center2) {
    double width = 100.0;
    double height = 100.0;

    Point intersect1 = intersectionPoint(center1, center2, width, height);
    Point intersect2 = intersectionPoint(center2, center1, width, height);

    return [intersect1, intersect2];
  }

  static Point intersectionPoint(
      Point center1, Point center2, double width, double height) {
    double dx = center2.x - center1.x as double;
    double dy = center2.y - center1.y as double;

    double absDx = dx.abs();
    double absDy = dy.abs();

    double scaleX = 1.0, scaleY = 1.0;

    if (absDx > 0) scaleX = (width / 2) / absDx;
    if (absDy > 0) scaleY = (height / 2) / absDy;

    double scale = min(scaleX, scaleY);

    return Point(center1.x + dx * scale, center1.y + dy * scale);
  }

  static void drawArrowhead(
      Canvas canvas, Offset point, Offset direction, Paint paint) {
    double arrowLength = 20;
    double arrowAngle = pi / 6;

    double edgeAngle = atan2(direction.dy - point.dy, direction.dx - point.dx);

    Offset arrowPoint1 = Offset(
      point.dx + arrowLength * cos(edgeAngle + arrowAngle),
      point.dy + arrowLength * sin(edgeAngle + arrowAngle),
    );
    Offset arrowPoint2 = Offset(
      point.dx + arrowLength * cos(edgeAngle - arrowAngle),
      point.dy + arrowLength * sin(edgeAngle - arrowAngle),
    );

    canvas.drawLine(point, arrowPoint1, paint);
    canvas.drawLine(point, arrowPoint2, paint);
  }
}

class Node {
  final Point position;

  Node(this.position);
}
