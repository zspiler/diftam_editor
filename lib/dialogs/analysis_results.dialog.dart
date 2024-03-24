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

  @override
  void initState() {
    super.initState();

    awareComponents = findGraphComponents(widget.policy, EdgeType.aware);
    obliviousComponents = findGraphComponents(widget.policy, EdgeType.oblivious);
  }

  Widget buildComponentRow(BuildContext context, List<Node> component) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: component
                .expand((node) => [
                      HighlightBox(child: Text(node.label, style: Theme.of(context).textTheme.titleMedium)),
                      SizedBox(width: 5),
                    ])
                .toList()),
      );

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
                if (awareComponents != null && obliviousComponents != null) ...[
                  SizedBox(height: 20),
                  Column(children: [
                    Text('Aware', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 5),
                    ...awareComponents!.map((component) =>
                        Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: buildComponentRow(context, component))),
                    SizedBox(height: 20),
                    Text('Oblivious', style: Theme.of(context).textTheme.titleLarge),
                    ...obliviousComponents!.map((component) =>
                        Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: buildComponentRow(context, component))),
                  ])
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
