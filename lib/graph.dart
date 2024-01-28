import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as vector;

import 'nodepainter.dart';
import 'graphpainter.dart';
import 'common.dart';
import 'snackbar.dart';
import 'menubar.dart';
import 'infopanel.dart';

class CanvasView extends StatefulWidget {
  const CanvasView({
    super.key,
  });

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

const darkBlue = Color.fromARGB(255, 20, 54, 91);

class _CanvasViewState extends State<CanvasView> {
  var nodes = <Node>[]; // TODO Set!
  var edges = <Edge>[]; // TODO Set!
  var pathPerEdge = <Edge, Path>{};

  Offset? draggingStartPoint;
  Offset? draggingEndPoint;
  Node? nodeBeingDragged;
  Node? nodeFromWhichDragging;
  Offset cursorPosition = Offset.zero;
  Offset canvasPosition = Offset.zero;
  GraphObject? hoveredObject;
  GraphObject? selectedObject;

  double scale = 1.0;

  EdgeType? _drawingEdgeType; // TODO private?
  NodeType? _drawingNodeType; // TODO private?

  @override
  void initState() {
    super.initState();
    // TODO why cant just do this above?
    setState(() {
      // TODO ensure unique IDS?
      final someLongId = Node("some long id", Point(100, 100), NodeType.tag);
      final tag2 = Node("tag 2", Point(300, 300), NodeType.tag);
      // final tag3 = Node("tag 3", Point(500, 150), NodeType.tag);
      // final stdin = Node("stdin", Point(600, 150), NodeType.entry);
      // final stdout = Node("stdout", Point(800, 150), NodeType.exit);
      // final someVeryVeryVeryLongId = Node("some very very very long id", Point(500, 100), NodeType.tag);

      nodes.add(someLongId);
      nodes.add(tag2);
      // nodes.add(tag3);
      // nodes.add(stdin);
      // nodes.add(stdout);
      // nodes.add(someVeryVeryVeryLongId);

      edges.add(Edge(someLongId, tag2, EdgeType.oblivious));
      edges.add(Edge(someLongId, tag2, EdgeType.aware));
      edges.add(Edge(someLongId, someLongId, EdgeType.oblivious));
      // edges.add(Edge(someLongId, tag3, EdgeType.oblivious));
      // edges.add(Edge(tag2, tag3, EdgeType.aware));
    });
  }

  bool isInSelectionMode() {
    return _drawingEdgeType == null && _drawingNodeType == null;
  }

  bool isInEdgeDrawingMode() {
    return _drawingEdgeType != null;
  }

  bool isInNodeCreationMode() {
    return _drawingNodeType != null;
  }

  bool isNodeHit(Node node, Offset offset) {
    final (nodeWidth, nodeHeight) = NodePainter.calculateNodeBoxSize(node.id);

    return node.position.x < offset.dx &&
        node.position.x + nodeWidth > offset.dx &&
        node.position.y < offset.dy &&
        node.position.y + nodeHeight > offset.dy;
  }

