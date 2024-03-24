import 'node.dart';
import 'edge.dart';
import 'operations.dart';

export 'edge.dart';
export 'node.dart';
export 'graph_object.dart';
export 'utils.dart';
export 'operations.dart';

class Policy {
  late String name;
  late final List<Node> nodes;
  late final List<Edge> edges;

  Policy({required this.name, List<Node>? nodes, List<Edge>? edges})
      : nodes = nodes ?? [],
        edges = edges ?? [];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'edges': edges.map((edge) => edge.toJson()).toList(),
    };
  }

  Policy.fromJson(Map<String, dynamic> json) {
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

  Policy operator *(Policy otherPolicy) {
    return tensorProduct(this, otherPolicy);
  }

  static void validateEdges(List<Edge> edges) {
    final Map<Node, int> numOfEdgesPerNode = {};

    for (var edge in edges) {
      if (edge.source is BoundaryNode) {
        numOfEdgesPerNode[edge.source] = (numOfEdgesPerNode[edge.source] ?? 0) + 1;
      } else if (edge.target is BoundaryNode) {
        numOfEdgesPerNode[edge.target] = (numOfEdgesPerNode[edge.target] ?? 0) + 1;
      }
    }

    if (numOfEdgesPerNode.values.any((numOfEdges) => numOfEdges > 1)) {
      throw StateError("An 'Entry' or 'Exit' node can only have one outgoing/incoming edge!");
    }
  }
}
