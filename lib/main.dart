import 'package:flutter/material.dart';
import 'package:poc/preferences_dialog.dart';
import 'canvas_view.dart';
import 'ui/snackbar.dart';
import 'common.dart';
import 'canvas_tab_bar.dart';
import 'user_preferences.dart';

void main() {
  runApp(MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.blue),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: SnackbarGlobal.key,
      home: const MyApp()));
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
  Preferences preferences = Preferences();

  @override
  void initState() {
    loadPreferences();

    focusNode = FocusNode();

    // TODO ensure unique IDS?
    final entry = EntryNode(Offset(350, 350), 'stdin');
    final tag2 = TagNode(Offset(500, 350), 'randomId', 'priv');
    final tag3 = TagNode(Offset(700, 350), 'randomId2', 'pub');
    final exit = ExitNode(Offset(850, 350), 'stdout');
    addNewCanvas(
        nodes: [tag2, tag3, entry, exit], edges: [Edge(tag2, tag3, EdgeType.aware), Edge(tag2, tag3, EdgeType.oblivious)]);
  }

  @override
  void dispose() {
    focusNode.dispose(); // TODO useless? is this ever called?
    super.dispose();
  }

  Future<void> loadPreferences() async {
    final prefs = await PreferencesManager.getPreferences();
    setState(() {
      preferences = prefs;
    });
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
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
              index: selectedCanvasIndex,
              children: canvases.map((canvas) {
                return CanvasView(
                  nodes: canvas.nodes,
                  edges: canvas.edges,
                  focusNode: focusNode,
                  preferences: preferences,
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
          Positioned(
              top: 16,
              left: 16,
              child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => PreferencesDialog(
                          onChange: (newPreferences) {
                            setState(() {
                              preferences = newPreferences;
                            });
                          },
                        ),
                      );
                    },
                  )))
        ],
      ),
    );
  }
}
