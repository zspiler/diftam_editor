import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'graph.dart';
import 'ui/snackbar.dart';
import 'common.dart';
import 'utils.dart';
import 'node_painter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.blue),
        debugShowCheckedModeBanner: false,
        home: const Scaffold(body: CanvasView()),
        scaffoldMessengerKey: SnackbarGlobal.key,
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  List<Node> nodes = [];
  List<Edge> edges = [];
  var pathPerEdge = <Edge, Path>{};

  Offset? draggingStartPoint;
  Offset? draggingEndPoint;
  Node? draggedNode;
  Node? newEdgeSourceNode;
  Offset cursorPosition = Offset.zero;
  Offset canvasPosition = Offset.zero;
  GraphObject? hoveredObject;
  GraphObject? selectedObject;

  double scale = 1.0; // TODO per canvas?

  EdgeType? drawingEdgeType;
  NodeType? drawingNodeType;

  MyAppState() {
    _initState();
  }

  void addNode(Node node) {
    nodes.add(node);
    notifyListeners();
  }

  void stopEdgeDrawing() {
    newEdgeSourceNode = null;
    draggingStartPoint = null;
    draggingEndPoint = null;
    drawingEdgeType = null;
    notifyListeners();
  }

  void stopNodeDrawing() {
    drawingNodeType = null;
    notifyListeners();
  }

  void enterSelectionMode() {
    stopEdgeDrawing();
    stopNodeDrawing();
    notifyListeners();
  }

  void resetZoomAndPosition() {
    canvasPosition = Offset(0, 0);
    scale = 1.0;
    notifyListeners();
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

  // TODO extract into utils
  bool isNodeHit(Node node, Offset offset) {
    final (nodeWidth, nodeHeight) = NodePainter.calculateNodeBoxSize(node);

    return node.position.dx < offset.dx &&
        node.position.dx + nodeWidth > offset.dx &&
        node.position.dy < offset.dy &&
        node.position.dy + nodeHeight > offset.dy;
  }

// TODO extract into utils
  bool isEdgeHit(Edge edge, Offset position) {
    if (!pathPerEdge.containsKey(edge)) {
      return false; // sanity check TODO
    }

    final path = pathPerEdge[edge]!;

    return Utils.isPointNearBezierPath(position, path);
  }

  void deleteSelectedObject() {
    if (selectedObject is Node) {
      nodes.remove(selectedObject);
      edges.removeWhere((edge) => edge.source == selectedObject || edge.target == selectedObject);
    } else {
      edges.remove(selectedObject);
    }

    selectedObject = null;
    notifyListeners();
  }

  void enterNodeDrawingMode(NodeType nodeType) {
    drawingEdgeType = null;
    if (drawingNodeType == null || drawingNodeType != nodeType) {
      drawingNodeType = nodeType;
    } else {
      stopNodeDrawing();
    }
    notifyListeners();
  }

  void enterEdgeDrawingMode(EdgeType edgeType) {
    stopNodeDrawing();

    if (drawingEdgeType == null || drawingEdgeType != edgeType) {
      drawingEdgeType = edgeType;
    } else {
      drawingEdgeType = null;
    }

    notifyListeners();
  }

  void createEdge(Node sourceNode, Node targetNode, EdgeType edgeType) {
    try {
      final newEdge = Edge(sourceNode, targetNode, edgeType);
      final edgeExists =
          edges.any((edge) => edge.source == newEdge.source && edge.target == newEdge.target && edge.type == newEdge.type);
      if (!edgeExists) {
        edges.add(newEdge);
      }
      notifyListeners();
    } on ArgumentError catch (e) {
      // TODO seperate UI and state management 🙈
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

    nodes.add(newNode);
    notifyListeners();
  }

  bool entryNodeWithDescriptorExists(String descriptor) {
    return nodes.any((node) => node is EntryNode && node.descriptor == descriptor);
  }

  bool exitNodeWithDescriptorExists(String descriptor) {
    return nodes.any((node) => node is ExitNode && node.descriptor == descriptor);
  }

  // Setters
  void setScale(double newScale) {
    scale = newScale;
    notifyListeners();
  }

  void setCanvasPosition(Offset position) {
    canvasPosition = position;
    notifyListeners();
  }

  void setCursorPosition(Offset position) {
    cursorPosition = position;
    notifyListeners();
  }

  void setDraggingEndPoint(Offset position) {
    draggingEndPoint = position;
    notifyListeners();
  }

  void setHoveredObject(GraphObject? object) {
    hoveredObject = object;
    notifyListeners();
  }

  void setPathPerEdge(Map<Edge, Path> newPathPerEdge) {
    pathPerEdge = newPathPerEdge;
    notifyListeners();
  }

  void setSelectedObject(GraphObject? object) {
    selectedObject = object;
    // notifyListeners();
  }

  void setDraggingStartPoint(position) {
    draggingStartPoint = position;
    // notifyListeners();
  }

  void setNewEdgeSourceNode(node) {
    newEdgeSourceNode = node;
    // notifyListeners();
  }

  void setDraggedNode(node) {
    draggedNode = node;
    // notifyListeners();
  }

  bool isInSelectionMode() => drawingEdgeType == null && drawingNodeType == null;
  bool isInEdgeDrawingMode() => drawingEdgeType != null;
  bool isInNodeDrawingMode() => drawingNodeType != null;

  bool isInNodeCreationMode() {
    return drawingNodeType != null;
  }

  void _initState() {
    // init?
    // TODO init state
    final tag2 = TagNode(Offset(500, 350), 'randomId', 'priv');
    final tag3 = TagNode(Offset(700, 350), 'randomId2', 'pub');
    nodes.add(tag2);
    nodes.add(tag3);
    notifyListeners();

    //  // TODO ensure unique IDS?
    //   // final someLongId = TagNode(Offset(100, 100), 'some long id', 'some label');
    //   final tag2 = TagNode(Offset(500, 350), 'randomId', 'priv');
    //   final tag3 = TagNode(Offset(700, 350), 'randomId2', 'pub');

    //   // final tag3 = Node("tag 3", Offset(500, 150), NodeType.tag);
    //   // final stdin = Node("stdin", Offset(600, 150), NodeType.entry);
    //   // final stdout = Node("stdout", Offset(800, 150), NodeType.exit);
    //   // final someVeryVeryVeryLongId = Node("some very very very long id", Offset(500, 100), NodeType.tag);

    //   // nodes.add(someLongId);
    //   nodes.add(tag2);
    //   nodes.add(tag3);
    //   // nodes.add(tag3);
    //   // nodes.add(stdin);
    //   // nodes.add(stdout);
    //   // nodes.add(someVeryVeryVeryLongId);

    //   // edges.add(Edge(someLongId, tag2, EdgeType.oblivious));
    //   // edges.add(Edge(someLongId, tag2, EdgeType.aware));
    //   // edges.add(Edge(someLongId, someLongId, EdgeType.oblivious));
    //   // edges.add(Edge(someLongId, tag3, EdgeType.oblivious));
    //   edges.add(Edge(tag2, tag3, EdgeType.aware));
  }
}
