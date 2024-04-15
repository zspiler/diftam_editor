import 'node.dart';
import 'edge.dart';
import '../utils.dart';

bool entryNodeWithDescriptorExists(List<Node> nodes, String descriptor) {
  return nodes.any((node) => node is EntryNode && node.descriptor == descriptor);
}

bool exitNodeWithDescriptorExists(List<Node> nodes, String descriptor) {
  return nodes.any((node) => node is ExitNode && node.descriptor == descriptor);
}

/*
  Because we represent two-way edges via two seperate edges we need to find the sibling edge of a given edge.
*/
Edge? getSiblingEdge(List<Edge> edges, Edge edge) {
  return firstOrNull(edges, (e) => e != edge && e.type == edge.type && e.source == edge.target && e.target == edge.source);
}

bool isOnlyEdgeTypeBetweenNodes(List<Edge> edges, Edge edge) {
  return edges.where((e) => e.source == edge.source && e.target == edge.target && e.type != edge.type).isEmpty;
}

Map<Node, List<Edge>> getLoopEdgesByNode(List<Edge> edges) {
  final Map<Node, List<Edge>> loopEdgesByNode = {};
  for (final edge in edges) {
    if (edge.source == edge.target) {
      loopEdgesByNode.putIfAbsent(edge.source, () => []).add(edge);
    }
  }
  return loopEdgesByNode;
}

bool anyEdgeOfDifferentTypeBetweenSameNodes(List<Edge> edges, Edge edge) {
  return edges.any((otherEdge) =>
      edge != otherEdge &&
      edge.type != otherEdge.type &&
      ((edge.source == otherEdge.source && edge.target == otherEdge.target) ||
          (edge.source == otherEdge.target && edge.target == otherEdge.source)));
}

List<(T, T)> cartesian<T>(List<T> list1, List<T> list2) {
  final List<(T, T)> result = [];
  for (var item1 in list1) {
    for (var item2 in list2) {
      result.add((item1, item2));
    }
  }
  return result;
}
