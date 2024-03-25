import 'package:flutter/material.dart';
import '../policy/policy.dart';
import '../ui/highlight_box.dart';

class AnalysisResultsDialog extends StatefulWidget {
  final Policy policy;

  const AnalysisResultsDialog({required this.policy, super.key});

  @override
  State<AnalysisResultsDialog> createState() => _AnalysisResultsDialogState();
}

class _AnalysisResultsDialogState extends State<AnalysisResultsDialog> {
  late final List<GraphComponent>? awareComponents;
  late final List<GraphComponent>? obliviousComponents;
  late final List<List<Node>> awareCycles;
  late final List<List<Node>> obliviousCycles;

  @override
  void initState() {
    super.initState();

    // TODO do aware & oblivious inside function itself?

    // TODO boundary nodes?
    awareComponents = findComponents(widget.policy, EdgeType.aware);
    obliviousComponents = findComponents(widget.policy, EdgeType.oblivious);

    // TODO boundary nodes?
    awareCycles = findCycles(widget.policy, EdgeType.aware);
    obliviousCycles = findCycles(widget.policy, EdgeType.oblivious);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 32.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('Policy analysis', style: Theme.of(context).textTheme.headlineLarge),
                SizedBox(height: 20),
                Text('Graph components', style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 20),
                if (awareComponents != null || obliviousComponents != null) ...[
                  _NodeGroupsSection(context: context, title: 'Aware', groups: awareComponents!, directed: false),
                  SizedBox(height: 20),
                  _NodeGroupsSection(context: context, title: 'Oblivious', groups: obliviousComponents!, directed: false),
                ] else
                  Text('No components found', style: Theme.of(context).textTheme.titleMedium),
                Divider(height: 50),
                Text('Graph cycles', style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 20),
                if (awareCycles.isNotEmpty || obliviousCycles.isNotEmpty) ...[
                  _NodeGroupsSection(context: context, title: 'Aware', groups: awareCycles, directed: true),
                  SizedBox(height: 20),
                  _NodeGroupsSection(context: context, title: 'Oblivious', groups: obliviousCycles, directed: true),
                ] else
                  Text('No cycles found', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeRow extends StatelessWidget {
  final List<Node> component;
  final bool directed;
  final BuildContext context;

  const _NodeRow({
    Key? key,
    required this.context,
    required this.component,
    this.directed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: component.asMap().entries.expand((entry) {
          int index = entry.key;
          Node node = entry.value;
          return [
            HighlightBox(child: Text(node.label, style: Theme.of(context).textTheme.titleMedium)),
            SizedBox(width: 5),
            if (directed && index != component.length - 1) ...[
              Text('->', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(width: 5),
            ],
          ];
        }).toList(),
      ),
    );
  }
}

class _NodeGroupsSection extends StatelessWidget {
  final String title;
  final List<List<Node>> groups;
  final bool directed;
  final BuildContext context;

  const _NodeGroupsSection({
    Key? key,
    required this.context,
    required this.title,
    required this.groups,
    this.directed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 5),
        if (groups.isNotEmpty)
          ...groups.map((component) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: _NodeRow(context: context, component: component, directed: directed)))
        else
          Text('/'),
      ],
    );
  }
}
