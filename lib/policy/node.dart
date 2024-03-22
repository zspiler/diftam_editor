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

  @override
  Node copyWith({Offset? position});

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
  String label; // TODO

  TagNode(Offset position, this.label) : super(position);

  @override
  TagNode copyWith({Offset? position, String? label}) {
    return TagNode(
      position ?? this.position,
      label ?? this.label,
    );
  }

  @override
  String toNodeString() {
    return 'TagNode ($label, $position)';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': NodeType.tag.value,
      'label': label,
      ...super.toJson(),
    };
  }

  TagNode.fromJson(Map<String, dynamic> json)
      : label = json['label'],
        super.fromJson(json);
}

abstract class BoundaryNode extends Node {
  // TODO descriptor and 'label' in TagNode could just be 'id'? Edge.fromJson would be simpler
  String descriptor;

  BoundaryNode(Offset position, this.descriptor) : super(position);

  factory BoundaryNode.create(NodeType nodeType, Offset position, String descriptor) {
    switch (nodeType) {
      case NodeType.entry:
        return EntryNode(position, descriptor);
      case NodeType.exit:
        return ExitNode(position, descriptor);
      default:
        throw Exception('$nodeType is not a boundary node!');
    }
  }

  @override
  String get label => descriptor;

  @override
  String toNodeString() {
    return 'BoundaryNode ($position, $descriptor)';
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
  EntryNode copyWith({Offset? position, String? descriptor}) {
    return EntryNode(
      position ?? this.position,
      descriptor ?? this.descriptor,
    );
  }

  @override
  String toNodeString() {
    return 'EntryNode{$position, $descriptor}';
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
  ExitNode copyWith({Offset? position, String? descriptor}) {
    return ExitNode(
      position ?? this.position,
      descriptor ?? this.descriptor,
    );
  }

  @override
  String toNodeString() {
    return 'ExitNode{$position, $descriptor}';
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
