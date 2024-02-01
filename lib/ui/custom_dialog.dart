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
      required Function(String text) onConfirm}) {
    TextEditingController textEditingController = TextEditingController();

    Widget continueButton = TextButton(
      child: Text(confirmButtonText ?? "OK"),
      onPressed: () {
        onConfirm(textEditingController.text);
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
      title: Text(title ?? "Input"),
      content: TextField(
        controller: textEditingController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: hint,
        ),
      ),
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

  static void showDropdownInputDialog(
    BuildContext context, {
    String? confirmButtonText,
    String? cancelButtonText,
    String? description,
    String? hint,
    required String title,
    required List<String> options,
    required Function(String text) onConfirm,
  }) {
    var selectedValue = options[0];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // NOTE need StatefulBuilder since we need reactive selectedValue!
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: DropdownButton<String>(
                value: selectedValue,
                items: options.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedValue = newValue!;
                  });
                },
              ),
              actions: [
                TextButton(
                  child: Text(cancelButtonText ?? "Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(confirmButtonText ?? "OK"),
                  onPressed: () {
                    onConfirm(selectedValue);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
