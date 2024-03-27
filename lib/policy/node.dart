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

  factory Node.fromType(NodeType type, Offset position, String labelOrDescriptor) {
    return switch (type) {
      NodeType.tag => TagNode(position, labelOrDescriptor),
      NodeType.entry => EntryNode(position, labelOrDescriptor),
      NodeType.exit => ExitNode(position, labelOrDescriptor),
    };
  }

  Node.fromJson(Map<String, dynamic> json)
      : position = Offset((json['position']['x'] as num).toDouble(), (json['position']['y'] as num).toDouble());

  @override
  Node copyWith({Offset? position});

  String get label;
  NodeType get type;

  String toNodeString();

  @override
  String toString() => toNodeString(); // require that subclasses to implement their own toString method!

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'position': {'x': position.dx, 'y': position.dy},
    };
  }
}

class TagNode extends Node {
  @override
  String label;

  TagNode(Offset position, this.label) : super(position);

  @override
  TagNode copyWith({Offset? position, String? label}) {
    return TagNode(position ?? this.position, label ?? this.label);
  }

  TagNode.fromJson(Map<String, dynamic> json)
      : label = json['label'],
        super.fromJson(json);

  @override
  NodeType get type => NodeType.tag;

  @override
  String toNodeString() => 'TagNode($label, $position)';

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'label': label,
    };
  }
}

abstract class BoundaryNode extends Node {
  String descriptor;

  BoundaryNode(Offset position, this.descriptor) : super(position);

  BoundaryNode.fromJson(Map<String, dynamic> json)
      : descriptor = json['descriptor'],
        super.fromJson(json);

  @override
  String get label => descriptor;

  @override
  String toNodeString() => 'BoundaryNode($descriptor, $position)';

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'descriptor': descriptor,
    };
  }
}

class EntryNode extends BoundaryNode {
  EntryNode(Offset position, String descriptor) : super(position, descriptor);

  @override
  EntryNode copyWith({Offset? position, String? descriptor}) {
    return EntryNode(position ?? this.position, descriptor ?? this.descriptor);
  }

  EntryNode.fromJson(Map<String, dynamic> json) : super.fromJson(json);

  @override
  NodeType get type => NodeType.entry;

  @override
  String toNodeString() => 'EntryNode($descriptor, $position)';
}

class ExitNode extends BoundaryNode {
  ExitNode(Offset position, String descriptor) : super(position, descriptor);

  @override
  ExitNode copyWith({Offset? position, String? descriptor}) {
    return ExitNode(position ?? this.position, descriptor ?? this.descriptor);
  }

  ExitNode.fromJson(Map<String, dynamic> json) : super.fromJson(json);

  @override
  NodeType get type => NodeType.exit;

  @override
  String toNodeString() => 'ExitNode($descriptor, $position)';
}