  bool isEdgeHit(Edge edge, Offset offset) {
    if (!pathPerEdge.containsKey(edge)) {
      return false; // sanity check
    }
    final path = pathPerEdge[edge]!;
    const threshold = 10;
    // approximate the Bezier curve with line segments
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      for (double t = 0.0; t < 1.0; t += 0.1) {
        // TODO find minimal precision
        var tangent = pathMetric.getTangentForOffset(pathMetric.length * t);
        if (tangent != null) {
          double distance = (tangent.position - cursorPosition).distance;
          if (distance < threshold) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void stopEdgeDrawing() {
    setState(() {
      nodeFromWhichDragging = null;
      draggingStartPoint = null;
      draggingEndPoint = null;
      _drawingEdgeType = null;
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

  void enterEdgeDrawingMode(EdgeType edgeType) {
    setState(() {
      _drawingNodeType = null;
      if (_drawingEdgeType == null || _drawingEdgeType != edgeType) {
        _drawingEdgeType = edgeType;
      } else {
        _drawingEdgeType = null;
      }
    });
  }

  void enterNodeDrawingMode(NodeType nodeType) {
    setState(() {
      _drawingEdgeType = null;
      if (_drawingNodeType == null || _drawingNodeType != nodeType) {
        _drawingNodeType = nodeType;
      } else {
        _drawingNodeType = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is! PointerScrollEvent) return;

          final isMetaPressed = RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.metaLeft);

          // TODO: Fix trackpad!
          if (isMetaPressed) {
            handleZoom(pointerSignal.scrollDelta);
          } else {
            handlePanning(pointerSignal.scrollDelta);
          }
        },
        onPointerHover: (event) {
          // TODO this is currently terrible - all mouse movement updates states and rerenders everything 🙈
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
                inverseTransformation.transform3(vector.Vector3(event.localPosition.dx, event.localPosition.dy, 0));

            cursorPosition = Offset(transformedPositionVector.x, transformedPositionVector.y);
          });

          if (isInEdgeDrawingMode()) {
            setState(() {
              draggingEndPoint = cursorPosition;
            });
          } else if (isInSelectionMode()) {
            setState(() {
              hoveredObject = null;
            });
            for (var node in nodes) {
              if (isNodeHit(node, cursorPosition)) {
                setState(() {
                  hoveredObject = node;
                });
                break;
              }
            }

            for (var edge in edges) {
              if (isEdgeHit(edge, cursorPosition)) {
                setState(() {
                  hoveredObject = edge;
                });
                break;
              }
            }
          }
        },
        child: MouseRegion(
          cursor: hoveredObject != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Container(
            color: Colors.grey[200],
            child: ClipRect(
              child: Transform(
                transform: Matrix4.identity()
                  ..translate(canvasPosition.dx, canvasPosition.dy)
                  ..scale(scale, scale),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: darkBlue,
                  child: GestureDetector(
                      onTapUp: (details) {
                        if (isInSelectionMode()) {
                          setState(() {
                            selectedObject = hoveredObject;
                          });
                        } else if (isInNodeCreationMode()) {
                          setState(() {
                            final randomId = Utils.generateRandomString(4);
                            final (nodeWidth, nodeHeight) = NodePainter.calculateNodeBoxSize(randomId);
                            final newNodePosition = Point(
                                details.localPosition.dx - nodeWidth / 2, details.localPosition.dy - nodeHeight / 2);

                            final newNode = Node(randomId, newNodePosition, _drawingNodeType!);
                            nodes.add(newNode);
                            selectedObject = newNode;
                            _drawingNodeType = null;
                          });
                        }
                      },
                      onTapDown: (details) {
                        if (isInEdgeDrawingMode()) {
                          for (var node in nodes) {
                            if (isNodeHit(node, details.localPosition)) {
                              if (draggingStartPoint == null) {
                                // NOTE probably dont need here since its called on hover but ok
                                setState(() {
                                  draggingStartPoint = details.localPosition;
                                  nodeFromWhichDragging = node;
                                });
                              } else {
                                if (nodeFromWhichDragging != null && _drawingEdgeType != null) {
                                  try {
                                    final newEdge = Edge(nodeFromWhichDragging!, node, _drawingEdgeType!);
                                    final edgeExists = edges.any((edge) =>
                                        edge.source == newEdge.source &&
                                        edge.target == newEdge.target &&
                                        edge.type == newEdge.type);
                                    if (!edgeExists) {
                                      setState(() {
                                        edges.add(newEdge);
                                      });
                                    }
                                  } on ArgumentError catch (e) {
                                    SnackbarGlobal.show(e.message);
                                  }
                                }
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
                        if (isInEdgeDrawingMode() || isInNodeCreationMode()) return;
                        for (var node in nodes) {
                          if (isNodeHit(node, details.localPosition)) {
                            setState(() {
                              nodeBeingDragged = node;
                            });
                            break;
                          }
                        }
                      },
                      onPanUpdate: (details) {
                        if (isInEdgeDrawingMode() || isInNodeCreationMode()) return;

                        if (nodeBeingDragged != null) {
                          var newX = nodeBeingDragged!.position.x + details.delta.dx;
                          var newY = nodeBeingDragged!.position.y + details.delta.dy;

                          final canvasWidth = MediaQuery.of(context).size.width - 175;
                          final canvasHeight = MediaQuery.of(context).size.height;

                          final (nodeWidth, nodeHeight) = NodePainter.calculateNodeBoxSize(nodeBeingDragged!.id);

                          final isNewPositionValid = newX > 0 &&
                              newX + nodeWidth < canvasWidth &&
                              newY > 0 &&
                              newY + nodeHeight < canvasHeight;

                          if (!isNewPositionValid) {
                            return;
                          }

                          setState(() {
                            nodeBeingDragged!.position = Point(newX, newY);
                          });
                        }
                      },
                      onPanEnd: (details) {
                        nodeBeingDragged = null;
                      },
                      child: CustomPaint(
                        painter: GraphPainter(
                          nodes,
                          edges,
                          isInEdgeDrawingMode() && draggingStartPoint != null && draggingEndPoint != null
                              ? (draggingStartPoint!, draggingEndPoint!) // TODO null safety
                              : null,
                          (newPathPerEdge) => pathPerEdge = newPathPerEdge,
                          selectedObject,
                        ),
                      )),
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: 16,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.topCenter,
          child: MyMenuBar(
              onAwareConnectionPress: () => enterEdgeDrawingMode(EdgeType.aware),
              onObliviousConnectionPress: () => enterEdgeDrawingMode(EdgeType.oblivious),
              onEntryNodePress: () => enterNodeDrawingMode(NodeType.entry),
              onExitNodePress: () => enterNodeDrawingMode(NodeType.exit),
              onTagNodePress: () => enterNodeDrawingMode(NodeType.tag),
              drawingEdgeType: _drawingEdgeType,
              drawingNodeType: _drawingNodeType),
        ),
      ),
      if (selectedObject != null)
        Positioned(
            bottom: 16,
            right: 0,
            child: Align(alignment: Alignment.bottomCenter, child: InfoPanel(text: selectedObject.toString()))),
    ]);
  }
}
