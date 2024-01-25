import 'dart:math';

const gridSize = 25;

class Node {
  String id;
  final Point position;

  Node(this.id, this.position);
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
