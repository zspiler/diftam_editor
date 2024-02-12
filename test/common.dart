import 'package:poc/common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolicyData', () {
    test('toJSON', () {
      final stdout = ExitNode(Offset(100, 100), 'stdout');
      final pub = TagNode(Offset(200, 100), 'uihrguhi432', 'pub');
      final priv = TagNode(Offset(400, 100), 'iogjeoihrufw', 'priv');
      final dg = TagNode(Offset(300, 0), 'iogjeoihrufw', 'dg');
      final stdin = EntryNode(Offset(500, 100), 'stdin');
      final stdinPriv = Edge(stdin, priv, EdgeType.oblivious);
      final privPriv = Edge(priv, priv, EdgeType.oblivious);
      final privDg = Edge(priv, dg, EdgeType.aware);
      final dgPub = Edge(dg, pub, EdgeType.aware);
      final pubPriv = Edge(pub, priv, EdgeType.oblivious);
      final pubPub = Edge(pub, pub, EdgeType.oblivious);
      final pubStdout = Edge(pub, stdout, EdgeType.oblivious);

      final nodes = [stdout, pub, priv, dg, stdin];
      final edges = [stdinPriv, privPriv, privDg, dgPub, pubPriv, pubPub, pubStdout];

      final policy = PolicyData(name: 'Policy 1', nodes: nodes, edges: edges);

      const Map<String, dynamic> expectedJson = {
        "name": "Policy 1",
        "nodes": [
          {
            "type": "Exit",
            "descriptor": "stdout",
            "position": {"x": 100.0, "y": 100.0}
          },
          {
            "type": "Tag",
            "id": "uihrguhi432",
            "name": "pub",
            "position": {"x": 200.0, "y": 100.0}
          },
          {
            "type": "Tag",
            "id": "iogjeoihrufw",
            "name": "priv",
            "position": {"x": 400.0, "y": 100.0}
          },
          {
            "type": "Tag",
            "id": "iogjeoihrufw",
            "name": "dg",
            "position": {"x": 300.0, "y": 0.0}
          },
          {
            "type": "Entry",
            "descriptor": "stdin",
            "position": {"x": 500.0, "y": 100.0}
          }
        ],
        "edges": [
          {"source": "stdin", "target": "iogjeoihrufw", "type": "Oblivious"},
          {"source": "iogjeoihrufw", "target": "iogjeoihrufw", "type": "Oblivious"},
          {"source": "iogjeoihrufw", "target": "iogjeoihrufw", "type": "Aware"},
          {'source': 'iogjeoihrufw', 'target': 'uihrguhi432', 'type': 'Aware'},
          {"source": "uihrguhi432", "target": "iogjeoihrufw", "type": "Oblivious"},
          {"source": "uihrguhi432", "target": "uihrguhi432", "type": "Oblivious"},
          {"source": "uihrguhi432", "target": "stdout", "type": "Oblivious"}
        ]
      };

      expect(policy.toJson(), expectedJson);
    });
  });
}
