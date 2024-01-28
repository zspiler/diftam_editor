import 'package:flutter/material.dart';
import 'common.dart';

class InfoPanel extends StatelessWidget {
  final String text;

  const InfoPanel({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(75),
      width: 400,
      height: 400,
      child: Text(text),
    );
  }
}
