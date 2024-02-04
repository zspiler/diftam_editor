import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:poc/keyboard_shortcuts.dart';

import 'package:vector_math/vector_math_64.dart' as vector;

import 'node_painter.dart';
import 'graph_painter.dart';
import 'common.dart';
import 'menu_bar.dart';
import 'utils.dart';
import 'ui/edge_info_panel.dart';
import 'ui/tag_node_info_panel.dart';
import 'ui/boundary_node_info_panel.dart';
import 'ui/custom_dialog.dart';
import 'ui/snackbar.dart';

class CanvasView extends StatefulWidget {
  final List<Node> nodes;
  final List<Edge> edges;
  FocusNode focusNode;

  CanvasView({super.key, required this.nodes, required this.edges, required this.focusNode});

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

const darkBlue = Color.fromARGB(255, 20, 54, 91);

class _CanvasViewState extends State<CanvasView> {
  var nodes = <Node>[];
  var edges = <Edge>[];
  var pathPerEdge = <Edge, Path>{};

  Offset? draggingStartPoint;
  Offset? draggingEndPoint;
  Node? draggedNode;
  Node? newEdgeSourceNode;
  Offset cursorPosition = Offset.zero;
  Offset canvasPosition = Offset.zero;
  GraphObject? hoveredObject;
  GraphObject? selectedObject;

  double scale = 1.0;

  EdgeType? _drawingEdgeType; // TODO private?
  NodeType? _drawingNodeType; // TODO private?

  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();

    nodes = List.from(widget.nodes);
    edges = List.from(widget.edges);
    focusNode = widget.focusNode;
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
    final (nodeWidth, nodeHeight) = NodePainter.calculateNodeBoxSize(node);

    return node.position.dx < offset.dx &&
        node.position.dx + nodeWidth > offset.dx &&
        node.position.dy < offset.dy &&
        node.position.dy + nodeHeight > offset.dy;
  }

  bool isEdgeHit(Edge edge, Offset position) {
    if (!pathPerEdge.containsKey(edge)) {
      return false; // sanity check TODO
    }

    final path = pathPerEdge[edge]!;

    return Utils.isPointNearBezierPath(position, path);
  }

  void stopEdgeDrawing() {
    setState(() {
      newEdgeSourceNode = null;
      draggingStartPoint = null;
      draggingEndPoint = null;
      _drawingEdgeType = null;
    });
  }

  void stopNodeDrawing() {
    setState(() {
      _drawingNodeType = null;
    });
  }

  void handlePanning(Offset scrollDelta) {
    setState(() {
      canvasPosition -= scrollDelta / 1.5;
    });
  }

  void zoom({bool zoomIn = true}) {
    final oldScale = scale;

    final zoomFactor = zoomIn ? 1.1 : 0.9;

    setState(() {
      scale *= zoomFactor;
    });

    final scaleChange = scale - oldScale;

    final offsetX = -(cursorPosition.dx * scaleChange);
    final offsetY = -(cursorPosition.dy * scaleChange);

    setState(() {
      canvasPosition += Offset(offsetX, offsetY);
    });
  }

  void resetZoomAndPosition() {
    setState(() {
      canvasPosition = Offset(0, 0);
      scale = 1.0;
    });
  }

  void enterSelectionMode() {
    stopEdgeDrawing();
    stopNodeDrawing();
  }

