import 'policy.dart';

// TODO tests!
Policy cartesianProduct(Policy policy1, Policy policy2) {
  final List<_CombinedNode> combinedNodes = [];

  final nodes1 = policy1.nodes;
  final nodes2 = policy2.nodes;

  for (var node1 in nodes1) {
    for (var node2 in nodes2) {
      // TODO - No edges from/to boundary nodes are created if we just match combine nodes of same type :(

      NodeType? combinedNodeType;
      if (node1 is EntryNode && node2 is EntryNode) {
        combinedNodeType = NodeType.entry;
      } else if (node1 is ExitNode && node2 is ExitNode) {
        combinedNodeType = NodeType.exit;
      } else if (node1 is TagNode && node2 is TagNode) {
        combinedNodeType = NodeType.tag;
      }

      if (combinedNodeType != null) {
        combinedNodes.add(_CombinedNode(node1: node1, node2: node2, type: combinedNodeType));
      }
    }
  }

  List<({int source, int destination, EdgeType type})> combineEdges(List<Edge> edges, {bool compareFirstComponent = true}) {
    List<({int source, int destination, EdgeType type})> combinedEdges = [];
    for (var edge in edges) {
      for (var i = 0; i < combinedNodes.length; i++) {
        for (var j = 0; j < combinedNodes.length; j++) {
          if (i == j) continue;
          var combinedNode1 = combinedNodes[i];
          var combinedNode2 = combinedNodes[j];

          if (combinedNode1 == combinedNode2 ||
              (compareFirstComponent ? combinedNode1.node2 != combinedNode2.node2 : combinedNode1.node1 != combinedNode2.node1)) {
            continue;
          }

          final comparedComponent1 = compareFirstComponent ? combinedNode1.node1 : combinedNode1.node2;
          final comparedComponent2 = compareFirstComponent ? combinedNode2.node1 : combinedNode2.node2;

          if (edge.source == comparedComponent1 && edge.target == comparedComponent2) {
            combinedEdges.add((source: i, destination: j, type: edge.type));
          } else if (edge.source == comparedComponent2 && edge.target == comparedComponent1) {
            combinedEdges.add((source: j, destination: i, type: edge.type));
          }
        }
      }
    }
    return combinedEdges;
  }

  final newEdges = [
    ...combineEdges(policy1.edges, compareFirstComponent: true),
    ...combineEdges(policy2.edges, compareFirstComponent: false)
  ];

  List<Node> nodes = [];
  List<Edge> edges = [];

  for (var node in combinedNodes) {
    final combinedLabel = '${node.node1.label}/${node.node2.label}';
    final combinedPosition = node.node1.position + node.node2.position;
    nodes.add(node.type == NodeType.tag
        ? TagNode(combinedPosition, combinedLabel)
        : BoundaryNode.create(node.type, combinedPosition, combinedLabel));
  }

  for (var edge in newEdges) {
    edges.add(Edge(nodes[edge.source], nodes[edge.destination], edge.type));
  }

  return Policy(name: '$policy1.name x ${policy2.name}', nodes: nodes, edges: edges);
}

class _CombinedNode {
  final Node node1;
  final Node node2;
  final NodeType type;

  _CombinedNode({required this.node1, required this.node2, required this.type});
}
