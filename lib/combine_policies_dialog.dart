import 'package:flutter/material.dart';
import 'policy/policy.dart';

class CombinePoliciesDialog extends StatefulWidget {
  final Function(Policy newPolicy) onCombine;
  final List<Policy> policies;

  const CombinePoliciesDialog({required this.policies, required this.onCombine, super.key});

  @override
  State<CombinePoliciesDialog> createState() => _CombinePoliciesDialogState();
}

class _CombinePoliciesDialogState extends State<CombinePoliciesDialog> {
  List<Policy> policies = [];
  List<Policy> selectedPolicies = [];

  @override
  void initState() {
    super.initState();
    policies = List.from(widget.policies);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 500, // TODO responsive
        height: 700, // TODO responsive
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Combine policies', style: Theme.of(context).textTheme.headlineLarge),
              SizedBox(height: 10),
              Expanded(
                child: policies.isEmpty
                    ? Center(child: Text('No policies created yet.'))
                    : ListView.builder(
                        itemCount: policies.length,
                        itemBuilder: (BuildContext context, int index) {
                          return CheckboxListTile(
                            title: Text(policies[index].name),
                            value: selectedPolicies.contains(policies[index]),
                            enabled: selectedPolicies.length < 2 || selectedPolicies.contains(policies[index]),
                            onChanged: (bool? value) {
                              if (value == true) {
                                if (selectedPolicies.length < 2) {
                                  setState(() {
                                    selectedPolicies.add(policies[index]);
                                  });
                                }
                              } else {
                                setState(() {
                                  selectedPolicies.remove(policies[index]);
                                });
                              }
                              // (context as Element).markNeedsBuild();
                            },
                          );
                        },
                      ),
              ),
              SizedBox(height: 10),
              TextButton(
                child: Text("Combine"),
                onPressed: () {
                  final product = selectedPolicies[0] * selectedPolicies[1];
                  widget.onCombine(product);
                  Navigator.of(context).pop();
                },
                style: selectedPolicies.length < 2 ? ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.grey)) : null,
              ),
              SizedBox(height: 10),
              TextButton(
                child: Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
