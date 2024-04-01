import 'dart:ui' show Offset;
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

  Node(Offset? position) : position = position ?? Offset(0, 0);

  factory Node.fromType(NodeType type, String labelOrDescriptor, [Offset? position]) {
    return switch (type) {
      NodeType.tag => TagNode(labelOrDescriptor, position),
      NodeType.entry => EntryNode(labelOrDescriptor, position),
      NodeType.exit => ExitNode(labelOrDescriptor, position),
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

  TagNode(this.label, [Offset? position]) : super(position);

  @override
  TagNode copyWith({Offset? position, String? label}) {
    return TagNode(label ?? this.label, position ?? this.position);
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

  BoundaryNode(this.descriptor, [Offset? position]) : super(position);

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
  EntryNode(String descriptor, [Offset? position]) : super(descriptor, position);

  @override
  EntryNode copyWith({Offset? position, String? descriptor}) {
    return EntryNode(descriptor ?? this.descriptor, position ?? this.position);
  }

  EntryNode.fromJson(Map<String, dynamic> json) : super.fromJson(json);

  @override
  NodeType get type => NodeType.entry;

  @override
  String toNodeString() => 'EntryNode($descriptor, $position)';
}

class ExitNode extends BoundaryNode {
  ExitNode(String descriptor, [Offset? position]) : super(descriptor, position);

  @override
  ExitNode copyWith({Offset? position, String? descriptor}) {
    return ExitNode(descriptor ?? this.descriptor, position ?? this.position);
  }

  ExitNode.fromJson(Map<String, dynamic> json) : super.fromJson(json);

  @override
  NodeType get type => NodeType.exit;

  @override
  String toNodeString() => 'ExitNode($descriptor, $position)';
}
