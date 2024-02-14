import 'package:poc/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolicyData', () {
    group('serialization & deserialization', () {
      const Map<String, dynamic> exampleJson = {
        "name": "Policy 1",
        "nodes": [
          {
            "type": "Tag",
            "id": "privID",
            "name": "priv",
            "position": {"x": 500.0, "y": 350.0}
          },
          {
            "type": "Tag",
            "id": "pubID",
            "name": "pub",
            "position": {"x": 700.0, "y": 350.0}
          },
          {
            "type": "Entry",
            "descriptor": "stdin",
            "position": {"x": 300.0, "y": 250.0}
          },
          {
            "type": "Exit",
            "descriptor": "stdout",
            "position": {"x": 900.0, "y": 250.0}
          }
        ],
        "edges": [
          {"source": "stdin", "target": "privID", "type": "Aware"},
          {"source": "privID", "target": "pubID", "type": "Oblivious"},
          {"source": "privID", "target": "pubID", "type": "Aware"},
          {"source": "pubID", "target": "pubID", "type": "Aware"},
          {"source": "pubID", "target": "pubID", "type": "Oblivious"},
          {"source": "pubID", "target": "privID", "type": "Aware"},
          {"source": "pubID", "target": "stdout", "type": "Aware"}
        ]
      };

      final priv = TagNode(Offset(500, 350), 'privID', 'priv');
      final pub = TagNode(Offset(700, 350), 'pubID', 'pub');
      final stdin = EntryNode(Offset(300, 250), 'stdin');
      final stdout = ExitNode(Offset(900, 250), 'stdout');

      final examplePolicy = Policy(name: 'Policy 1', nodes: [
        priv,
        pub,
        stdin,
        stdout
      ], edges: [
        Edge(stdin, priv, EdgeType.aware),
        Edge(priv, pub, EdgeType.oblivious),
        Edge(priv, pub, EdgeType.aware),
        Edge(pub, pub, EdgeType.aware),
        Edge(pub, pub, EdgeType.oblivious),
        Edge(pub, priv, EdgeType.aware),
        Edge(pub, stdout, EdgeType.aware),
      ]);

      test('toJSON', () {
        const Map<String, dynamic> expectedJson = exampleJson;

        expect(examplePolicy.toJson(), expectedJson);
      });

      // TODO - how to test?
      // test('fromJSON', () {
      //   const json = exampleJson;
      //   final PolicyData policy = PolicyData.fromJson(json);
      // });
    });
  });
}
