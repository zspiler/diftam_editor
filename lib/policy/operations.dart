import 'policy.dart';
import 'utils.dart';

Policy tensorProduct(Policy policy1, Policy policy2) {
  final nodes1 = policy1.nodes;
  final nodes2 = policy2.nodes;

  final List<_CombinedNode> combinedNodes = cartesianProduct(nodes1, nodes2)
      .where((pair) => pair.$1.runtimeType == pair.$2.runtimeType)
      .map((pair) => _CombinedNode(source1: pair.$1, source2: pair.$2, type: pair.$1.type))
      .toList();

  // Find new edges
  final List<({_CombinedNode source, _CombinedNode destination, EdgeType type})> newEdges = [];

  cartesianProduct(combinedNodes, combinedNodes).forEach((pair) {
    final node1 = pair.$1;
    final node2 = pair.$2;

    for (var edge1 in policy1.edges) {
      if (edge1.source == node1.source1 && edge1.target == node2.source1) {
        final siblingEdgeExists = policy2.edges
            .any((edge2) => edge2.source == node1.source2 && edge2.target == node2.source2 && edge1.type == edge2.type);
        if (siblingEdgeExists) {
          newEdges.add((source: node1, destination: node2, type: edge1.type));
        }
      }
    }
  });

  // Generate nodes from temporary 'combinedNodes' which also hold information about original nodes
  final List<Node> nodes = combinedNodes.map((node) {
    final label = node.source1.label != node.source2.label
        ? '${node.source1.label}/${node.source2.label}'
        : node.source1.label; // we merge nodes with same label
    final position = node.source1.position + node.source2.position; // for presentation purposes, we sum original positions
    return node.type == NodeType.tag ? TagNode(position, label) : BoundaryNode.create(node.type, position, label);
  }).toList();

  // Generate edges
  final List<Edge> edges = newEdges.map((edge) {
    final sourceNode = nodes[combinedNodes.indexOf(edge.source)];
    final destinationNode = nodes[combinedNodes.indexOf(edge.destination)];
    return Edge(sourceNode, destinationNode, edge.type);
  }).toList();

  return Policy(name: '${policy1.name} x ${policy2.name}', nodes: nodes, edges: edges);
}

class _CombinedNode {
  final Node source1;
  final Node source2;
  final NodeType type;

  _CombinedNode({required this.source1, required this.source2, required this.type});

  @override
  String toString() {
    return 'CombinedNode{${source1.label}, ${source2.label}, $type}';
  }
}


// // TODO tests!
// Policy cartesianProduct(Policy policy1, Policy policy2) {
//   final List<_CombinedNode> combinedNodes = [];

//   final nodes1 = policy1.nodes;
//   final nodes2 = policy2.nodes;

//   for (var node1 in nodes1) {
//     for (var node2 in nodes2) {
//       // TODO - No edges from/to boundary nodes are created if we just match combine nodes of same type :(

//       NodeType? combinedNodeType;
//       if (node1 is EntryNode && node2 is EntryNode) {
//         combinedNodeType = NodeType.entry;
//       } else if (node1 is ExitNode && node2 is ExitNode) {
//         combinedNodeType = NodeType.exit;
//       } else if (node1 is TagNode && node2 is TagNode) {
//         combinedNodeType = NodeType.tag;
//       }

//       if (combinedNodeType != null) {
//         combinedNodes.add(_CombinedNode(source1: node1, source2: node2, type: combinedNodeType));
//       }
//     }
//   }

//   List<({int source, int destination, EdgeType type})> combineEdges(List<Edge> edges, {bool compareFirstComponent = true}) {
//     List<({int source, int destination, EdgeType type})> combinedEdges = [];
//     for (var edge in edges) {
//       for (var i = 0; i < combinedNodes.length; i++) {
//         for (var j = 0; j < combinedNodes.length; j++) {
//           if (i == j) continue;
//           var combinedNode1 = combinedNodes[i];
//           var combinedNode2 = combinedNodes[j];

//           if (combinedNode1 == combinedNode2) {
//             continue;
//           }

//           if (compareFirstComponent) {
//             if (combinedNode1.source2 != combinedNode2.source2) {
//               continue;
//             }
//           } else {
//             if (combinedNode1.source1 != combinedNode2.source1) {
//               continue;
//             }
//           }

//           final comparedComponent1 = compareFirstComponent ? combinedNode1.source1 : combinedNode1.source2;
//           final comparedComponent2 = compareFirstComponent ? combinedNode2.source1 : combinedNode2.source2;

//           if (edge.source == comparedComponent1 && edge.target == comparedComponent2) {
//             combinedEdges.add((source: i, destination: j, type: edge.type));
//           } else if (edge.source == comparedComponent2 && edge.target == comparedComponent1) {
//             combinedEdges.add((source: j, destination: i, type: edge.type));
//           }
//         }
//       }
//     }
//     return combinedEdges;
//   }

//   final newEdges = [
//     ...combineEdges(policy1.edges, compareFirstComponent: true),
//     ...combineEdges(policy2.edges, compareFirstComponent: false)
//   ];

//   List<Node> nodes = [];
//   List<Edge> edges = [];

//   for (var node in combinedNodes) {
//     final combinedLabel = '${node.source1.label}/${node.source2.label}';
//     final combinedPosition = node.source1.position + node.source2.position;
//     nodes.add(node.type == NodeType.tag
//         ? TagNode(combinedPosition, combinedLabel)
//         : BoundaryNode.create(node.type, combinedPosition, combinedLabel));
//   }

//   for (var edge in newEdges) {
//     edges.add(Edge(nodes[edge.source], nodes[edge.destination], edge.type));
//   }

//   return Policy(name: '${policy1.name} x ${policy2.name}', nodes: nodes, edges: edges);
// }