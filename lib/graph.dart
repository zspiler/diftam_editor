import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as vector;

import 'nodepainter.dart';
import 'graphpainter.dart';
import 'common.dart';

class CanvasView extends StatefulWidget {
  const CanvasView({
    super.key,
  });

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

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

  NodeType _drawingNodeType = NodeType.tag;

  @override
  void initState() {
    super.initState();
    // TODO why cant just do this above?
    setState(() {
      // TODO ensure unique IDS?
      nodes.add(Node("some long id", Point(100, 100), NodeType.tag));
      nodes.add(Node("tag 2", Point(300, 300), NodeType.tag));
      nodes.add(Node("tag 3", Point(500, 150), NodeType.tag));
      nodes.add(Node("stdin", Point(600, 150), NodeType.entryExit));
      nodes.add(Node("some very very very long id", Point(500, 100), NodeType.tag));

      edges[0] = [1];
      edges[1] = [1];
    });
  }

  bool isHit(Node node, Offset offset) {
    final (nodeWidth, nodeHeight) = NodePainter.calculateNodeBoxSize(node.id);

    return node.position.x < offset.dx &&
        node.position.x + nodeWidth > offset.dx &&
        node.position.y < offset.dy &&
        node.position.y + nodeHeight > offset.dy;
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
                backgroundColor: isInEdgeDrawingMode ? Colors.green : Colors.red,
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
            DropdownButton<NodeType>(
                value: _drawingNodeType,
                onChanged: (NodeType? newValue) {
                  setState(() {
                    _drawingNodeType = newValue!;
                  });
                },
                items: NodeType.values.map((NodeType nodeType) {
                  return DropdownMenuItem<NodeType>(value: nodeType, child: Text(nodeType.value));
                }).toList()),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: isInNodeCreationMode ? Colors.green : Colors.red,
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

            final isMetaPressed = RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.metaLeft);

            // TODO: fix trackpad behavior
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
                  color: Color.fromARGB(255, 18, 32, 47),
                  child: GestureDetector(
                      onTapUp: (details) {
                        if (isInNodeCreationMode) {
                          setState(() {
                            final randomId = Utils.generateRandomString(4);

                            final (nodeWidth, nodeHeight) = NodePainter.calculateNodeBoxSize(randomId);

                            final newNodePosition = Point(
                                details.localPosition.dx - nodeWidth / 2, details.localPosition.dy - nodeHeight / 2);

                            nodes.add(Node(randomId, newNodePosition, _drawingNodeType));
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
                                  if (edges.containsKey(nodeFromWhichDragging)) {
                                    edges[nodeFromWhichDragging!]!.add(i); // TODO null safety 😬
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
                          var newX = node.position.x + details.delta.dx;
                          var newY = node.position.y + details.delta.dy;

                          final newNode = Node(nodes[nodeBeingDraggedIndex!].id, Point(newX, newY),
                              nodes[nodeBeingDraggedIndex!].type); // TODO update node
                          setState(() {
                            nodes[nodeBeingDraggedIndex!] = newNode;
                          });
                        }
                      },
                      onPanEnd: (details) {
                        nodeBeingDraggedIndex = null;
                      },
                      child: CustomPaint(
                        painter: GraphPainter(
                            nodes,
                            edges,
                            isInEdgeDrawingMode && draggingStartPoint != null && draggingEndPoint != null
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
