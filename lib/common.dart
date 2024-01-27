import 'dart:math';

const gridSize = 25;

enum NodeType {
  entryExit('Entry/Exit'),
  tag('Tag');

  final String value;

  const NodeType(this.value);
}

enum EdgeType {
  oblivious('Oblivious'),
  aware('Aware');

  final String value;

  const EdgeType(this.value);
}

class Node {
  String id;
  final Point position;
  final NodeType type;

  Node(this.id, this.position, this.type);
}

class Utils {
  static double snapToGrid(double value, int gridSize) {
    return (value / gridSize).round() * gridSize * 1.0;
  }

  static String generateRandomString(int len) {
    var r = Random();
    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)]).join();
  }
}
