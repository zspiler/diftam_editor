import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:D2SC_editor/keyboard_utils.dart';
import 'graph_painter/node_painter.dart';
import 'graph_painter/graph_painter.dart';
import 'package:D2SC_editor/d2sc_policy/lib/d2sc_policy.dart';
import 'tool_bar.dart';
import 'utils.dart';
import 'info_panels/edge_info_panel.dart';
import 'info_panels/tag_node_info_panel.dart';
import 'info_panels/boundary_node_info_panel.dart';
import 'ui/custom_dialog.dart';
import 'ui/snackbar.dart';
import 'preferences_manager.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'canvas.dart';
import 'dart:math';
import 'theme.dart';

class CanvasView extends StatefulWidget {
  final List<Node> nodes;
  final List<Edge> edges;
  final FocusNode focusNode;
  final Preferences preferences;

  const CanvasView({super.key, required this.nodes, required this.edges, required this.focusNode, required this.preferences});

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView> {
  var nodes = <Node>[];
  var edges = <Edge>[];
  var edgePaths = <Path>[];

  CanvasTransform canvasTransform = CanvasTransform();
  Offset cursorPosition = Offset.zero;

  Offset? draggingStartPoint;
  Offset? draggingEndPoint;
  Node? draggedNode;

  GraphObject? hoveredObject;
  GraphObject? selectedObject;

  Node? newEdgeSourceNode;
  EdgeType? _drawingEdgeType;
  NodeType? _drawingNodeType;

  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();

    nodes = widget.nodes;
    edges = widget.edges;
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

  void deleteSelectedObject() {
    if (selectedObject != null) {
      deleteObject(selectedObject!);
    }
  }

  void createEdge(Node sourceNode, Node targetNode, EdgeType edgeType) {
    final Edge newEdge;
    try {
      newEdge = Edge(sourceNode, targetNode, edgeType);
    } on ArgumentError catch (e) {
      SnackbarGlobal.info(e.message);
      return;
    }

    final validationErrors = Policy.validateEdges([...edges, newEdge]);
    if (validationErrors.isNotEmpty) {
      final message = validationErrors.join('\n');
      SnackbarGlobal.error(message);
    } else {
      edges.add(newEdge);
    }
  }

  void createNode(Offset position, NodeType nodeType, {required String labelOrDescriptor}) {
    final Node newNode = Node.fromType(nodeType, labelOrDescriptor);

    final nodeSize = NodePainter.calculateNodeSize(newNode, padding: widget.preferences.nodePadding) * canvasTransform.scale;
    newNode.position = Point(position.dx - nodeSize.width / 2, position.dy - nodeSize.height / 2);

    setState(() {
      nodes.add(newNode);
    });
  }

  // CANVAS ZOOM & PAN

  void panCanvas(Offset scrollDelta) {
    final adjustedScrollDelta = adjustPanningScrollDeltaForPlatforms(scrollDelta);
    final newOffset = canvasTransform.offset - adjustedScrollDelta / 1.5 / canvasTransform.scale;
    setState(() {
      canvasTransform = canvasTransform.copyWith(offset: newOffset);
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
    final newScale = canvasTransform.scale * zoomFactor;
    if (newScale >= maxZoom || newScale <= minZoom) {
      return;
    }

    final oldScale = canvasTransform.scale;

    setState(() {
      canvasTransform = canvasTransform.copyWith(scale: newScale);
    });

    final scaleChange = canvasTransform.scale - oldScale;

    final cursorOnCanvas = mapScreenPositionToCanvas(cursorPosition, canvasTransform);
    final adjustedCursor = (cursorOnCanvas + canvasTransform.offset) / oldScale;
    final offsetX = -(adjustedCursor.dx * scaleChange);
    final offsetY = -(adjustedCursor.dy * scaleChange);

    final newOffset = canvasTransform.offset + Offset(offsetX, offsetY);
    setState(() {
      canvasTransform = canvasTransform.copyWith(offset: newOffset);
    });
  }

  void resetZoomAndPosition() {
    setState(() {
      canvasTransform = CanvasTransform(offset: Offset.zero, scale: 1.0);
    });
  }

  // DIALOGS

  void showNewTagNodeDialog(Offset position) {
    CustomDialog.showInputDialog(
      context,
      title: 'Create new tag',
      hint: 'Enter tag label',
      onConfirm: (String inputText) {
        createNode(position, NodeType.tag, labelOrDescriptor: inputText);
        stopNodeDrawing();
      },
      isInputValid: (String inputText) => !nodes.any((node) => node is TagNode && node.label == inputText),
      errorMessage: 'Please choose a unique tag label',
    );
  }

  void showNewBoundaryNodeDialog(Offset position) {
    CustomDialog.showInputDialog(context,
        title: 'Create new ${_drawingNodeType!.value} node',
        hint: 'Enter descriptor',
        onConfirm: (String inputText) {
          createNode(position, _drawingNodeType!, labelOrDescriptor: inputText);
          stopNodeDrawing();
        },
        isInputValid: (String inputText) =>
            inputText.isNotEmpty && _drawingNodeType == NodeType.entry && !entryNodeWithDescriptorExists(nodes, inputText) ||
            _drawingNodeType == NodeType.exit && !exitNodeWithDescriptorExists(nodes, inputText),
        errorMessage: '${_drawingNodeType!.value} node with this descriptor already exists!');
  }

  // GESTURES

  void onPointerUp(PointerUpEvent event) {
    final position = mapScreenPositionToCanvas(event.localPosition, canvasTransform);

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

  void onPointerDown(PointerDownEvent event) {
    final position = mapScreenPositionToCanvas(event.localPosition, canvasTransform);
    final nodeAtCursor = getNodeAtPosition(position);

    if (!isInEdgeDrawingMode()) {
      // We use set draggedNode here of in onPanStart (which would be more natural) since that event works weirdly with
      // trackpad on desktop - it seems to be triggered on every trackpad change (without click).
      setState(() {
        draggedNode = nodeAtCursor;
      });
      return;
    }

    if (nodeAtCursor == null) {
      stopEdgeDrawing();
      return;
    }

    if (draggingStartPoint == null) {
      setState(() {
        draggingStartPoint = position;
        newEdgeSourceNode = nodeAtCursor;
      });
    } else {
      if (newEdgeSourceNode != null && _drawingEdgeType != null) {
        final equivalentEdgeExists =
            edges.any((edge) => edge.source == newEdgeSourceNode && edge.target == nodeAtCursor && edge.type == _drawingEdgeType);
        if (!equivalentEdgeExists) {
          createEdge(newEdgeSourceNode!, nodeAtCursor, _drawingEdgeType!);
        }
      }
      stopEdgeDrawing();
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (isInEdgeDrawingMode() || isInNodeCreationMode() || draggedNode == null) return;

    final delta = Offset(details.delta.dx, details.delta.dy) / canvasTransform.scale;
    var newX = draggedNode!.position.x + delta.dx;
    var newY = draggedNode!.position.y + delta.dy;

    setState(() {
      draggedNode!.position = Point(newX, newY);
    });
  }

  void onPointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    // NOTE Because onPointerSignal does not work for scroll event with trackpad on desktop (works ok on web),
    // we have to use this event which is only triggered on trackpad on desktop.
    // Hence, we also don't get intertial scrolling behavior when using trackpad on desktop and panning or zooming canvas.

    // https://docs.flutter.dev/release/breaking-changes/trackpad-gesturesk

    final delta = Offset(-event.panDelta.dx, -event.panDelta.dy);
    if (KeyboardUtils.isScrollModifierPresseed()) {
      zoomCanvas(zoomIn: delta.dy < 0);
    } else {
      panCanvas(delta);
    }
  }

  void onPointerHover(PointerHoverEvent event) {
    setState(() {
      cursorPosition = event.localPosition;
    });

    final position = mapScreenPositionToCanvas(cursorPosition, canvasTransform);
    if (isInEdgeDrawingMode()) {
      setState(() {
        draggingEndPoint = position;
      });
    } else if (isInSelectionMode()) {
      setState(() {
        hoveredObject = getNodeAtPosition(position) ?? getEdgeAtPosition(position);
      });
    }
  }

  void onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    if (KeyboardUtils.isScrollModifierPresseed()) {
      zoomCanvas(zoomIn: event.scrollDelta.dy < 0);
    } else {
      panCanvas(event.scrollDelta);
    }
  }

  // helpers

  (Offset, Offset)? getPreviewEdgePositions() {
    if (isInEdgeDrawingMode() && draggingStartPoint != null && draggingEndPoint != null) {
      return (draggingStartPoint!, draggingEndPoint!);
    }
    return null;
  }

  void moveNodes(Offset offset) {
    setState(() {
      for (var node in nodes) {
        node.position = Point(node.position.x + offset.dx, node.position.y + offset.dy);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Listener(
        onPointerSignal: onPointerSignal,
        onPointerPanZoomUpdate: onPointerPanZoomUpdate,
        onPointerHover: onPointerHover,
        onPointerDown: onPointerDown,
        onPointerUp: onPointerUp,
        child: MouseRegion(
          cursor: hoveredObject != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: darkBlue,
            child: CallbackShortcuts(
              bindings: {
                SingleActivator(LogicalKeyboardKey.delete): deleteSelectedObject,
                SingleActivator(LogicalKeyboardKey.backspace): deleteSelectedObject,
                SingleActivator(LogicalKeyboardKey.escape): () {
                  selectedObject = null;
                  stopNodeDrawing();
                  stopEdgeDrawing();
                },
                SingleActivator(LogicalKeyboardKey.equal, meta: true): zoomCanvas,
                SingleActivator(LogicalKeyboardKey.add, meta: true): zoomCanvas,
                SingleActivator(LogicalKeyboardKey.minus, meta: true): () => zoomCanvas(zoomIn: false),
                SingleActivator(LogicalKeyboardKey.digit0, meta: true): resetZoomAndPosition,
                SingleActivator(LogicalKeyboardKey.arrowUp): () => moveNodes(Offset(0, -gridSize)),
                SingleActivator(LogicalKeyboardKey.arrowDown): () => moveNodes(Offset(0, gridSize)),
                SingleActivator(LogicalKeyboardKey.arrowLeft): () => moveNodes(Offset(-gridSize, 0)),
                SingleActivator(LogicalKeyboardKey.arrowRight): () => moveNodes(Offset(gridSize, 0)),
              },
              child: Focus(
                focusNode: focusNode,
                autofocus: true,
                child: GestureDetector(
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
                          canvasTransform,
                          widget.preferences,
                        ),
                      ),
                    )),
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
          child: ToolBar(
              onSelectionPress: enterSelectionMode,
              onAwareConnectionPress: () => enterEdgeDrawingMode(EdgeType.aware),
              onObliviousConnectionPress: () => enterEdgeDrawingMode(EdgeType.oblivious),
              onBoundaryConnectionPress: () => enterEdgeDrawingMode(EdgeType.boundary),
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
          editLabel: (newLabel) {
            setState(() => (selectedObject as TagNode).label = newLabel);
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
