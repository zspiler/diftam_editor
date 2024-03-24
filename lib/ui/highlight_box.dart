import 'package:flutter/material.dart';

class HighlightBox extends StatelessWidget {
  final Widget child;

  const HighlightBox({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Color.fromARGB(255, 25, 24, 36), borderRadius: BorderRadius.all(Radius.circular(4))),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Center(child: child),
      ),
    );
  }
}
