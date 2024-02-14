import 'package:flutter/material.dart';
import 'package:poc/import.dart';
import 'package:poc/manage_policies_dialog.dart';
import 'package:poc/preferences_dialog.dart';
import 'canvas_view.dart';
import 'ui/snackbar.dart';
import 'models.dart';
import 'policy_tab_bar.dart';
import 'user_preferences.dart';
import 'ui/custom_dialog.dart';
import 'package:file_picker/file_picker.dart';

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

  Preferences preferences = Preferences();

  @override
  void initState() {
    super.initState();

    loadPreferences();

    // TODO ensure unique IDS?
    final priv = TagNode(Offset(500, 350), 'privID', 'priv');
    final pub = TagNode(Offset(700, 350), 'pubID', 'pub');
    final stdin = EntryNode(Offset(300, 250), 'stdin');
    final stdout = ExitNode(Offset(900, 250), 'stdout');

    final policy = PolicyData(name: 'Policy 1', nodes: [
      priv,
      pub,
      stdin,
      stdout
    ], edges: [
      Edge(stdin, priv, EdgeType.aware),
      Edge(priv, pub, EdgeType.oblivious),
      Edge(priv, pub, EdgeType.aware),
      Edge(pub, pub, EdgeType.aware),
      Edge(pub, pub, EdgeType.oblivious),
      Edge(pub, priv, EdgeType.aware),
      Edge(pub, stdout, EdgeType.aware),
    ]);

    addPolicy(policy);
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

  void addPolicy(PolicyData policy) {
    setState(() {
      focusNodes.add(FocusNode());
      policies.add(policy);
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
                      addPolicy(PolicyData(name: newPolicyName));
                      selectPolicy(policies.length - 1);
                    },
                    isInputValid: (String inputText) => !policies.any((policy) => policy.name == inputText),
                    errorMessage: 'Policy with this name already exists!',
                  );
                }, onImportPressed: () async {
                  // TODO this package supports saving file via dialog, but only on Desktop!
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                    withData: true, // needed for MacOS
                  );
                  if (result == null) {
                    // user canceled file picker
                    return;
                  }
                  final bytes = result.files.single.bytes;
                  if (bytes == null) {
                    SnackbarGlobal.error("Failed to read file");
                    return;
                  }

                  PolicyData policy;
                  try {
                    policy = decodeAndParsePolicy(bytes);
                  } catch (e) {
                    SnackbarGlobal.error(e.toString());
                    return;
                  }
                  addPolicy(policy);
                  // TODO Desktop
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
