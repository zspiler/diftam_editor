import 'package:flutter/material.dart';

class ConstrainedDialog extends StatelessWidget {
  final Widget child;

  const ConstrainedDialog({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        constraints: BoxConstraints(minWidth: 800),
        child: child,
      ),
    );
  }
}
