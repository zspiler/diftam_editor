import 'node.dart';

bool entryNodeWithDescriptorExists(List<Node> nodes, String descriptor) {
  return nodes.any((node) => node is EntryNode && node.descriptor == descriptor);
}

bool exitNodeWithDescriptorExists(List<Node> nodes, String descriptor) {
  return nodes.any((node) => node is ExitNode && node.descriptor == descriptor);
}
