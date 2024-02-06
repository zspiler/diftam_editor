import 'package:flutter/material.dart';

class NumberInput extends StatelessWidget {
  final int value;
  final int? max;
  final int? min;
  final Function(int) onChange;

  const NumberInput({
    super.key,
    required this.value,
    required this.onChange,
    this.max,
    this.min,
  });

  void _increment() {
    if (max == null || value < max!) {
      onChange(value + 1);
    }
  }

  void _decrement() {
    if (min == null || value > min!) {
      onChange(value - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        icon: Icon(Icons.remove),
        onPressed: _decrement,
      ),
      Text('$value', style: TextStyle(fontSize: 18)),
      IconButton(
        icon: Icon(Icons.add),
        onPressed: _increment,
      ),
    ]);
  }
}
