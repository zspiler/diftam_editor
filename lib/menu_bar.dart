import 'package:flutter/material.dart';
import 'common.dart';

class MyMenuBar extends StatelessWidget {
  final VoidCallback onSelectionPress;
  final VoidCallback onObliviousConnectionPress;
  final VoidCallback onAwareConnectionPress;
  final VoidCallback onEntryNodePress;
  final VoidCallback onExitNodePress;
  final VoidCallback onTagNodePress;
  final EdgeType? drawingEdgeType;
  final NodeType? drawingNodeType;
  final bool isInSelectionMode;

  const MyMenuBar({
    super.key,
    required this.onSelectionPress,
    required this.onObliviousConnectionPress,
    required this.onAwareConnectionPress,
    required this.onEntryNodePress,
    required this.onExitNodePress,
    required this.onTagNodePress,
    required this.drawingEdgeType,
    required this.drawingNodeType,
    required this.isInSelectionMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.black.withAlpha(75), border: Border.all(), borderRadius: BorderRadius.all(Radius.circular(20))),
      width: 400,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Tooltip(
              message: "Selection",
              child: IconButton(
                icon: Icon(Icons.ads_click),
                onPressed: onSelectionPress,
                style: IconButton.styleFrom(backgroundColor: isInSelectionMode ? Colors.white : null),
              )),
          Tooltip(
              message: "Aware connection",
              child: IconButton(
                icon: Icon(Icons.arrow_forward, color: Colors.green),
                onPressed: onAwareConnectionPress,
                style: IconButton.styleFrom(backgroundColor: drawingEdgeType == EdgeType.aware ? Colors.white : null),
              )),
          Tooltip(
              message: "Oblivious connection",
              child: IconButton(
                icon: Icon(Icons.arrow_forward, color: Colors.red),
                onPressed: onObliviousConnectionPress,
                style: IconButton.styleFrom(backgroundColor: drawingEdgeType == EdgeType.oblivious ? Colors.white : null),
              )),
          Tooltip(
              message: "Tag node",
              child: IconButton(
                icon: Icon(Icons.crop_square),
                onPressed: onTagNodePress,
                style: IconButton.styleFrom(backgroundColor: drawingNodeType == NodeType.tag ? Colors.white : null),
              )),
          Tooltip(
              message: "Entry node",
              child: IconButton(
                icon: Icon(Icons.login),
                onPressed: onEntryNodePress,
                style: IconButton.styleFrom(backgroundColor: drawingNodeType == NodeType.entry ? Colors.white : null),
              )),
          Tooltip(
              message: "Exit node",
              child: IconButton(
                icon: Icon(Icons.logout),
                onPressed: onExitNodePress,
                style: IconButton.styleFrom(backgroundColor: drawingNodeType == NodeType.exit ? Colors.white : null),
              )),
        ],
      ),
    );
  }
}
