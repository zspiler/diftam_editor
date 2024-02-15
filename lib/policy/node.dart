import 'package:flutter/material.dart';
import 'graph_object.dart';

enum NodeType {
  tag('Tag'),
  entry('Entry'),
  exit('Exit');

  final String value;

  const NodeType(this.value);
}

abstract class Node implements GraphObject {
  Offset position;

  Node(this.position);

  String get label;

  @override
  String toString() => toNodeString(); // require that subclasses to implement their own toString method

  String toNodeString();

  Map<String, dynamic> toJson() {
    return {
      'position': {'x': position.dx, 'y': position.dy},
    };
  }

  Node.fromJson(Map<String, dynamic> json)
      : position = Offset((json['position']['x'] as num).toDouble(), (json['position']['y'] as num).toDouble());
}

class TagNode extends Node {
  final String id;
  String? name;

  TagNode(Offset position, this.id, [this.name]) : super(position);

  @override
  String get label => name ?? id;

  @override
  String toNodeString() {
    return 'Tag ($id, $label)';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': NodeType.tag.value,
      'id': id,
      'name': name,
      ...super.toJson(),
    };
  }

  TagNode.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        super.fromJson(json);
}

abstract class BoundaryNode extends Node {
  // TODO descriptor could just be 'id'? Edge.fromJson would be simpler

  String descriptor;

  BoundaryNode(Offset position, this.descriptor) : super(position);

  @override
  String get label => descriptor;

  @override
  String toNodeString() {
    return 'BoundaryNode ($descriptor)';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'descriptor': descriptor,
      ...super.toJson(),
    };
  }

  BoundaryNode.fromJson(Map<String, dynamic> json)
      : descriptor = json['descriptor'],
        super.fromJson(json);
}

class EntryNode extends BoundaryNode {
  EntryNode(Offset position, String descriptor) : super(position, descriptor);

  @override
  String toNodeString() {
    return 'EntryNode{$descriptor}';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': NodeType.entry.value,
      ...super.toJson(),
    };
  }

  EntryNode.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}

class ExitNode extends BoundaryNode {
  ExitNode(Offset position, String descriptor) : super(position, descriptor);

  @override
  String toNodeString() {
    return 'ExitNode{$descriptor}';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': NodeType.exit.value,
      ...super.toJson(),
    };
  }

  ExitNode.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}
