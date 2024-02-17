import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:poc/keyboard_shortcuts.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'graph_painter/node_painter.dart';
import 'graph_painter/graph_painter.dart';
import 'policy/policy.dart';
import 'menu_bar.dart';
import 'utils.dart';
import 'info_panels/edge_info_panel.dart';
import 'info_panels/tag_node_info_panel.dart';
import 'info_panels/boundary_node_info_panel.dart';
import 'info_panels/info_panel_positioner.dart';
import 'ui/custom_dialog.dart';
import 'ui/snackbar.dart';
import 'user_preferences.dart';

class CanvasView extends StatefulWidget {
  final List<Node> nodes;
  final List<Edge> edges;
  FocusNode focusNode;
  Preferences preferences;

  CanvasView({super.key, required this.nodes, required this.edges, required this.focusNode, required this.preferences});

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
  double canvasScale = 1.0;
  GraphObject? hoveredObject;
  GraphObject? selectedObject;

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

  bool isNodeHit(Node node, Offset position) {
    final nodeSize = NodePainter.calculateNodeSize(node, padding: widget.preferences.nodePadding);

    return node.position.dx < position.dx &&
        node.position.dx + nodeSize.width > position.dx &&
        node.position.dy < position.dy &&
        node.position.dy + nodeSize.height > position.dy;
  }

