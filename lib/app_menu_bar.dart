import 'package:flutter/material.dart';
import 'package:D2SC_editor/d2sc_policy/lib/d2sc_policy.dart';

class AppMenuBar extends StatelessWidget {
  final List<Policy> policies;
  final Function(int index) onSelect;
  final Function() onAddPressed;
  final Function() onImportPressed;
  final Function() onManagePressed;
  final Function() onCombinePressed;
  final Function() onAnalyzePressed;
  final int currentPolicyIndex;

  const AppMenuBar(this.policies, this.currentPolicyIndex,
      {Key? key,
      required this.onSelect,
      required this.onAddPressed,
      required this.onImportPressed,
      required this.onManagePressed,
      required this.onCombinePressed,
      required this.onAnalyzePressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final foregroundColor = MaterialStateProperty.all<Color>(Colors.white);
    final backgroundColor = MaterialStateProperty.all<Color>(Colors.black.withAlpha(150));

    return Row(
      children: [
        Tooltip(
          message: 'Manage policies',
          child: SizedBox(
            height: 40,
            child: TextButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
              ),
              onPressed: onManagePressed,
              child: Icon(Icons.list),
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
        if (policies.isNotEmpty) ...[
          Tooltip(
            message: 'Combine policies',
            child: SizedBox(
              height: 40,
              child: TextButton(
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  )),
                  foregroundColor: foregroundColor,
                  backgroundColor: backgroundColor,
                ),
                onPressed: onCombinePressed,
                child: Icon(Icons.merge),
              ),
            ),
          ),
          Tooltip(
            message: 'Analyze policy',
            child: SizedBox(
              height: 40,
              child: TextButton(
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  )),
                  foregroundColor: foregroundColor,
                  backgroundColor: backgroundColor,
                ),
                onPressed: onAnalyzePressed,
                child: Icon(Icons.share_outlined),
              ),
            ),
          ),
        ],
        Tooltip(
          message: 'Create policy',
          child: SizedBox(
            height: 40,
            child: TextButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                  topRight: Radius.circular(policies.isEmpty ? 10 : 0),
                  bottomRight: Radius.circular(policies.isEmpty ? 10 : 0),
                ))),
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
              ),
              onPressed: onAddPressed,
              child: Icon(Icons.add),
            ),
          ),
        ),
        ...policies.asMap().entries.map((policy) {
          final index = policy.key;
          return SizedBox(
            height: 40,
            child: TextButton(
              style: ButtonStyle(
                splashFactory: NoSplash.splashFactory,
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                  topRight: Radius.circular(policy.value == policies.last ? 10 : 0),
                  bottomRight: Radius.circular(policy.value == policies.last ? 10 : 0),
                ))),
                foregroundColor: foregroundColor,
                backgroundColor: index == currentPolicyIndex ? MaterialStateProperty.all(Colors.blue) : backgroundColor,
              ),
              onPressed: () => onSelect(index),
              child: Text(policy.value.name),
            ),
          );
        }).toList(),
      ],
    );
  }
}
