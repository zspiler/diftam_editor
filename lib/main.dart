import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as vector;

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
      home: Scaffold(body: CanvasView()),
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
  bool isInEdgeDrawingMode = false;
  bool isInNodeCreationMode = false;
  Offset? draggingStartPoint;
  Offset? draggingEndPoint;
  int? nodeFromWhichDragging;
  Offset cursorPosition = Offset.zero;
  Offset canvasPosition = Offset.zero;
  double scale = 1.0;

  @override
  void initState() {
    super.initState();
    // TODO why cant just do this above?
    setState(() {
      nodes.add(Node(Point(100, 100)));
      nodes.add(Node(Point(300, 300)));
      nodes.add(Node(Point(500, 150)));

      edges[0] = [1];
      edges[1] = [1];
    });
  }

  bool isHit(Node node, Offset offset) {
    return node.position.x < offset.dx &&
        node.position.x + boxSize > offset.dx &&
        node.position.y < offset.dy &&
        node.position.y + boxSize > offset.dy;
  }

  void stopEdgeDrawing() {
    setState(() {
      nodeFromWhichDragging = null;
      draggingStartPoint = null;
      draggingEndPoint = null;
      isInEdgeDrawingMode = false;
    });
  }

  void handlePanning(Offset scrollDelta) {
    setState(() {
      canvasPosition -= scrollDelta / 1.5;
    });
  }

  void handleZoom(Offset scrollDelta) {
    final oldScale = scale;

    if (scrollDelta.dy < 0) {
      setState(() {
        scale *= 1.1;
      });
    } else {
      setState(() {
        scale *= 0.9;
      });
    }

    final scaleChange = scale - oldScale;
    final offsetX = -(cursorPosition.dx * scaleChange);
    final offsetY = -(cursorPosition.dy * scaleChange);

    setState(() {
      canvasPosition += Offset(offsetX, offsetY);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        color: Colors.blue,
        width: 175, // temp to prevent column resize when texty value changes
        child: Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor:
                    isInEdgeDrawingMode ? Colors.green : Colors.red,
                elevation: 0,
                minimumSize: Size(100, 70),
              ),
              onPressed: () {
                setState(() {
                  isInNodeCreationMode = false;
                  if (isInEdgeDrawingMode) {
                    stopEdgeDrawing();
                  } else {
                    isInEdgeDrawingMode = true;
                  }
                });
              },
              child: const Text("Edge drawing"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor:
                    isInNodeCreationMode ? Colors.green : Colors.red,
                elevation: 0,
                minimumSize: Size(100, 70),
              ),
              onPressed: () {
                setState(() {
                  stopEdgeDrawing();
                  if (isInNodeCreationMode) {
                    isInNodeCreationMode = false;
                  } else {
                    isInNodeCreationMode = true;
                  }
                });
              },
              child: const Text("Add node"),
            ),
          ],
        ),
      ),
      Expanded(
        child: Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is! PointerScrollEvent) return;

            final isMetaPressed = RawKeyboard.instance.keysPressed
                .contains(LogicalKeyboardKey.metaLeft);

            // TODO: fix trackpad behavior
            if (isMetaPressed) {
              handleZoom(pointerSignal.scrollDelta);
            } else {
              handlePanning(pointerSignal.scrollDelta);
            }
          },
          onPointerHover: (event) {
            setState(() {
              /*
                Because Listener is outside Transformation (since we want to scroll etc. even outside original canvas area). 
                here the coordinates do not match transformd coordinates so we need to apply inverse transformation.
               */
              Matrix4 inverseTransformation = Matrix4.identity()
                ..translate(canvasPosition.dx, canvasPosition.dy)
                ..scale(scale, scale)
                ..invert();

              vector.Vector3 transformedPositionVector =
                  inverseTransformation.transform3(vector.Vector3(
                      event.localPosition.dx, event.localPosition.dy, 0));

              cursorPosition = Offset(
                  transformedPositionVector.x, transformedPositionVector.y);
            });

            if (isInEdgeDrawingMode) {
              setState(() {
                draggingEndPoint = cursorPosition;
              });
            }
          },
          child: Container(
            color: Color.fromARGB(255, 20, 54, 91),
            child: ClipRect(
              child: Transform(
                transform: Matrix4.identity()
                  ..translate(canvasPosition.dx, canvasPosition.dy)
                  ..scale(scale, scale),
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: darkBlue,
                  child: GestureDetector(
                      onTapUp: (details) {
                        if (isInNodeCreationMode) {
                          setState(() {
                            nodes.add(Node(Point(
                                details.localPosition.dx - boxSize / 2,
                                details.localPosition.dy - boxSize / 2)));
                          });
                          isInNodeCreationMode = false;
                          return;
                        }
                      },
                      onTapDown: (details) {
                        if (isInEdgeDrawingMode) {
                          for (var (i, node) in nodes.indexed) {
                            if (isHit(node, details.localPosition)) {
                              if (draggingStartPoint == null) {
                                // NOTE probably dont need here since its called on hover but ok
                                setState(() {
                                  draggingStartPoint = details.localPosition;
                                  nodeFromWhichDragging = i;
                                });
                              } else {
                                setState(() {
                                  // TODO ensure edge of same type is one-way?
                                  if (edges
                                      .containsKey(nodeFromWhichDragging)) {
                                    edges[nodeFromWhichDragging!]!
                                        .add(i); // TODO null safety 😬
                                  } else {
                                    edges[nodeFromWhichDragging!] = [i];
                                  }
                                });
                                stopEdgeDrawing();
                              }
                              return;
                            }
                          }
                          stopEdgeDrawing();
                          return;
                        }
                      },
                      onPanStart: (details) {
                        if (isInEdgeDrawingMode || isInNodeCreationMode) return;
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
                        if (isInEdgeDrawingMode || isInNodeCreationMode) return;

                        // TODO respect canvas boundaries
                        if (nodeBeingDraggedIndex != null) {
                          final node = nodes[nodeBeingDraggedIndex!];
                          final newNode = Node(Point(
                              node.position.x + details.delta.dx,
                              node.position.y + details.delta.dy));
                          setState(() {
                            nodes[nodeBeingDraggedIndex!] = newNode;
                          });
                        }
                      },
                      onPanEnd: (details) {
                        nodeBeingDraggedIndex = null;
                      },
                      child: CustomPaint(
                        painter: MyCustomPainter(
                            nodes,
                            edges,
                            isInEdgeDrawingMode &&
                                    draggingStartPoint != null &&
                                    draggingEndPoint != null
                                ? (draggingStartPoint!, draggingEndPoint!)
                                : null), // TODO null safety 😬
                      )),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class MyCustomPainter extends CustomPainter {
  final List<Node> nodes;
  final Map<int, List<int>> edges;
  final (Offset, Offset)? newEdge; // TODO check existing type for this

  MyCustomPainter(this.nodes, this.edges, this.newEdge);

  @override
  void paint(Canvas canvas, Size size) {
    // NOTE widget rebuilt each time _CanvasViewState changes 😬
    for (var node in nodes) {
      NodePainter.drawNode(canvas, node);
    }

    edges.forEach((fromNodeIndex, toNodeIndexes) {
      for (var toNodeIndex in toNodeIndexes) {
        EdgePainter.drawEdge(canvas, nodes[fromNodeIndex], nodes[toNodeIndex]);
      }
    });

    if (newEdge != null) {
      EdgePainter.drawEdgeInProgress(canvas, newEdge!);
      // TODO always use offset vs point
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true; // TODO optimize?
}

const strokeWidth = 4.0;

class NodePainter {
  static final paintStyle = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = Colors.lime;

  static void drawNode(Canvas canvas, Node node) {
    final (x, y) = (node.position.x as double, node.position.y as double);
    final radius = Radius.circular(20);

    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, boxSize, boxSize), radius),
        paintStyle);
  }
}

class EdgePainter {
  static final paintStyle = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = Colors.lime;

  static void drawEdgeInProgress(Canvas canvas, (Offset, Offset) points) {
    final paintStyleFaded = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.lime.withOpacity(0.7);

    final (fromPoint, toPoint) = points;
    canvas.drawLine(fromPoint, toPoint, paintStyleFaded);
    drawArrowhead(canvas, toPoint, fromPoint, paintStyleFaded);
  }

  static void drawEdge(Canvas canvas, Node fromNode, Node toNode) {
    if (fromNode == toNode) {
      drawLoop(canvas, fromNode);
      return;
    }

    final fromOffset = Offset(
        fromNode.position.x + boxSize / 2, fromNode.position.y + boxSize / 2);
    final toOffset = Offset(
        toNode.position.x + boxSize / 2, toNode.position.y + boxSize / 2);

    List<Point> points = calculateIntersectionPoints(
        Point(fromOffset.dx, fromOffset.dy), Point(toOffset.dx, toOffset.dy));

    canvas.drawLine(Offset(points[0].x as double, points[0].y as double),
        Offset(points[1].x as double, points[1].y as double), paintStyle);

    drawArrowhead(canvas, Offset(points[1].x as double, points[1].y as double),
        Offset(points[0].x as double, points[0].y as double), paintStyle);
  }

  // TODO: dynamic, avoid other edges
  static void drawLoop(Canvas canvas, Node node) {
    const double loopWidth = boxSize / 2 + 10;
    const double loopHeight = boxSize / 2 + 10;

    final Offset boxTopCenter =
        Offset(node.position.x + boxSize / 2, node.position.y as double);

    // control points for the Bezier curve
    final Offset controlPoint1 = boxTopCenter.translate(loopWidth, -loopHeight);
    final Offset controlPoint2 =
        boxTopCenter.translate(-loopWidth, -loopHeight);

    // start and end points
    final Offset loopPoint =
        boxTopCenter.translate(0, -paintStyle.strokeWidth * 2);

    final Path path = Path();
    path.moveTo(loopPoint.dx, loopPoint.dy);
    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      loopPoint.dx,
      loopPoint.dy,
    );

    canvas.drawPath(path, paintStyle);

    // arrow is rotated by 90 degrees to make the arrow point downwards
    final double angle = atan2(
            controlPoint2.dy - loopPoint.dy, controlPoint2.dx - loopPoint.dx) +
        pi / 2;

    drawArrowhead(
        canvas,
        loopPoint,
        Offset(loopPoint.dx + cos(angle), loopPoint.dy + sin(angle)),
        paintStyle,
        arrowLength: 15);
  }

  static List<Point> calculateIntersectionPoints(Point center1, Point center2) {
    double width = boxSize;
    double height = boxSize;

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
      Canvas canvas, Offset point, Offset direction, Paint paint,
      {double arrowLength = 20}) {
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
