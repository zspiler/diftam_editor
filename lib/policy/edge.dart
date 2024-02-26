import 'node.dart';
import 'graph_object.dart';

enum EdgeType {
  oblivious('Oblivious'),
  aware('Aware');

  final String value;

  const EdgeType(this.value);

  static EdgeType fromString(String value) {
    return EdgeType.values.firstWhere((e) => e.value == value);
  }
}

class Edge implements GraphObject {
  final Node source;
  final Node target;
  EdgeType type;

  Edge(this.source, this.target, this.type) {
    _validate(source, target);
  }

  @override
  Edge copyWith({Node? source, Node? target, EdgeType? type}) {
    return Edge(
      source ?? this.source,
      target ?? this.target,
      type ?? this.type,
    );
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
    String getNodeLabel(Node node) => node is TagNode ? node.label : (node as BoundaryNode).descriptor;

    return {
      'source': getNodeLabel(source),
      'target': getNodeLabel(target),
      'type': type.value,
    };
  }

  Edge.fromJson(Map<String, dynamic> json, List<Node> nodes)
      : source = nodes.firstWhere((node) {
          if (node is TagNode) {
            return node.label == json['source'];
          }
          return (node as BoundaryNode).descriptor == json['source'];
        }),
        target = nodes.firstWhere((node) {
          if (node is TagNode) {
            return node.label == json['target'];
          }
          return (node as BoundaryNode).descriptor == json['target'];
        }),
        type = EdgeType.fromString(json['type']);
}
