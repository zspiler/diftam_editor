import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:file_picker/file_picker.dart';
import 'package:poc/import_export.dart';
import 'package:poc/manage_policies_dialog.dart';
import 'package:poc/preferences_dialog.dart';
import 'canvas_view.dart';
import 'ui/snackbar.dart';
import 'policy/policy.dart';
import 'policy_tab_bar.dart';
import 'preferences_manager.dart';
import 'ui/custom_dialog.dart';
import 'dev_utils.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // SharedPreferences requires Flutter engine bindings to be initialized!
  await PreferencesManager.init();

  runApp(MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: darkBlue),
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
  List<Policy> policies = [];
  var selectedPolicyIndex = 0;

  List<FocusNode> focusNodes = [];

  Preferences preferences = Preferences();

  @override
  void initState() {
    super.initState();

    preferences = PreferencesManager.getPreferences();

    if (kDebugMode) {
      addPolicy(getMockPolicy());
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
  }

  void addPolicy(Policy policy) {
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

  void onAddPolicy() {
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
        addPolicy(Policy(name: newPolicyName));
        selectPolicy(policies.length - 1);
      },
      isInputValid: (String inputText) => !policies.any((policy) => policy.name == inputText),
      errorMessage: 'Policy with this name already exists!',
    );
  }

  void onImportPolicy() async {
    // NOTE this package supports saving file via dialog, but only on Desktop!
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

    Policy policy;
    try {
      policy = decodeAndParsePolicy(bytes);
    } catch (e) {
      SnackbarGlobal.error(e.toString());
      return;
    }
    addPolicy(policy);
    selectPolicy(policies.length - 1);
    // TODO Desktop
  }

  void onManagePolicies() {
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
              if (newPoliciesLength > 0 && selectedPolicyIndex >= newPoliciesLength) {
                selectPolicy(selectedPolicyIndex -= 1);
              }
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    const clickableTextSpanStyle = TextStyle(color: Colors.blue);
    return Scaffold(
      body: Stack(
        children: [
          if (policies.isEmpty)
            Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('No policies created yet.', style: TextStyle(color: Colors.white)),
              SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  text: '',
                  style: TextStyle(color: Colors.white),
                  children: [
                    TextSpan(text: 'Please '),
                    TextSpan(
                        text: 'create', style: clickableTextSpanStyle, recognizer: TapGestureRecognizer()..onTap = onAddPolicy),
                    TextSpan(text: ' or '),
                    TextSpan(
                        text: 'import',
                        style: clickableTextSpanStyle,
                        recognizer: TapGestureRecognizer()..onTap = onImportPolicy),
                    TextSpan(text: ' a policy.'),
                  ],
                ),
              ),
            ])),
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
                  child: PolicyTabBar(policies, selectedPolicyIndex,
                      onSelect: selectPolicy,
                      onAddPressed: onAddPolicy,
                      onImportPressed: onImportPolicy,
                      onManagePressed: onManagePolicies))),
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
