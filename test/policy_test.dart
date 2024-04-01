import 'package:D2SC_editor/policy/policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Policy', () {
    test('valid', () {
      final priv = TagNode('priv');
      final pub = TagNode('priv');
      final stdin = EntryNode('stdin');
      final stdout = ExitNode('stdout');

      Policy(name: 'Policy 1', nodes: [
        priv,
        pub,
        stdin,
        stdout
      ], edges: [
        Edge(stdin, priv, EdgeType.boundary),
        Edge(priv, pub, EdgeType.oblivious),
        Edge(priv, pub, EdgeType.aware),
      ]);
    });

    group('validateEdges', () {
      test('invalid - multiple edges from a entry node', () {
        final priv = TagNode('priv');
        final pub = TagNode('priv');
        final stdin = EntryNode('stdin');

        final policy = Policy(name: 'Policy 1', nodes: [
          priv,
          pub,
          stdin,
        ], edges: [
          Edge(stdin, priv, EdgeType.boundary),
          Edge(stdin, pub, EdgeType.boundary),
        ]);

        expect(Policy.validateEdges(policy.edges), ["An 'Entry' or 'Exit' node can only have one outgoing/incoming edge!"]);
      });

      test('invalid - multiple edges to a exit node', () {
        final priv = TagNode('priv');
        final pub = TagNode('priv');
        final stdout = ExitNode('stdout');

        final policy = Policy(name: 'Policy 1', nodes: [
          priv,
          pub,
          stdout
        ], edges: [
          Edge(priv, stdout, EdgeType.boundary),
          Edge(pub, stdout, EdgeType.boundary),
        ]);

        expect(Policy.validateEdges(policy.edges), ["An 'Entry' or 'Exit' node can only have one outgoing/incoming edge!"]);
      });
    });
  });

  group('Edge', () {
    final priv = TagNode('priv');
    final pub = TagNode('priv');
    final stdin = EntryNode('stdin');
    final stdout = ExitNode('stdout');

    test('validation', () {
      expect(() => Edge(stdin, priv, EdgeType.boundary), returnsNormally);
      expect(() => Edge(priv, stdout, EdgeType.boundary), returnsNormally);
      expect(() => Edge(priv, priv, EdgeType.aware), returnsNormally);

      expect(() => Edge(priv, pub, EdgeType.boundary), throwsArgumentError);
      expect(() => Edge(stdin, priv, EdgeType.aware), throwsArgumentError);
      expect(() => Edge(priv, stdout, EdgeType.aware), throwsArgumentError);
      expect(() => Edge(stdin, stdin, EdgeType.boundary), throwsArgumentError);
      expect(() => Edge(stdout, stdout, EdgeType.boundary), throwsArgumentError);
      expect(() => Edge(priv, stdin, EdgeType.boundary), throwsArgumentError);
      expect(() => Edge(stdout, priv, EdgeType.boundary), throwsArgumentError);
    });
  });
}
