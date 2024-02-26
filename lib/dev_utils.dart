import 'package:flutter/material.dart';
import 'policy/policy.dart';

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
