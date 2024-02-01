import 'package:flutter/material.dart';

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

  static void showInputDialog(BuildContext context,
      {String? confirmButtonText,
      String? cancelButtonText,
      String? description,
      String? hint,
      required String title,
      required Function(String text) onConfirm,
      bool Function(String)? isInputValid, // Validation function parameter
      bool acceptEmptyInput = false,
      String? errorMessage}) {
    TextEditingController textEditingController = TextEditingController();

    String? displayedError;

    // TODO AlertDialog useless? (we're not using actions)
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Container(
        // TODO responsive
        height: 150,
        width: 300,
        child: Center(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              Widget cancelButton = TextButton(
                child: Text(cancelButtonText ?? "Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              );

              Widget continueButton = TextButton(
                child: Text(confirmButtonText ?? "OK"),
                onPressed: () {
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
                  // If validation passes or not provided
                  onConfirm(textEditingController.text);
                  Navigator.of(context).pop();
                },
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: hint,
                      errorText: displayedError, // Display the error message if not null
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [cancelButton, continueButton], // Place 'continueButton' inside the Row
                  ),
                ],
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
