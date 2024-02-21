import 'package:flutter/material.dart';

class ObjectInfoPanel extends StatelessWidget {
  final List<Widget> children;
  const ObjectInfoPanel({
    Key? key,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      right: 16,
      child: Align(
          alignment: Alignment.centerRight,
          child: Container(
              decoration: BoxDecoration(color: Colors.black.withAlpha(75), borderRadius: BorderRadius.all(Radius.circular(20))),
              width: 400,
              height: 300, // TODO responsive / adjust to screen? (padding: EdgeInsets.all?)
              child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 64.0, vertical: 16.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: children)))),
    );
  }
}
