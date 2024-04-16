import 'policy.dart';

typedef _CombinedNode = ({Node source1, Node source2, NodeType type});
typedef _CombinedEdge = ({_CombinedNode source, _CombinedNode destination, EdgeType type});

/*
Tensor product

vertices (g, h) and (g', h') are adjacent in G × H if and only if
  g is adjacent to g' in G, and
  h is adjacent to h' in H.
 */
Policy tensorProduct(Policy policy1, Policy policy2) {
  List<_CombinedEdge> combineEdges(Policy policy1, Policy policy2, List<_CombinedNode> combinedNodes) {
    List<_CombinedEdge> newEdges = [];
    for (var node1 in combinedNodes) {
      for (var node2 in combinedNodes) {
        for (var edge1 in policy1.edges) {
          if (edge1.source == node1.source1 && edge1.target == node2.source1) {
            // Component A of source node must be connected to component A of destination node and vice versa.
            // We require that the edge type is the same. If we don't we'd have to prefer one edge type to another..
            final siblingEdgeExists = policy2.edges
                .any((edge2) => edge2.source == node1.source2 && edge2.target == node2.source2 && edge1.type == edge2.type);
            if (siblingEdgeExists) {
              newEdges.add((source: node1, destination: node2, type: edge1.type));
            }
          }
        }
      }
    }
    return newEdges;
  }

  final combinedNodes = cartesian(policy1.nodes, policy2.nodes)
      .where((pair) => pair.$1.runtimeType == pair.$2.runtimeType)
      .map((pair) => (source1: pair.$1, source2: pair.$2, type: pair.$1.type))
      .toList();
  final combinedEdges = combineEdges(policy1, policy2, combinedNodes);

  final nodes = _createNodesFromCombined(combinedNodes);
  final edges = _createEdgesFromCombined(combinedEdges, combinedNodes, nodes);

  return Policy(name: '${policy1.name} x ${policy2.name}', nodes: nodes, edges: edges);
}

/*
Cartesian product

two vertices (u,v) and (u' ,v' ) are adjacent in G □ H if and only if either
  u = u' and v is adjacent to v' in H, or
  v = v' and u is adjacent to u' in G.
 */
Policy cartesianProduct(Policy policy1, Policy policy2) {
  final combinedNodes = cartesian(policy1.nodes, policy2.nodes)
      .where((pair) => pair.$1.runtimeType == pair.$2.runtimeType)
      .map((pair) => (source1: pair.$1, source2: pair.$2, type: pair.$1.type))
      .toList();

  // TODO refactor
  List<_CombinedEdge> combineEdges(List<Edge> edges, {bool compareFirstComponent = true}) {
    List<_CombinedEdge> combinedEdges = [];
    for (var edge in edges) {
      for (var i = 0; i < combinedNodes.length; i++) {
        for (var j = 0; j < combinedNodes.length; j++) {
          if (i == j) continue;
          var combinedNode1 = combinedNodes[i];
          var combinedNode2 = combinedNodes[j];

          if (combinedNode1 == combinedNode2) {
            continue;
          }

          if (compareFirstComponent) {
            if (combinedNode1.source2 != combinedNode2.source2) {
              continue;
            }
          } else {
            if (combinedNode1.source1 != combinedNode2.source1) {
              continue;
            }
          }

          final comparedComponent1 = compareFirstComponent ? combinedNode1.source1 : combinedNode1.source2;
          final comparedComponent2 = compareFirstComponent ? combinedNode2.source1 : combinedNode2.source2;

          if (edge.source == comparedComponent1 && edge.target == comparedComponent2) {
            combinedEdges.add((source: combinedNodes[i], destination: combinedNodes[j], type: edge.type));
          } else if (edge.source == comparedComponent2 && edge.target == comparedComponent1) {
            combinedEdges.add((source: combinedNodes[j], destination: combinedNodes[i], type: edge.type));
          }
        }
      }
    }
    return combinedEdges;
  }

  final combinedEdges = [
    ...combineEdges(policy1.edges, compareFirstComponent: true),
    ...combineEdges(policy2.edges, compareFirstComponent: false)
  ];

  final nodes = _createNodesFromCombined(combinedNodes);
  final edges = _createEdgesFromCombined(combinedEdges, combinedNodes, nodes);

  return Policy(name: '${policy1.name} x ${policy2.name}', nodes: nodes, edges: edges);
}

// Helpers

List<Node> _createNodesFromCombined(List<_CombinedNode> combinedNodes) {
  return combinedNodes.map((node) {
    final label = node.source1.label != node.source2.label ? '${node.source1.label}/${node.source2.label}' : node.source1.label;
    final position = node.source1.position + node.source2.position;
    return Node.fromType(node.type, label, position);
  }).toList();
}

List<Edge> _createEdgesFromCombined(List<_CombinedEdge> combinedEdges, List<_CombinedNode> combinedNodes, List<Node> nodes) {
  return combinedEdges.map((edge) {
    final sourceNode = nodes[combinedNodes.indexOf(edge.source)];
    final destinationNode = nodes[combinedNodes.indexOf(edge.destination)];
    return Edge(sourceNode, destinationNode, edge.type);
  }).toList();
}
