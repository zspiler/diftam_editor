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
import 'main.dart'; // TODO rm
import 'package:provider/provider.dart';

class CanvasView extends StatefulWidget {
  const CanvasView({
    super.key,
  });

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

const darkBlue = Color.fromARGB(255, 20, 54, 91);

class _CanvasViewState extends State<CanvasView> {
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  bool isNodeHit(Node node, Offset offset) {
    final (nodeWidth, nodeHeight) = NodePainter.calculateNodeBoxSize(node);

    return node.position.dx < offset.dx &&
        node.position.dx + nodeWidth > offset.dx &&
        node.position.dy < offset.dy &&
        node.position.dy + nodeHeight > offset.dy;
  }

  void handlePanning(Offset scrollDelta) {
    // TODO ugly :(
    final appState = Provider.of<MyAppState>(context, listen: false); // NOTE listen: false?

    final newCanvasPosition = appState.canvasPosition -= scrollDelta / 1.5;
    appState.setCanvasPosition(newCanvasPosition);
  }

  void zoom({bool zoomIn = true}) {
    // TODO ugly :(
    final appState = Provider.of<MyAppState>(context, listen: false); // NOTE listen: false?

    final oldScale = appState.scale;

    final zoomFactor = zoomIn ? 1.1 : 0.9;

    appState.setScale(appState.scale *= zoomFactor);

    final scaleChange = appState.scale - oldScale;

    final offsetX = -(appState.cursorPosition.dx * scaleChange);
    final offsetY = -(appState.cursorPosition.dy * scaleChange);

    final newCanvasPosition = appState.canvasPosition + Offset(offsetX, offsetY);
    appState.setCanvasPosition(newCanvasPosition);
  }

  void showDeleteObjectDialog() {
    CustomDialog.showConfirmationDialog(context,
        confirmButtonText: 'Delete', title: 'Are you sure you want to delete this object?', onConfirm: () {
      final appState = context.watch<MyAppState>();
      appState.deleteSelectedObject();
    });
  }

  // TODO how to access state outside build? 😬 Riverpod?
  void onTapUp(TapUpDetails details) {
    // TODO ugly :(
    final appState = Provider.of<MyAppState>(context, listen: false); // NOTE listen: false?

    final position = details.localPosition;

    if (appState.isInSelectionMode()) {
      appState.setSelectedObject(appState.hoveredObject);
    } else if (appState.isInNodeCreationMode()) {
      if (appState.drawingNodeType == null) {
        // TODO
        return;
      }
      if (appState.drawingNodeType == NodeType.tag) {
        CustomDialog.showInputDialog(context, title: 'Create new tag', hint: 'Enter tag name (optional)', acceptEmptyInput: true,
            onConfirm: (String inputText) {
          if (inputText.isEmpty) {
            appState.createNode(position, NodeType.tag);
          } else {
            appState.createNode(position, NodeType.tag, nameOrDescriptor: inputText);
          }
          appState.stopNodeDrawing();
        });
      } else {
        CustomDialog.showInputDialog(context,
            title: 'Create new ${appState.drawingNodeType!.value} node',
            hint: 'Enter descriptor',
            onConfirm: (String inputText) {
              if (appState.drawingNodeType == NodeType.entry && appState.entryNodeWithDescriptorExists(inputText) ||
                  appState.drawingNodeType == NodeType.exit && appState.exitNodeWithDescriptorExists(inputText)) {
                SnackbarGlobal.show('$appState.drawingNodeType node with descriptor $inputText already exists!');
              } else {
                appState.createNode(position, appState.drawingNodeType!, nameOrDescriptor: inputText);
              }
              appState.stopNodeDrawing();
            },
            isInputValid: (String inputText) =>
                inputText.isNotEmpty &&
                    appState.drawingNodeType == NodeType.entry &&
                    !appState.entryNodeWithDescriptorExists(inputText) ||
                appState.drawingNodeType == NodeType.exit && !appState.exitNodeWithDescriptorExists(inputText),
            errorMessage: '${appState.drawingNodeType!.value} node with this descriptor already exists!');
      }
    }
  }

