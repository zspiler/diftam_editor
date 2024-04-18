import 'policy.dart';

typedef GraphComponent = List<Node>;

List<GraphComponent> findComponents(Policy policy, EdgeType edgeType) {
  final List<List<Node>> components = [];
  final List<Node> visited = [];

  void dfs(Node node, List<Node> component) {
    if (visited.contains(node)) {
      return;
    }
    visited.add(node);
    component.add(node);
    for (var edge in policy.edges) {
      if (edge.type == edgeType) {
        // NOTE: We don't care about the direction of the edge
        if (edge.source == node) {
          dfs(edge.target, component);
        } else if (edge.target == node) {
          dfs(edge.source, component);
        }
      }
    }
  }

  for (var node in policy.nodes) {
    if (!visited.contains(node)) {
      List<Node> component = [];
      dfs(node, component);
      components.add(component);
    }
  }

  return components;
}

List<List<Node>> findCycles(Policy policy, EdgeType edgeType) {
  final List<List<Node>> cycles = [];
  final Map<Node, Node> parentMap = {};
  final visited = <Node>{};
  final finished = <Node>{};

  void dfs(Node node, List<Node> path) {
    if (visited.contains(node)) {
      if (!finished.contains(node)) {
        Node? current = node;
        List<Node> cycle = [current];

        while (true) {
          current = parentMap[current] != current ? parentMap[current] : null;
          if (current == null || current == node) {
            break;
          }
          cycle.add(current);
        }

        cycle.add(node);
        cycles.add(cycle.reversed.toList());
      }
      return;
    }

    if (finished.contains(node)) {
      return;
    }

    visited.add(node);
    path.add(node);

    final neighbours = policy.edges.where((edge) => edge.type == edgeType && edge.source == node).map((edge) => edge.target);
    for (var neighbour in neighbours) {
      parentMap[neighbour] = node;
      dfs(neighbour, List<Node>.from(path));
    }

    path.remove(node);
    finished.add(node);
  }

  for (var node in policy.nodes) {
    dfs(node, []);
  }

  return cycles;
}

List<TagNode> findLoneTags(Policy policy) {
  final List<TagNode> tags = policy.nodes.whereType<TagNode>().toList();

  final List<Node> visited = [];

  void dfs(Node node) {
    if (visited.contains(node)) {
      return;
    }

    visited.add(node);

    final neighbours = policy.edges.where((edge) => edge.source == node).map((edge) => edge.target);
    for (var neighbour in neighbours) {
      dfs(neighbour);
    }
  }

  for (var node in policy.nodes) {
    if (node is EntryNode) {
      dfs(node);
    }
  }

  return tags.where((tag) => !visited.contains(tag)).toList();
}