  void enterEdgeDrawingMode(EdgeType edgeType) {
    stopNodeDrawing();
    setState(() {
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
        stopNodeDrawing();
      }
    });
  }

  void deleteObject(GraphObject object) {
    CustomDialog.showConfirmationDialog(context,
        confirmButtonText: 'Delete', title: 'Are you sure you want to delete this object?', onConfirm: () {
      if (object is Node) {
        setState(() {
          nodes.remove(object);
          edges.removeWhere((edge) => edge.source == object || edge.target == object);
        });
      } else {
        setState(() {
          edges.remove(object);
        });
      }
      if (selectedObject == object) {
        setState(() {
          selectedObject = null;
        });
      }
    });
  }

  GraphObject? getObjectAtCursor() {
    for (var node in nodes) {
      if (isNodeHit(node, cursorPosition)) {
        return node;
      }
    }

    for (var edge in edges) {
      if (isEdgeHit(edge, cursorPosition)) {
        return edge;
      }
    }
    return null;
  }

  void createEdge(Node sourceNode, Node targetNode, EdgeType edgeType) {
    try {
      final newEdge = Edge(sourceNode, targetNode, edgeType);
      final edgeExists =
          edges.any((edge) => edge.source == newEdge.source && edge.target == newEdge.target && edge.type == newEdge.type);
      if (!edgeExists) {
        setState(() {
          edges.add(newEdge);
        });
      }
    } on ArgumentError catch (e) {
      SnackbarGlobal.show(e.message);
    }
  }

  void createNode(Offset position, NodeType nodeType, {String? nameOrDescriptor}) {
    // TODO refactor (nameOrDescriptor 😬)
    final randomId = Utils.generateRandomString(4);

    final tempPosition = Offset(0, 0);
    late final Node newNode;
    if (nodeType == NodeType.tag) {
      newNode = TagNode(tempPosition, randomId, nameOrDescriptor);
    } else {
      if (nodeType == NodeType.entry) {
        newNode = EntryNode(tempPosition, nameOrDescriptor!);
      } else {
        newNode = ExitNode(tempPosition, nameOrDescriptor!);
      }
    }

    final (nodeWidth, nodeHeight) = NodePainter.calculateNodeBoxSize(newNode);
    newNode.position = Offset(position.dx - nodeWidth / 2, position.dy - nodeHeight / 2);

    setState(() {
      nodes.add(newNode);
    });
  }

  bool entryNodeWithDescriptorExists(String descriptor) {
    return nodes.any((node) => node is EntryNode && node.descriptor == descriptor);
  }

  bool exitNodeWithDescriptorExists(String descriptor) {
    return nodes.any((node) => node is ExitNode && node.descriptor == descriptor);
  }

  void onTapUp(TapUpDetails details) {
    final position = details.localPosition;

    if (isInSelectionMode()) {
      setState(() {
        selectedObject = hoveredObject;
      });
    } else if (isInNodeCreationMode()) {
      if (_drawingNodeType == null) {
        // TODO
        return;
      }
      if (_drawingNodeType == NodeType.tag) {
        CustomDialog.showInputDialog(context, title: 'Create new tag', hint: 'Enter tag name (optional)', acceptEmptyInput: true,
            onConfirm: (String inputText) {
          if (inputText.isEmpty) {
            createNode(position, NodeType.tag);
          } else {
            createNode(position, NodeType.tag, nameOrDescriptor: inputText);
          }
          stopNodeDrawing();
        });
      } else {
        CustomDialog.showInputDialog(context,
            title: 'Create new ${_drawingNodeType!.value} node',
            hint: 'Enter descriptor',
            onConfirm: (String inputText) {
              if (_drawingNodeType == NodeType.entry && entryNodeWithDescriptorExists(inputText) ||
                  _drawingNodeType == NodeType.exit && exitNodeWithDescriptorExists(inputText)) {
                SnackbarGlobal.show('$_drawingNodeType node with descriptor $inputText already exists!');
              } else {
                createNode(position, _drawingNodeType!, nameOrDescriptor: inputText);
              }
              stopNodeDrawing();
            },
            isInputValid: (String inputText) =>
                inputText.isNotEmpty && _drawingNodeType == NodeType.entry && !entryNodeWithDescriptorExists(inputText) ||
                _drawingNodeType == NodeType.exit && !exitNodeWithDescriptorExists(inputText),
            errorMessage: '${_drawingNodeType!.value} node with this descriptor already exists!');
      }
    }
  }

  void onTapDown(TapDownDetails details) {
    final position = details.localPosition;

    if (isInEdgeDrawingMode()) {
      for (var node in nodes) {
        if (isNodeHit(node, position)) {
          if (draggingStartPoint == null) {
            // NOTE probably dont need here since its called on hover but ok
            setState(() {
              draggingStartPoint = position;
              newEdgeSourceNode = node;
            });
          } else {
            if (newEdgeSourceNode != null && _drawingEdgeType != null) {
              createEdge(newEdgeSourceNode!, node, _drawingEdgeType!);
            }
            stopEdgeDrawing();
          }
          return;
        }
      }
      stopEdgeDrawing();
    }
  }

  void onPanStart(DragStartDetails details) {
    final position = details.localPosition;

    if (isInEdgeDrawingMode() || isInNodeCreationMode()) return;
    for (var node in nodes) {
      if (isNodeHit(node, position)) {
        setState(() {
          draggedNode = node;
        });
        break;
      }
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    final delta = details.delta;

    if (isInEdgeDrawingMode() || isInNodeCreationMode() || draggedNode == null) return; // TODO null handling

    var newX = draggedNode!.position.dx + delta.dx;
    var newY = draggedNode!.position.dy + delta.dy;

    final canvasWidth = MediaQuery.of(context).size.width;
    final canvasHeight = MediaQuery.of(context).size.height;

    final (nodeWidth, nodeHeight) = NodePainter.calculateNodeBoxSize(draggedNode!);

    final isNewPositionInvalid = newX < 0 && newX + nodeWidth > canvasWidth && newY < 0 && newY + nodeHeight > canvasHeight;
    if (isNewPositionInvalid) {
      return;
    }

    setState(() {
      draggedNode!.position = Offset(newX, newY);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is! PointerScrollEvent) return;

          if (KeyboardShortcutManager.isScrollKeyPresseed(RawKeyboard.instance)) {
            zoom(zoomIn: pointerSignal.scrollDelta.dy < 0);
          } else {
            handlePanning(pointerSignal.scrollDelta);
          }

          // TODO: Fix trackpad!
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
              hoveredObject = getObjectAtCursor();
            });
          }
        },
        child: MouseRegion(
          cursor: hoveredObject != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Container(
            color: Color.fromARGB(255, 219, 219, 219),
            child: ClipRect(
              child: Transform(
                transform: Matrix4.identity()
                  ..translate(canvasPosition.dx, canvasPosition.dy)
                  ..scale(scale, scale),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: darkBlue,
                  child: KeyboardListener(
                    focusNode: focusNode,
                    autofocus: true,
                    onKeyEvent: (event) {
                      if (event is! KeyDownEvent) {
                        return;
                      }

                      if (selectedObject != null) {
                        if (KeyboardShortcutManager.isDeleteKeyPressed(RawKeyboard.instance)) {
                          deleteObject(selectedObject!);
                        } else if (KeyboardShortcutManager.isDeselectKeyPressed(RawKeyboard.instance)) {
                          setState(() {
                            selectedObject = null;
                          });
                        }
                      }

                      if (!isInSelectionMode()) {
                        if (KeyboardShortcutManager.isCancelDrawingKeyPressed(RawKeyboard.instance)) {
                          stopNodeDrawing();
                          stopEdgeDrawing();
                        }
                      }

                      if (KeyboardShortcutManager.isMetaPressed(RawKeyboard.instance) &&
                              event.logicalKey == LogicalKeyboardKey.equal ||
                          event.logicalKey == LogicalKeyboardKey.add ||
                          event.logicalKey == LogicalKeyboardKey.numpadAdd) {
                        zoom();
                      }

                      if (KeyboardShortcutManager.isMetaPressed(RawKeyboard.instance) &&
                              event.logicalKey == LogicalKeyboardKey.minus ||
                          event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
                        zoom(zoomIn: false);
                      }

                      if (KeyboardShortcutManager.isMetaPressed(RawKeyboard.instance) &&
                          event.logicalKey == LogicalKeyboardKey.digit0) {
                        resetZoomAndPosition();
                      }
                    },
                    child: GestureDetector(
                        onTapUp: onTapUp,
                        onTapDown: onTapDown,
                        onPanStart: onPanStart,
                        onPanUpdate: onPanUpdate,
                        onPanEnd: (details) {
                          draggedNode = null;
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
      ),
      Positioned(
        top: 16,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.topCenter,
          child: MyMenuBar(
              onSelectionPress: () => enterSelectionMode(),
              onAwareConnectionPress: () => enterEdgeDrawingMode(EdgeType.aware),
              onObliviousConnectionPress: () => enterEdgeDrawingMode(EdgeType.oblivious),
              onEntryNodePress: () => enterNodeDrawingMode(NodeType.entry),
              onExitNodePress: () => enterNodeDrawingMode(NodeType.exit),
              onTagNodePress: () => enterNodeDrawingMode(NodeType.tag),
              drawingEdgeType: _drawingEdgeType,
              drawingNodeType: _drawingNodeType,
              isInSelectionMode: isInSelectionMode()),
        ),
      ),
      if (selectedObject is Edge)
        Positioned(
          top: 0,
          bottom: 0,
          right: 16,
          child: Align(
              alignment: Alignment.centerRight,
              child: EdgeInfoPanel(
                  edge: selectedObject as Edge,
                  deleteObject: deleteObject,
                  changeEdgeType: (newEdgeType) {
                    setState(() {
                      (selectedObject as Edge).type = newEdgeType;
                    });
                  })),
        ),
      if (selectedObject is TagNode)
        // TODO reuse panel + positions
        Positioned(
            top: 0,
            bottom: 0,
            right: 16,
            child: Align(
                alignment: Alignment.centerRight,
                child: TagNodeInfoPanel(
                  node: selectedObject as TagNode,
                  deleteObject: deleteObject,
                  editLabel: () {
                    CustomDialog.showInputDialog(
                      context,
                      title: 'Edit label',
                      hint: 'Enter new label',
                      acceptEmptyInput: true,
                      initialText: (selectedObject as TagNode).name,
                      onConfirm: (String inputText) {
                        setState(() {
                          (selectedObject as TagNode).name = inputText.isNotEmpty ? inputText : null;
                        });
                      },
                      isInputValid: (String inputText) =>
                          !nodes.any((node) => node != selectedObject && node is TagNode && node.name == inputText),
                      errorMessage: 'Please choose a unique tag label',
                    );
                  },
                ))),
      if (selectedObject is BoundaryNode)
        Positioned(
            top: 0,
            bottom: 0,
            right: 16,
            child: Align(
                alignment: Alignment.centerRight,
                child: BoundaryNodeInfoPanel(
                  node: selectedObject as BoundaryNode,
                  deleteObject: deleteObject,
                  editDescriptor: () {
                    CustomDialog.showInputDialog(context,
                        title: 'Edit descriptor',
                        hint: 'Enter new descriptor',
                        initialText: (selectedObject as BoundaryNode).descriptor,
                        onConfirm: (String inputText) {
                          setState(() {
                            (selectedObject as BoundaryNode).descriptor = inputText;
                          });
                        },
                        isInputValid: (String inputText) =>
                            inputText.isNotEmpty && selectedObject is EntryNode && !entryNodeWithDescriptorExists(inputText) ||
                            selectedObject is ExitNode && !exitNodeWithDescriptorExists(inputText),
                        errorMessage:
                            '${selectedObject is EntryNode ? 'Entry' : 'Exit'} node with this descriptor already exists!');
                  },
                ))),
    ]);
  }
}
