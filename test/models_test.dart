import 'package:D2SC_editor/policy/policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolicyData', () {
    group('serialization & deserialization', () {
      const Map<String, dynamic> exampleJson = {
        "name": "Policy 1",
        "nodes": [
          {
            "type": "Tag",
            "label": "priv",
            "position": {"x": 500.0, "y": 350.0}
          },
          {
            "type": "Tag",
            "label": "pub",
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
          {"source": "stdin", "target": "priv", "type": "Boundary"},
          {"source": "priv", "target": "pub", "type": "Oblivious"},
          {"source": "priv", "target": "pub", "type": "Aware"},
          {"source": "pub", "target": "pub", "type": "Aware"},
          {"source": "pub", "target": "pub", "type": "Oblivious"},
          {"source": "pub", "target": "priv", "type": "Aware"},
          {"source": "pub", "target": "stdout", "type": "Boundary"}
        ]
      };

      final priv = TagNode('priv', Offset(500, 350));
      final pub = TagNode('pub', Offset(700, 350));
      final stdin = EntryNode('stdin', Offset(300, 250));
      final stdout = ExitNode('stdout', Offset(900, 250));

      final examplePolicy = Policy(name: 'Policy 1', nodes: [
        priv,
        pub,
        stdin,
        stdout
      ], edges: [
        Edge(stdin, priv, EdgeType.boundary),
        Edge(priv, pub, EdgeType.oblivious),
        Edge(priv, pub, EdgeType.aware),
        Edge(pub, pub, EdgeType.aware),
        Edge(pub, pub, EdgeType.oblivious),
        Edge(pub, priv, EdgeType.aware),
        Edge(pub, stdout, EdgeType.boundary),
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