  void onTapDown(TapDownDetails details) {
    // TODO ugly :(
    final appState = Provider.of<MyAppState>(context, listen: false); // NOTE listen: false?

    final position = details.localPosition;

    if (appState.isInEdgeDrawingMode()) {
      for (var node in appState.nodes) {
        if (isNodeHit(node, position)) {
          if (appState.draggingStartPoint == null) {
            // NOTE probably dont need here since its called on hover but ok

            appState.setDraggingStartPoint(position);
            appState.setNewEdgeSourceNode(node);
          } else {
            if (appState.newEdgeSourceNode != null && appState.drawingEdgeType != null) {
              appState.createEdge(appState.newEdgeSourceNode!, node, appState.drawingEdgeType!);
            }
            appState.stopEdgeDrawing();
          }
          return;
        }
      }
      appState.stopEdgeDrawing();
    }
  }

  void onPanStart(DragStartDetails details) {
    // TODO ugly :(
    final appState = Provider.of<MyAppState>(context, listen: false); // NOTE listen: false?

    final position = details.localPosition;

    if (appState.isInEdgeDrawingMode() || appState.isInNodeCreationMode()) return;
    for (var node in appState.nodes) {
      if (isNodeHit(node, position)) {
        appState.setDraggedNode(node);
        break;
      }
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    // TODO ugly :(
    final appState = Provider.of<MyAppState>(context, listen: false); // NOTE listen: false?

    final delta = details.delta;

    if (appState.isInEdgeDrawingMode() || appState.isInNodeCreationMode() || appState.draggedNode == null)
      return; // TODO null handling

    var newX = appState.draggedNode!.position.dx + delta.dx;
    var newY = appState.draggedNode!.position.dy + delta.dy;

    final canvasWidth = MediaQuery.of(context).size.width;
    final canvasHeight = MediaQuery.of(context).size.height;

    final (nodeWidth, nodeHeight) = NodePainter.calculateNodeBoxSize(appState.draggedNode!);

    final isNewPositionInvalid = newX < 0 && newX + nodeWidth > canvasWidth && newY < 0 && newY + nodeHeight > canvasHeight;
    if (isNewPositionInvalid) {
      return;
    }

    appState.draggedNode!.position = Offset(newX, newY); // TODO Mutating directly???
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>(); // TODO rename to store?

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

          /*
                Because Listener is outside Transformation (since we want to scroll etc. even outside original canvas area). 
                here the coordinates do not match transformd coordinates so we need to apply inverse transformation.
               */
          Matrix4 inverseTransformation = Matrix4.identity()
            ..translate(appState.canvasPosition.dx, appState.canvasPosition.dy)
            ..scale(appState.scale, appState.scale)
            ..invert();

          vector.Vector3 transformedPositionVector =
              inverseTransformation.transform3(vector.Vector3(event.localPosition.dx, event.localPosition.dy, 0));

          appState.setCursorPosition(Offset(transformedPositionVector.x, transformedPositionVector.y));

          if (appState.isInEdgeDrawingMode()) {
            appState.setDraggingEndPoint(appState.cursorPosition);
          } else if (appState.isInSelectionMode()) {
            appState.setHoveredObject(appState.getObjectAtCursor());
          }
        },
        child: MouseRegion(
          cursor: appState.hoveredObject != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Container(
            color: Color.fromARGB(255, 219, 219, 219),
            child: ClipRect(
              child: Transform(
                transform: Matrix4.identity()
                  ..translate(appState.canvasPosition.dx, appState.canvasPosition.dy)
                  ..scale(appState.scale, appState.scale),
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

                      if (appState.selectedObject != null) {
                        if (KeyboardShortcutManager.isDeleteKeyPressed(RawKeyboard.instance)) {
                          showDeleteObjectDialog();
                        } else if (KeyboardShortcutManager.isDeselectKeyPressed(RawKeyboard.instance)) {
                          appState.setSelectedObject(null);
                        }
                      }

                      if (!appState.isInSelectionMode()) {
                        if (KeyboardShortcutManager.isCancelDrawingKeyPressed(RawKeyboard.instance)) {
                          appState.stopNodeDrawing();
                          appState.stopEdgeDrawing();
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
                        appState.resetZoomAndPosition();
                      }
                    },
                    child: GestureDetector(
                        // onTapUp: onTapUp,
                        // onTapDown: onTapDown,
                        // onPanStart: onPanStart,
                        // onPanUpdate: onPanUpdate,
                        onPanEnd: (details) {
                          appState.draggedNode = null;
                        },
                        child: CustomPaint(
                          painter: GraphPainter(
                            appState.nodes,
                            appState.edges,
                            appState.isInEdgeDrawingMode() &&
                                    appState.draggingStartPoint != null &&
                                    appState.draggingEndPoint != null
                                ? (appState.draggingStartPoint!, appState.draggingEndPoint!) // TODO null safety
                                : null,
                            (newPathPerEdge) => appState.setPathPerEdge(newPathPerEdge),
                            appState.selectedObject,
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
              onSelectionPress: () => appState.enterSelectionMode(),
              onAwareConnectionPress: () => appState.enterEdgeDrawingMode(EdgeType.aware),
              onObliviousConnectionPress: () => appState.enterEdgeDrawingMode(EdgeType.oblivious),
              onEntryNodePress: () => appState.enterNodeDrawingMode(NodeType.entry),
              onExitNodePress: () => appState.enterNodeDrawingMode(NodeType.exit),
              onTagNodePress: () => appState.enterNodeDrawingMode(NodeType.tag),
              drawingEdgeType: appState.drawingEdgeType,
              drawingNodeType: appState.drawingNodeType,
              isInSelectionMode: appState.isInSelectionMode()),
        ),
      ),
      if (appState.selectedObject is Edge)
        Positioned(
          top: 0,
          bottom: 0,
          right: 16,
          child: Align(
              alignment: Alignment.centerRight,
              child: EdgeInfoPanel(
                  edge: appState.selectedObject as Edge,
                  deleteObject: showDeleteObjectDialog,
                  changeEdgeType: (newEdgeType) {
                    (appState.selectedObject as Edge).type = newEdgeType;
                  })),
        ),
      if (appState.selectedObject is TagNode)
        // TODO reuse panel + positions
        Positioned(
            top: 0,
            bottom: 0,
            right: 16,
            child: Align(
                alignment: Alignment.centerRight,
                child: TagNodeInfoPanel(
                  node: appState.selectedObject as TagNode,
                  deleteObject: showDeleteObjectDialog,
                  editLabel: () {
                    CustomDialog.showInputDialog(
                      context,
                      title: 'Edit label',
                      hint: 'Enter new label',
                      acceptEmptyInput: true,
                      initialText: (appState.selectedObject as TagNode).name,
                      onConfirm: (String inputText) {
                        (appState.selectedObject as TagNode).name = inputText.isNotEmpty ? inputText : null;
                      },
                      isInputValid: (String inputText) => !appState.nodes
                          .any((node) => node != appState.selectedObject && node is TagNode && node.name == inputText),
                      errorMessage: 'Please choose a unique tag label',
                    );
                  },
                ))),
      if (appState.selectedObject is BoundaryNode)
        Positioned(
            top: 0,
            bottom: 0,
            right: 16,
            child: Align(
                alignment: Alignment.centerRight,
                child: BoundaryNodeInfoPanel(
                  node: appState.selectedObject as BoundaryNode,
                  deleteObject: showDeleteObjectDialog,
                  editDescriptor: () {
                    CustomDialog.showInputDialog(context,
                        title: 'Edit descriptor',
                        hint: 'Enter new descriptor',
                        initialText: (appState.selectedObject as BoundaryNode).descriptor,
                        onConfirm: (String inputText) {
                          (appState.selectedObject as BoundaryNode).descriptor = inputText;
                          // TODO MOVE OUT? also need to call notify listeners
                        },
                        isInputValid: (String inputText) =>
                            inputText.isNotEmpty &&
                                appState.selectedObject is EntryNode &&
                                !appState.entryNodeWithDescriptorExists(inputText) ||
                            appState.selectedObject is ExitNode && !appState.exitNodeWithDescriptorExists(inputText),
                        errorMessage:
                            '${appState.selectedObject is EntryNode ? 'Entry' : 'Exit'} node with this descriptor already exists!');
                  },
                ))),
    ]);
  }
}
