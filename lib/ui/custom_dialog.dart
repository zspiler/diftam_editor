import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomDialog {
  static void showConfirmationDialog(BuildContext context,
      {String? confirmButtonText, String? cancelButtonText, required String title, required Function onConfirm}) {
    Widget continueButton = TextButton(
      child: Text(confirmButtonText ?? "OK"),
      onPressed: () {
        onConfirm();
        Navigator.of(context).pop();
      },
    );

    Widget cancelButton = TextButton(
      child: Text(cancelButtonText ?? "Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Alert"),
      content: Text(title),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) => alert,
    );
  }

  static void showInputDialog(
    BuildContext context, {
    required String title,
    required Function(String text) onConfirm,
    String? confirmButtonText,
    String? cancelButtonText,
    String? description,
    String? hint,
    bool Function(String)? isInputValid, // Validation function parameter
    bool acceptEmptyInput = false,
    String? errorMessage,
    String? initialText,
  }) {
    TextEditingController textEditingController = TextEditingController();
    if (initialText != null) {
      textEditingController.text = initialText;
    }

    String? displayedError;
    late FocusNode focusNode = FocusNode();

    // TODO AlertDialog useless? (we're not using actions)
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Container(
        // TODO responsive (padding: EdgeInsets.all?)
        height: 150,
        width: 300,
        child: Center(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              void onContinuePress() {
                if (!acceptEmptyInput && textEditingController.text.isEmpty) {
                  setState(() {
                    displayedError = 'Field must not be empty';
                  });
                  return;
                }
                if (isInputValid != null && !isInputValid(textEditingController.text)) {
                  setState(() {
                    displayedError = errorMessage ?? 'Invalid input';
                  });
                  return;
                }

                onConfirm(textEditingController.text);
                Navigator.of(context).pop();
              }

              Widget cancelButton = TextButton(
                child: Text(cancelButtonText ?? "Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              );

              Widget continueButton = TextButton(
                child: Text(confirmButtonText ?? "OK"),
                onPressed: onContinuePress,
              );

              return KeyboardListener(
                focusNode: focusNode,
                autofocus: true,
                onKeyEvent: (event) {
                  if (event is KeyDownEvent && RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.enter)) {
                    onContinuePress();
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textEditingController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: hint,
                        errorText: displayedError,
                      ),
                      onSubmitted: (String value) {
                        onContinuePress(); // handle 'Enter' key press when input is focused
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [cancelButton, continueButton],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) => alert,
    );
  }
}
