import 'package:flutter/material.dart';
import '../policy/policy.dart';

Policy getMockPolicy() {
  // TODO ensure unique IDS?
  final priv = TagNode(Offset(500, 350), 'priv');
  final pub = TagNode(Offset(700, 350), 'pub');
  final stdin = EntryNode(Offset(300, 250), 'stdin');
  final stdout = ExitNode(Offset(900, 250), 'stdout');

  return Policy(name: 'Policy 1', nodes: [
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
}

List<Policy> getMockPolicies() {
  Node stdin1 = EntryNode(Offset(0, 0), 'stdin1');
  Node x = TagNode(Offset(100, 100), 'X');
  Node y = TagNode(Offset(100, 250), 'Y');

  Edge stdinX = Edge(stdin1, x, EdgeType.oblivious);
  Edge xy = Edge(x, y, EdgeType.aware);

  Policy p1 = Policy(name: 'Policy 1', nodes: [x, y, stdin1], edges: [xy, stdinX]);

  Node stdin2 = EntryNode(Offset(0, 0), 'stdin2');
  Node a = TagNode(Offset(100, 100), 'A');
  Node b = TagNode(Offset(250, 100), 'B');
  Node c = TagNode(Offset(400, 100), 'C');
  Node d = TagNode(Offset(550, 100), 'D');

  Edge stdin2A = Edge(stdin2, a, EdgeType.oblivious);
  Edge ab = Edge(a, b, EdgeType.oblivious);
  Edge bc = Edge(b, c, EdgeType.oblivious);
  Edge cd = Edge(c, d, EdgeType.oblivious);

  Policy p2 = Policy(name: 'Policy 2', nodes: [a, b, c, d, stdin2], edges: [ab, bc, cd, stdin2A]);

  return [p1, p2];
}
