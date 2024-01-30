import 'package:flutter/material.dart';

class ConfirmationDialog {
  static void show(BuildContext context,
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
}
