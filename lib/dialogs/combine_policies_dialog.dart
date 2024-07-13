import 'package:flutter/material.dart';
import 'package:D2SC_editor/d2sc_policy/lib/d2sc_policy.dart';
import 'package:D2SC_editor/dialogs/my_dialog.dart';

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

  var selectedMethod = 0;
  final methods = [
    (name: 'Tensor product', func: tensorProduct),
    (name: 'Cartesian product', func: cartesianProduct),
  ];

  @override
  void initState() {
    super.initState();
    policies = List.from(widget.policies);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedDialog(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 32.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text('Combine policies', style: Theme.of(context).textTheme.headlineLarge),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 128.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
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
              ),
              ToggleButtons(
                onPressed: (int index) {
                  setState(() => selectedMethod = index);
                },
                isSelected: List.generate(methods.length, (index) => index == selectedMethod),
                borderRadius: BorderRadius.circular(10.0), // Curved edges for buttons
                constraints: BoxConstraints(minWidth: 160.0, minHeight: kMinInteractiveDimension),
                children: methods
                    .map((method) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Adjust padding as needed
                          child: Text(method.name),
                        ))
                    .toList(),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  final product = methods[selectedMethod].func(selectedPolicies[0], selectedPolicies[1]);
                  widget.onCombine(product);
                  Navigator.of(context).pop();
                },
                style: selectedPolicies.length < 2 ? ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.grey)) : null,
                child: Text("Combine"),
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
