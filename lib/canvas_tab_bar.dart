import 'package:flutter/material.dart';
import 'common.dart';

class CanvasTabBar extends StatelessWidget {
  final List<CanvasData> canvases;
  final Function(int index) onSelect;
  final Function() onAdd;
  final int currentCanvasIndex;

  CanvasTabBar(this.canvases, this.currentCanvasIndex, {Key? key, required this.onSelect, required this.onAdd}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          ...canvases.asMap().entries.map((canvas) {
            final index = canvas.key;
            return SizedBox(
              height: 40,
              child: TextButton(
                style: ButtonStyle(
                  splashFactory: NoSplash.splashFactory,
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                    topLeft: index == 0 ? Radius.circular(10) : Radius.circular(0),
                    bottomLeft: index == 0 ? Radius.circular(10) : Radius.circular(0),
                  ))),
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  backgroundColor: index == currentCanvasIndex
                      ? MaterialStateProperty.all<Color>(Colors.blue)
                      : MaterialStateProperty.all<Color>(Colors.black.withAlpha(150)),
                ),
                onPressed: () => onSelect(index),
                child: Text('Canvas ${index}'),
              ),
            );
          }).toList(),
          SizedBox(
            height: 40,
            child: TextButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
                  ),
                ),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                backgroundColor: MaterialStateProperty.all<Color>(Colors.black.withAlpha(150)),
              ),
              onPressed: onAdd,
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
