import 'package:flutter/material.dart';
import 'package:poc/manage_policies_dialog.dart';
import 'package:poc/preferences_dialog.dart';
import 'canvas_view.dart';
import 'ui/snackbar.dart';
import 'common.dart';
import 'policy_tab_bar.dart';
import 'user_preferences.dart';
import 'ui/custom_dialog.dart';

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
  List<PolicyData> policies = [];
  var selectedPolicyIndex = 0;

  List<FocusNode> focusNodes = [];

  final nodes = <Node>[];
  final edges = <Edge>[];
  Preferences preferences = Preferences();

  @override
  void initState() {
    super.initState();

    loadPreferences();

    // TODO ensure unique IDS?
    final tag2 = TagNode(Offset(500, 350), 'randomId', 'priv');
    final tag3 = TagNode(Offset(700, 350), 'randomId2', 'pub');
    final tag4 = TagNode(Offset(100, 250), 'abcdefghijklm', 'abcdefghijklm');
    final tag5 = TagNode(Offset(500, 250), 'randomId55', 'priv5');
    final tag6 = TagNode(Offset(700, 250), 'randomId55', 'pub6');

    createPolicy(name: 'Policy 1', nodes: [
      tag2,
      tag3,
      tag4,
      tag5,
      tag6
    ], edges: [
      Edge(tag2, tag3, EdgeType.aware),
      Edge(tag2, tag3, EdgeType.oblivious),
      Edge(tag5, tag6, EdgeType.oblivious),
      Edge(tag5, tag5, EdgeType.oblivious),
      Edge(tag5, tag5, EdgeType.aware)
    ]);

    createPolicy(name: 'Policy 2');
  }

  @override
  void dispose() {
    super.dispose();
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
  }

  Future<void> loadPreferences() async {
    final prefs = await PreferencesManager.getPreferences();
    setState(() {
      preferences = prefs;
    });
  }

  void createPolicy({required String name, List<Node>? nodes, List<Edge>? edges}) {
    setState(() {
      focusNodes.add(FocusNode());
      policies.add(PolicyData(name: name, nodes: nodes, edges: edges));
    });
  }

  void selectPolicy(int index) {
    setState(() {
      selectedPolicyIndex = index;
      focusNodes[selectedPolicyIndex].requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
              index: selectedPolicyIndex,
              children: policies.asMap().entries.map((entry) {
                final index = entry.key;
                final policy = entry.value;
                return CanvasView(
                  nodes: policy.nodes,
                  edges: policy.edges,
                  focusNode: focusNodes[index],
                  preferences: preferences,
                );
              }).toList()),
          Positioned(
              bottom: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: PolicyTabBar(policies, selectedPolicyIndex, onSelect: selectPolicy, onAddPressed: () {
                  var newPolicyName = 'Policy ${policies.length + 1}';
                  CustomDialog.showInputDialog(
                    context,
                    title: 'Create policy',
                    hint: 'Enter policy name',
                    acceptEmptyInput: true,
                    initialText: newPolicyName,
                    onConfirm: (String inputText) {
                      if (inputText.isNotEmpty) {
                        newPolicyName = inputText;
                      }
                      createPolicy(name: newPolicyName);
                      selectPolicy(policies.length - 1);
                    },
                    isInputValid: (String inputText) => !policies.any((policy) => policy.name == inputText),
                    errorMessage: 'Policy with this name already exists!',
                  );
                }, onManagePressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ManagePoliciesDialog(
                          policies: policies,
                          onChange: (updatedPolicies) {
                            setState(() {
                              policies = List.from(updatedPolicies);
                            });
                          },
                          onDeletePress: (int index) {
                            final newPoliciesLength = policies.length - 1;
                            if (selectedPolicyIndex >= newPoliciesLength) {
                              selectPolicy(selectedPolicyIndex -= 1);
                            }
                          },
                        );
                      });
                }),
              )),
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
