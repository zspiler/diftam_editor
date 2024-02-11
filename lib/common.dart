import 'package:flutter/material.dart';

const gridSize = 25;

enum EdgeType {
  oblivious('Oblivious'),
  aware('Aware');

  final String value;

  const EdgeType(this.value);
}

enum NodeType {
  tag('Tag'),
  entry('Entry'),
  exit('Exit');

  final String value;

  const NodeType(this.value);
}

abstract class GraphObject {}

abstract class Node implements GraphObject {
  Offset position;

  Node(this.position);

  String get label;

  @override
  String toString() => toNodeString(); // we want to require that subclasses implement their own toString method

  String toNodeString();
}

class TagNode extends Node {
  final String id;
  String? name;

  TagNode(Offset position, this.id, [this.name]) : super(position);

  @override
  String get label => name ?? id;

  @override
  String toNodeString() {
    return 'Tag ($id, $label)';
  }
}

abstract class BoundaryNode extends Node {
  String descriptor;

  BoundaryNode(Offset position, this.descriptor) : super(position);

  @override
  String get label => descriptor;

  @override
  String toNodeString() {
    return 'BoundaryNode ($descriptor)';
  }
}

class EntryNode extends BoundaryNode {
  EntryNode(Offset position, String descriptor) : super(position, descriptor);

  @override
  String toNodeString() {
    return 'EntryNode{$descriptor}';
  }
}

class ExitNode extends BoundaryNode {
  ExitNode(Offset position, String descriptor) : super(position, descriptor);

  @override
  String toNodeString() {
    return 'ExitNode{$descriptor}';
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
    if (source == target && source is! TagNode) {
      throw ArgumentError("Only 'Tag' node can connect with itself");
    }

    if (source is EntryNode && target is! TagNode) {
      throw ArgumentError("'Entry' node can only connect into 'Tag' node!");
    }

    if (source is ExitNode) {
      throw ArgumentError("'Exit' node cannot have any outgoing edges!");
    }

    if (target is EntryNode) {
      throw ArgumentError("'Entry' node cannot have any incoming edges!");
    }
  }

  @override
  String toString() {
    return 'Edge{source: $source, target: $target, type: ${type.value}}';
  }
}

class PolicyData {
  String name;
  final List<Node> nodes;
  final List<Edge> edges;

  PolicyData({required this.name, List<Node>? nodes, List<Edge>? edges})
      : nodes = nodes ?? [],
        edges = edges ?? [];
}
