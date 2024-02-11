import 'package:flutter/material.dart';
import 'common.dart';

class PolicyTabBar extends StatelessWidget {
  final List<PolicyData> policies;
  final Function(int index) onSelect;
  final Function() onAddPressed;
  final Function() onManagePressed;
  final int currentPolicyIndex;

  PolicyTabBar(this.policies, this.currentPolicyIndex,
      {Key? key, required this.onSelect, required this.onAddPressed, required this.onManagePressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
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
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  backgroundColor: index == currentPolicyIndex
                      ? MaterialStateProperty.all<Color>(Colors.blue)
                      : MaterialStateProperty.all<Color>(Colors.black.withAlpha(150)),
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
                  shape:
                      MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.black.withAlpha(150)),
                ),
                onPressed: onAddPressed,
                child: Icon(Icons.add),
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
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.black.withAlpha(150)),
                ),
                onPressed: onManagePressed,
                child: Icon(Icons.list),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
