import 'package:flutter/material.dart';

class InfoPanelPositioner extends StatelessWidget {
  final Widget child;
  const InfoPanelPositioner({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      right: 16,
      child: Align(
        alignment: Alignment.centerRight,
        child: child,
      ),
    );
  }
}
