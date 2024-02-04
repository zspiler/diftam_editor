import 'package:flutter/material.dart';
import 'canvas_view.dart';
import 'ui/snackbar.dart';
import 'common.dart';
import 'canvas_tab_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<CanvasData> canvases = [];
  var selectedCanvasIndex = 0;
  late FocusNode focusNode;

  final nodes = <Node>[];
  final edges = <Edge>[];

  @override
  void initState() {
    focusNode = FocusNode();

    // TODO ensure unique IDS?
    final tag2 = TagNode(Offset(500, 350), 'randomId', 'priv');
    final tag3 = TagNode(Offset(700, 350), 'randomId2', 'pub');

    addNewCanvas(nodes: [tag2, tag3], edges: [Edge(tag2, tag3, EdgeType.aware)]);
  }

  @override
  void dispose() {
    focusNode.dispose(); // TODO useless? is this ever called?
    super.dispose();
  }

  void addNewCanvas({List<Node>? nodes, List<Edge>? edges}) {
    setState(() {
      canvases.add(CanvasData(nodes: nodes, edges: edges));
    });
  }

  void selectCanvas(int index) {
    setState(() {
      selectedCanvasIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.blue),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: SnackbarGlobal.key,
      home: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
                index: selectedCanvasIndex,
                children: canvases.map((canvas) {
                  return CanvasView(
                    nodes: canvas.nodes,
                    edges: canvas.edges,
                    focusNode: focusNode,
                  );
                }).toList()),
            Positioned(
                bottom: 0,
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: CanvasTabBar(canvases, selectedCanvasIndex, onSelect: selectCanvas, onAdd: () {
                      addNewCanvas();
                      setState(() {
                        selectedCanvasIndex = canvases.length - 1;
                      });
                    }))),
          ],
        ),
      ),
    );
  }
}
