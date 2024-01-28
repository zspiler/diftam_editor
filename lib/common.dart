import 'dart:math';
import 'package:flutter/material.dart';

const gridSize = 25;

enum NodeType {
  entry('Entry'),
  exit('Exit'),
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

abstract class GraphObject {}

class Node implements GraphObject {
  String id;
  Point position;
  final NodeType type;

  Node(this.id, this.position, this.type);

  @override
  String toString() {
    return 'Node{$id, ${type.value}}';
  }
}

class Edge implements GraphObject {
  final Node source;
  final Node target;
  EdgeType type;

  Edge(this.source, this.target, this.type) {
    _validate(source, target);
  }

  void _validate(Node source, Node target) {
    if (source == target && source.type != NodeType.tag) {
      throw ArgumentError("Only 'Tag' node can connect with itself");
    }

    if (source.type == NodeType.entry && target.type != NodeType.tag) {
      throw ArgumentError("'Entry' node can only connect into 'Tag' node!");
    }

    if (source.type == NodeType.exit) {
      throw ArgumentError("'Exit' node cannot have any outgoing edges!");
    }

    if (target.type == NodeType.entry) {
      throw ArgumentError("'Entry' node cannot have any incoming edges!");
    }
  }

  @override
  String toString() {
    return 'Edge{source: $source, target: $target, type: ${type.value}}';
  }
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

class Dialogs {
  static void showConfirmationDialog(BuildContext context,
      {String? confirmButtonText, String? cancelButtonText, required String title, required Function onConfirm}) {
    Widget continueButton = TextButton(
      child: Text(confirmButtonText ?? "OK"),
      onPressed: () {
        onConfirm();
        Navigator.of(context).pop();
      },
    );

    Widget cancelButton = TextButton(
      child: Text(cancelButtonText ?? "Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Alert"),
      content: Text(title),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) => alert,
    );
  }
}
