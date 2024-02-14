import 'package:flutter/material.dart';

enum EdgeType {
  oblivious('Oblivious'),
  aware('Aware');

  final String value;

  const EdgeType(this.value);

  static EdgeType fromString(String value) {
    return EdgeType.values.firstWhere((e) => e.value == value);
  }
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
  String toString() => toNodeString(); // require that subclasses to implement their own toString method

  String toNodeString();

  Map<String, dynamic> toJson() {
    return {
      'position': {'x': position.dx, 'y': position.dy},
    };
  }

  Node.fromJson(Map<String, dynamic> json) : position = Offset(json['position']['x'], json['position']['y']);
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': NodeType.tag.value,
      'id': id,
      'name': name,
      ...super.toJson(),
    };
  }

  TagNode.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        super.fromJson(json);
}

abstract class BoundaryNode extends Node {
  // TODO descriptor could just be 'id'? Edge.fromJson would be simpler

  String descriptor;

  BoundaryNode(Offset position, this.descriptor) : super(position);

  @override
  String get label => descriptor;

  @override
  String toNodeString() {
    return 'BoundaryNode ($descriptor)';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'descriptor': descriptor,
      ...super.toJson(),
    };
  }

  BoundaryNode.fromJson(Map<String, dynamic> json)
      : descriptor = json['descriptor'],
        super.fromJson(json);
}

class EntryNode extends BoundaryNode {
  EntryNode(Offset position, String descriptor) : super(position, descriptor);

  @override
  String toNodeString() {
    return 'EntryNode{$descriptor}';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': NodeType.entry.value,
      ...super.toJson(),
    };
  }

  EntryNode.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}

class ExitNode extends BoundaryNode {
  ExitNode(Offset position, String descriptor) : super(position, descriptor);

  @override
  String toNodeString() {
    return 'ExitNode{$descriptor}';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': NodeType.exit.value,
      ...super.toJson(),
    };
  }

  ExitNode.fromJson(Map<String, dynamic> json) : super.fromJson(json);
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

  Map<String, dynamic> toJson() {
    String getNodeId(Node node) => node is TagNode ? node.id : (node as BoundaryNode).descriptor;

    return {
      'source': getNodeId(source),
      'target': getNodeId(target),
      'type': type.value,
    };
  }

  Edge.fromJson(Map<String, dynamic> json, List<Node> nodes)
      : source = nodes.firstWhere((node) {
          if (node is TagNode) {
            return node.id == json['source'];
          }
          return (node as BoundaryNode).descriptor == json['source'];
        }),
        target = nodes.firstWhere((node) {
          if (node is TagNode) {
            return node.id == json['target'];
          }
          return (node as BoundaryNode).descriptor == json['target'];
        }),
        type = EdgeType.fromString(json['type']); // TODO ?
}

class PolicyData {
  String name = '';
  late final List<Node> nodes; // TODO late OK?
  late final List<Edge> edges; // TODO late OK?

  PolicyData({required this.name, List<Node>? nodes, List<Edge>? edges})
      : nodes = nodes ?? [],
        edges = edges ?? [];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'edges': edges.map((edge) => edge.toJson()).toList(),
    };
  }

  PolicyData.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    nodes = json['nodes'].map<Node>((node) {
      if (node['type'] == NodeType.tag.value) {
        return TagNode.fromJson(node);
      }

      if (node['type'] == NodeType.entry.value) {
        return EntryNode.fromJson(node);
      }

      if (node['type'] == NodeType.exit.value) {
        return ExitNode.fromJson(node);
      }
      throw ArgumentError('Unknown node type: ${node['type']}');
    }).toList();
    edges = json['edges'].map<Edge>((edge) => Edge.fromJson(edge, nodes)).toList();
  }
}
