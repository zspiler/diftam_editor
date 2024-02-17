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
