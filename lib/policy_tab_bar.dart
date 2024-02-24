import 'package:flutter/material.dart';
import 'policy/policy.dart';

class PolicyTabBar extends StatelessWidget {
  final List<Policy> policies;
  final Function(int index) onSelect;
  final Function() onAddPressed;
  final Function() onImportPressed;
  final Function() onManagePressed;
  final int currentPolicyIndex;

  const PolicyTabBar(this.policies, this.currentPolicyIndex,
      {Key? key,
      required this.onSelect,
      required this.onAddPressed,
      required this.onImportPressed,
      required this.onManagePressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final foregroundColor = MaterialStateProperty.all<Color>(Colors.white);
    final backgroundColor = MaterialStateProperty.all<Color>(Colors.black.withAlpha(150));

    return Row(
      children: [
        ...policies.asMap().entries.map((policy) {
          final index = policy.key;
          return SizedBox(
            height: 40,
            child: TextButton(
              style: ButtonStyle(
                splashFactory: NoSplash.splashFactory,
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(index == 0 ? 10 : 0),
                  bottomLeft: Radius.circular(index == 0 ? 10 : 0),
                ))),
                foregroundColor: foregroundColor,
                backgroundColor: index == currentPolicyIndex ? MaterialStateProperty.all<Color>(Colors.blue) : backgroundColor,
              ),
              onPressed: () => onSelect(index),
              child: Text(policy.value.name),
            ),
          );
        }).toList(),
        Tooltip(
          message: 'Create policy',
          child: SizedBox(
            height: 40,
            child: TextButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
              ),
              onPressed: onAddPressed,
              child: Icon(Icons.add),
            ),
          ),
        ),
        Tooltip(
          message: 'Import policy',
          child: SizedBox(
            height: 40,
            child: TextButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
              ),
              onPressed: onImportPressed,
              child: Icon(Icons.upload),
            ),
          ),
        ),
        Tooltip(
          message: 'Manage policies',
          child: SizedBox(
            height: 40,
            child: TextButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
                  ),
                ),
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
              ),
              onPressed: onManagePressed,
              child: Icon(Icons.list),
            ),
          ),
        ),
      ],
    );
  }
}
