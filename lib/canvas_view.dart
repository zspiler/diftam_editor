import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:poc/keyboard_shortcuts.dart';
import 'graph_painter/node_painter.dart';
import 'graph_painter/graph_painter.dart';
import 'policy/policy.dart';
import 'menu_bar.dart';
import 'utils.dart';
import 'info_panels/edge_info_panel.dart';
import 'info_panels/tag_node_info_panel.dart';
import 'info_panels/boundary_node_info_panel.dart';
import 'ui/custom_dialog.dart';
import 'ui/snackbar.dart';
import 'preferences_manager.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  var edgePaths = <Path>[];

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

  Edge? getEdgeAtPosition(Offset position) {
    return firstOrNull(edges, ((edge) {
      final edgePath = edgePaths[edges.indexOf(edge)];
      return isPointNearBezierPath(position, edgePath);
    }));
  }

  Node? getNodeAtPosition(Offset position) {
    return firstOrNull(nodes, ((node) => isNodeHit(node, position, widget.preferences.nodePadding)));
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

  void enterSelectionMode() {
    stopEdgeDrawing();
    stopNodeDrawing();
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

  // CANVAS ZOOM & PAN

  void panCanvas(Offset scrollDelta) {
    final adjustedScrollDelta = adjustPanningScrollDeltaForPlatforms(scrollDelta);
    setState(() {
      canvasPosition -= adjustedScrollDelta / 1.5 / canvasScale;
    });
  }

  Offset adjustPanningScrollDeltaForPlatforms(Offset scrollDelta) {
    if (KeyboardUtils.isShiftPressed() && Platform.isMacOS && !kIsWeb) {
      return Offset(scrollDelta.dy, 0);
    }

    return scrollDelta;
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

    final adjustedCursorPosition =
        (adjustPositionForCanvasTransform(cursorPosition, canvasPosition, canvasScale) + canvasPosition) / oldScale; // NOTE ?
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

  // DIALOGS

  void showNewTagNodeDialog(Offset position) {
    CustomDialog.showInputDialog(context, title: 'Create new tag', hint: 'Enter tag name (optional)', acceptEmptyInput: true,
        onConfirm: (String inputText) {
      createNode(position, NodeType.tag, nameOrDescriptor: inputText.isEmpty ? null : inputText);
      stopNodeDrawing();
    });
  }

  void showNewBoundaryNodeDialog(Offset position) {
    CustomDialog.showInputDialog(context,
        title: 'Create new ${_drawingNodeType!.value} node',
        hint: 'Enter descriptor',
        onConfirm: (String inputText) {
          createNode(position, _drawingNodeType!, nameOrDescriptor: inputText);
          stopNodeDrawing();
        },
        isInputValid: (String inputText) =>
            inputText.isNotEmpty && _drawingNodeType == NodeType.entry && !entryNodeWithDescriptorExists(nodes, inputText) ||
            _drawingNodeType == NodeType.exit && !exitNodeWithDescriptorExists(nodes, inputText),
        errorMessage: '${_drawingNodeType!.value} node with this descriptor already exists!');
  }

  // GESTURES

  void onTapUp(TapUpDetails details) {
    final position = adjustPositionForCanvasTransform(details.localPosition, canvasPosition, canvasScale);

    if (isInSelectionMode()) {
      setState(() {
        selectedObject = hoveredObject;
      });
    } else if (isInNodeCreationMode()) {
      if (_drawingNodeType == NodeType.tag) {
        showNewTagNodeDialog(position);
      } else if (_drawingNodeType != null) {
        showNewBoundaryNodeDialog(position);
      }
    }
  }

  void onTapDown(TapDownDetails details) {
    if (!isInEdgeDrawingMode()) {
      return;
    }

    final adjustedCursorPosition = adjustPositionForCanvasTransform(details.localPosition, canvasPosition, canvasScale);

    final nodeAtCursor = getNodeAtPosition(adjustedCursorPosition);
    if (nodeAtCursor == null) {
      stopEdgeDrawing();
      return;
    }

    if (draggingStartPoint == null) {
      setState(() {
        draggingStartPoint = adjustedCursorPosition;
        newEdgeSourceNode = nodeAtCursor;
      });
    } else {
      if (newEdgeSourceNode != null && _drawingEdgeType != null) {
        createEdge(newEdgeSourceNode!, nodeAtCursor, _drawingEdgeType!);
      }
      stopEdgeDrawing();
    }
  }

  void onPanStart(DragStartDetails details) {
    if (isInEdgeDrawingMode() || isInNodeCreationMode()) return;

    final position = adjustPositionForCanvasTransform(details.localPosition, canvasPosition, canvasScale);
    final node = getNodeAtPosition(position);
    if (node != null) {
      setState(() {
        draggedNode = node;
      });
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (isInEdgeDrawingMode() || isInNodeCreationMode() || draggedNode == null) return;

    final delta = Offset(details.delta.dx, details.delta.dy) / canvasScale;
    var newX = draggedNode!.position.dx + delta.dx;
    var newY = draggedNode!.position.dy + delta.dy;

    setState(() {
      draggedNode!.position = Offset(newX, newY);
    });
  }

  (Offset, Offset)? getPreviewEdgePositions() {
    if (isInEdgeDrawingMode() && draggingStartPoint != null && draggingEndPoint != null) {
      return (draggingStartPoint!, draggingEndPoint!);
    }
    return null;
  }

  // KEYBOARD SHORTCUTS

  /*
  Returns `true` if any app shortcuts were detected & handled, `false` otherwise.
   */
  bool onKeyDown(RawKeyDownEvent event) {
    if (handleSelectionShortcuts(event)) return true;
    if (handleZoomShortcuts(event)) return true;
    return false;
  }

  bool handleZoomShortcuts(RawKeyDownEvent event) {
    if (KeyboardUtils.isMetaPressed() && event.logicalKey == LogicalKeyboardKey.equal ||
        event.logicalKey == LogicalKeyboardKey.add ||
        event.logicalKey == LogicalKeyboardKey.numpadAdd) {
      zoomCanvas();
      return true;
    }

    if (KeyboardUtils.isMetaPressed() && event.logicalKey == LogicalKeyboardKey.minus ||
        event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
      zoomCanvas(zoomIn: false);
      return true;
    }

    if (KeyboardUtils.isMetaPressed() && event.logicalKey == LogicalKeyboardKey.digit0) {
      resetZoomAndPosition();
      return true;
    }

    return false;
  }

  bool handleSelectionShortcuts(RawKeyDownEvent event) {
    if (selectedObject != null) {
      if (KeyboardUtils.isDeletePressed()) {
        deleteObject(selectedObject!);
        return true;
      }
      if (KeyboardUtils.isEscapePressed()) {
        setState(() {
          selectedObject = null;
        });
        return true;
      }
    }

    if (KeyboardUtils.isEscapePressed()) {
      if (!isInSelectionMode()) {
        stopNodeDrawing();
        stopEdgeDrawing();
      }
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

          if (KeyboardUtils.isScrollModifierPresseed()) {
            zoomCanvas(zoomIn: pointerSignal.scrollDelta.dy < 0);
          } else {
            panCanvas(pointerSignal.scrollDelta);
          }
        },
        onPointerHover: (event) {
          setState(() {
            cursorPosition = event.localPosition;
          });

          final adjustedCursorPosition = adjustPositionForCanvasTransform(cursorPosition, canvasPosition, canvasScale);
          if (isInEdgeDrawingMode()) {
            setState(() {
              draggingEndPoint = adjustedCursorPosition;
            });
          } else if (isInSelectionMode()) {
            setState(() {
              hoveredObject = getNodeAtPosition(adjustedCursorPosition) ?? getEdgeAtPosition(cursorPosition);
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
                if (event is! RawKeyDownEvent || !onKeyDown(event)) {
                  return KeyEventResult.ignored;
                }

                return KeyEventResult.handled;
              },
              child: GestureDetector(
                  onTapUp: onTapUp,
                  onTapDown: onTapDown,
                  onPanStart: onPanStart,
                  onPanUpdate: onPanUpdate,
                  onPanEnd: (details) {
                    draggedNode = null;
                  },
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: GraphPainter(
                        nodes,
                        edges,
                        getPreviewEdgePositions(),
                        (newEdgePaths) => edgePaths = newEdgePaths,
                        selectedObject,
                        canvasPosition,
                        canvasScale,
                        widget.preferences,
                      ),
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
        EdgeInfoPanel(
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
      if (selectedObject is TagNode)
        TagNodeInfoPanel(
          node: selectedObject as TagNode,
          nodes: nodes,
          deleteObject: deleteObject,
          editName: (newName) {
            setState(() => (selectedObject as TagNode).name = newName);
          },
        ),
      if (selectedObject is BoundaryNode)
        BoundaryNodeInfoPanel(
          node: selectedObject as BoundaryNode,
          nodes: nodes,
          deleteObject: deleteObject,
          editDescriptor: (newDescriptor) {
            setState(() => (selectedObject as BoundaryNode).descriptor = newDescriptor);
          },
        ),
    ]);
  }
}