  bool isEdgeHit(Edge edge, Offset position) {
    if (!pathPerEdge.containsKey(edge)) {
      return false; // sanity check TODO
    }

    final path = pathPerEdge[edge]!;

    return isPointNearBezierPath(position, path);
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

  void handleCanvasPanning(Offset scrollDelta) {
    setState(() {
      canvasPosition -= scrollDelta / 1.5 / canvasScale;
    });
  }

  void zoomCanvas({bool zoomIn = true}) {
    const maxZoom = 50.0;
    const minZoom = 0.1;

    const delta = 0.125;
    final zoomFactor = zoomIn ? 1 + delta : 1 - delta;
    final newScale = canvasScale * zoomFactor;

    if (newScale >= maxZoom || newScale <= minZoom) {
      return;
    }

    final oldScale = canvasScale;

    setState(() {
      canvasScale = newScale;
    });

    final scaleChange = canvasScale - oldScale;

    final adjustedCursorPosition = (adjustPositionForCanvasTransform(cursorPosition) + canvasPosition) / oldScale; // NOTE ?
    final offsetX = -(adjustedCursorPosition.dx * scaleChange);
    final offsetY = -(adjustedCursorPosition.dy * scaleChange);

    setState(() {
      canvasPosition += Offset(offsetX, offsetY);
    });
  }

  void resetZoomAndPosition() {
    setState(() {
      canvasPosition = Offset(0, 0);
      canvasScale = 1.0;
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
        final siblingEdge = getSiblingEdge(edges, object as Edge);
        final edgesToRemove = siblingEdge != null ? [object, siblingEdge] : [object];
        setState(() {
          edges.removeWhere((edge) => edgesToRemove.contains(edge));
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
      if (isNodeHit(node, adjustPositionForCanvasTransform(cursorPosition))) {
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
      SnackbarGlobal.info(e.message);
    }
  }

  void createNode(Offset position, NodeType nodeType, {String? nameOrDescriptor}) {
    // TODO refactor (nameOrDescriptor 😬)
    final randomId = generateRandomString(4);

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

    final nodeSize = NodePainter.calculateNodeSize(newNode, padding: widget.preferences.nodePadding) * canvasScale;
    newNode.position = Offset(position.dx - nodeSize.width / 2, position.dy - nodeSize.height / 2);

    setState(() {
      nodes.add(newNode);
    });
  }

  void onTapUp(TapUpDetails details) {
    final position = adjustPositionForCanvasTransform(details.localPosition);

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
        showNewTagNodeDialog(position);
      } else {
        showNewBoundaryNodeDialog(position);
      }
    }
  }

  void showNewTagNodeDialog(Offset position) {
    CustomDialog.showInputDialog(context, title: 'Create new tag', hint: 'Enter tag name (optional)', acceptEmptyInput: true,
        onConfirm: (String inputText) {
      if (inputText.isEmpty) {
        createNode(position, NodeType.tag);
      } else {
        createNode(position, NodeType.tag, nameOrDescriptor: inputText);
      }
      stopNodeDrawing();
    });
  }

  void showNewBoundaryNodeDialog(Offset position) {
    CustomDialog.showInputDialog(context,
        title: 'Create new ${_drawingNodeType!.value} node',
        hint: 'Enter descriptor',
        onConfirm: (String inputText) {
          if (_drawingNodeType == NodeType.entry && entryNodeWithDescriptorExists(nodes, inputText) ||
              _drawingNodeType == NodeType.exit && exitNodeWithDescriptorExists(nodes, inputText)) {
            SnackbarGlobal.info('$_drawingNodeType node with descriptor $inputText already exists!');
          } else {
            createNode(position, _drawingNodeType!, nameOrDescriptor: inputText);
          }
          stopNodeDrawing();
        },
        isInputValid: (String inputText) =>
            inputText.isNotEmpty && _drawingNodeType == NodeType.entry && !entryNodeWithDescriptorExists(nodes, inputText) ||
            _drawingNodeType == NodeType.exit && !exitNodeWithDescriptorExists(nodes, inputText),
        errorMessage: '${_drawingNodeType!.value} node with this descriptor already exists!');
  }

  void onTapDown(TapDownDetails details) {
    final position = adjustPositionForCanvasTransform(details.localPosition);

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
    final position = adjustPositionForCanvasTransform(details.localPosition);
    updateDraggedNode(position);
  }

  void updateDraggedNode(Offset position) {
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
    final delta = Offset(details.delta.dx, details.delta.dy) / canvasScale;

    if (isInEdgeDrawingMode() || isInNodeCreationMode() || draggedNode == null) return; // TODO null handling

    var newX = draggedNode!.position.dx + delta.dx;
    var newY = draggedNode!.position.dy + delta.dy;

    setState(() {
      draggedNode!.position = Offset(newX, newY);
    });
  }

  Offset adjustPositionForCanvasTransform(Offset position) {
    Matrix4 inverseTransformation = Matrix4.identity()
      ..scale(canvasScale, canvasScale)
      ..translate(canvasPosition.dx, canvasPosition.dy)
      ..invert();

    vector.Vector3 transformedPositionVector = inverseTransformation.transform3(vector.Vector3(position.dx, position.dy, 0));
    return Offset(transformedPositionVector.x, transformedPositionVector.y);
  }

  (Offset, Offset)? getEdgeInProgress() {
    if (isInEdgeDrawingMode() && draggingStartPoint != null && draggingEndPoint != null) {
      return (draggingStartPoint!, draggingEndPoint!);
    }
    return null;
  }

  /*
  Returns `true` if any app shortcuts were detected & handled, `false` otherwise.
   */
  bool onKeyDown(RawKeyDownEvent event) {
    if (selectedObject != null) {
      if (KeyboardShortcutManager.isDeleteKeyPressed(RawKeyboard.instance)) {
        deleteObject(selectedObject!);
        return true;
      } else if (KeyboardShortcutManager.isDeselectKeyPressed(RawKeyboard.instance)) {
        setState(() {
          selectedObject = null;
        });
        return true;
      }
    }

    if (KeyboardShortcutManager.isCancelDrawingKeyPressed(RawKeyboard.instance)) {
      if (!isInSelectionMode()) {
        stopNodeDrawing();
        stopEdgeDrawing();
      }
      return true;
    }

    if (KeyboardShortcutManager.isMetaPressed(RawKeyboard.instance) && event.logicalKey == LogicalKeyboardKey.equal ||
        event.logicalKey == LogicalKeyboardKey.add ||
        event.logicalKey == LogicalKeyboardKey.numpadAdd) {
      zoomCanvas();
      return true;
    }

    if (KeyboardShortcutManager.isMetaPressed(RawKeyboard.instance) && event.logicalKey == LogicalKeyboardKey.minus ||
        event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
      zoomCanvas(zoomIn: false);
      return true;
    }

    if (KeyboardShortcutManager.isMetaPressed(RawKeyboard.instance) && event.logicalKey == LogicalKeyboardKey.digit0) {
      resetZoomAndPosition();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is! PointerScrollEvent) return;

          if (KeyboardShortcutManager.isScrollKeyPresseed(RawKeyboard.instance)) {
            zoomCanvas(zoomIn: pointerSignal.scrollDelta.dy < 0);
          } else {
            handleCanvasPanning(pointerSignal.scrollDelta);
          }
        },
        onPointerHover: (event) {
          // TODO this is currently terrible - all mouse movement updates states and rerenders everything 🙈
          setState(() {
            cursorPosition = event.localPosition;
          });

          if (isInEdgeDrawingMode()) {
            setState(() {
              draggingEndPoint = adjustPositionForCanvasTransform(cursorPosition);
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
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: darkBlue,
            child: Focus(
              focusNode: focusNode,
              autofocus: true,
              onKey: (FocusNode node, RawKeyEvent event) {
                if (event is! RawKeyDownEvent) {
                  return KeyEventResult.ignored;
                }
                final shortcutsHandled = onKeyDown(event);
                if (shortcutsHandled) {
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
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
                      getEdgeInProgress(),
                      (newPathPerEdge) => pathPerEdge = newPathPerEdge,
                      selectedObject,
                      canvasPosition,
                      canvasScale,
                      widget.preferences,
                    ),
                  )),
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
              onSelectionPress: enterSelectionMode,
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
        InfoPanelPositioner(
          child: EdgeInfoPanel(
              edge: selectedObject as Edge,
              siblingEdge: getSiblingEdge(edges, selectedObject as Edge),
              isOnlyEdgeTypeBetweenNodes: isOnlyEdgeTypeBetweenNodes(edges, selectedObject as Edge),
              deleteObject: deleteObject,
              changeEdgeType: (newEdgeType) {
                final siblingEdge = getSiblingEdge(edges, selectedObject as Edge);
                final edgesToModify = siblingEdge != null ? [selectedObject as Edge, siblingEdge] : [selectedObject as Edge];
                setState(() {
                  for (var edge in edgesToModify) {
                    edge.type = newEdgeType;
                  }
                });
              }),
        ),
      if (selectedObject is TagNode)
        InfoPanelPositioner(
            child: TagNodeInfoPanel(
          node: selectedObject as TagNode,
          nodes: nodes,
          deleteObject: deleteObject,
          editName: (newName) {
            // NOTE Could also replace emit new object and replace existing one?
            setState(() => (selectedObject as TagNode).name = newName);
          },
        )),
      if (selectedObject is BoundaryNode)
        InfoPanelPositioner(
            child: BoundaryNodeInfoPanel(
          node: selectedObject as BoundaryNode,
          nodes: nodes,
          deleteObject: deleteObject,
          editDescriptor: (newDescriptor) {
            // NOTE Could also replace emit new object and replace existing one?
            setState(() => (selectedObject as BoundaryNode).descriptor = newDescriptor);
          },
        )),
    ]);
  }
}
