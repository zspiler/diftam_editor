import 'package:D2SC_editor/dialogs/manage_policies_dialog.dart';
import 'package:D2SC_editor/dialogs/preferences_dialog.dart';
import 'package:D2SC_editor/import_export.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'canvas_view.dart';
import 'debug/debug_utils.dart';
import 'dialogs/combine_policies_dialog.dart';
import 'dialogs/keyboard_shortcuts_dialog.dart';
import 'policy/policy.dart';
import 'policy_tab_bar.dart';
import 'preferences_manager.dart';
import 'ui/custom_dialog.dart';
import 'ui/snackbar.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  List<Policy> policies = [];
  var selectedPolicyIndex = 0;

  List<FocusNode> focusNodes = [];

  Preferences preferences = Preferences();

  @override
  void initState() {
    super.initState();

    preferences = PreferencesManager.getPreferences();

    if (kDebugMode) {
      getMockPolicies().forEach(addPolicy);
      addPolicy(policies[0] * policies[1]);
      // addPolicy(getMockPolicy());
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

  void addAndSelectPolicy(Policy policy) {
    addPolicy(policy);
    selectPolicy(policies.indexOf(policy));
  }

  void onAddPolicyPress() {
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
        addAndSelectPolicy(Policy(name: newPolicyName));
      },
      isInputValid: (String inputText) => !policies.any((policy) => policy.name == inputText),
      errorMessage: 'Policy with this name already exists!',
    );
  }

  void onImportPolicyPress() async {
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
    addAndSelectPolicy(policy);
    // TODO Desktop
  }

  void onManagePoliciesPress() {
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

  void onCombinePoliciesPress() {
    showDialog(
      context: context,
      builder: (BuildContext context) => CombinePoliciesDialog(
        policies: policies,
        onCombine: addAndSelectPolicy,
      ),
    );
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
                        text: 'create',
                        style: clickableTextSpanStyle,
                        recognizer: TapGestureRecognizer()..onTap = onAddPolicyPress),
                    TextSpan(text: ' or '),
                    TextSpan(
                        text: 'import',
                        style: clickableTextSpanStyle,
                        recognizer: TapGestureRecognizer()..onTap = onImportPolicyPress),
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
                  child: PolicyTabBar(
                    policies,
                    selectedPolicyIndex,
                    onSelect: selectPolicy,
                    onAddPressed: onAddPolicyPress,
                    onImportPressed: onImportPolicyPress,
                    onManagePressed: onManagePoliciesPress,
                    onCombinePressed: onCombinePoliciesPress,
                  ))),
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
                  ))),
          Positioned(
              top: 16,
              right: 16,
              child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.keyboard),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => KeyboardShortcutsDialog(),
                      );
                    },
                  )))
        ],
      ),
    );
  }
}
