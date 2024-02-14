import 'package:flutter/material.dart';
import 'ui/custom_dialog.dart';
import 'ui/snackbar.dart';
import 'models.dart';
import 'export.dart';

class ManagePoliciesDialog extends StatefulWidget {
  final Function(List<PolicyData> updatedPolicies) onChange;
  final Function(int index) onDeletePress;
  final List<PolicyData> policies;

  const ManagePoliciesDialog({required this.policies, required this.onChange, required this.onDeletePress, super.key});

  @override
  _ManagePoliciesDialogState createState() => _ManagePoliciesDialogState();
}

class _ManagePoliciesDialogState extends State<ManagePoliciesDialog> {
  List<PolicyData> _policies = [];

  @override
  void initState() {
    super.initState();
    _policies = List.from(widget.policies);
  }

  TableRow buildTableSpacer(double height) => TableRow(
      children: [SizedBox(height: height), SizedBox(height: height), SizedBox(height: height), SizedBox(height: height)]);

  List<TableRow> buildPoliciesTableRows() {
    List<TableRow> rowsWithSpacers = _policies.fold<List<TableRow>>([], (List<TableRow> accumulator, policy) {
      final name = policy.name;

      accumulator.add(TableRow(children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(child: Text(name, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.left)),
        ),
        TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Container(
              child: Align(
                alignment: Alignment.center,
                child: Tooltip(
                  message: 'Rename',
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.edit, size: 16.0),
                      onPressed: () {
                        CustomDialog.showInputDialog(
                          context,
                          title: 'Rename policy',
                          hint: 'Enter policy name',
                          acceptEmptyInput: true,
                          initialText: policy.name,
                          onConfirm: (String inputText) {
                            if (inputText.isEmpty) {
                              return;
                            }
                            setState(() {
                              policy.name = inputText;
                            });
                            widget.onChange(_policies);
                          },
                          isInputValid: (String inputText) => !_policies.any((p) => p != policy && p.name == inputText),
                          errorMessage: 'Policy with this name already exists!',
                        );
                      },
                    ),
                  ),
                ),
              ),
            )),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            child: Align(
              alignment: Alignment.center,
              child: Tooltip(
                  message: "Export",
                  child: IconButton(
                    icon: Icon(Icons.download),
                    onPressed: () async {
                      try {
                        await exportPolicy(policy);
                      } catch (e) {
                        SnackbarGlobal.error('Failed to save policy');
                      }
                    },
                  )),
            ),
          ),
        ),
        _policies.length > 1
            ? TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Container(
                  child: Align(
                    alignment: Alignment.center,
                    child: Tooltip(
                        message: "Delete",
                        child: IconButton(
                          icon: Icon(Icons.delete_rounded, color: Colors.red),
                          onPressed: () {
                            CustomDialog.showConfirmationDialog(context,
                                confirmButtonText: 'Delete',
                                title: 'Are you sure you want to delete this policy?', onConfirm: () {
                              final indexOfDeletedPolicy = _policies.indexOf(policy);
                              setState(() {
                                _policies.remove(policy);
                              });
                              widget.onDeletePress(indexOfDeletedPolicy);
                              widget.onChange(_policies);
                            });
                          },
                        )),
                  ),
                ),
              )
            : TableCell(
                child: Container(),
              )
      ]));

      if (policy != _policies.last) {
        accumulator.add(buildTableSpacer(10));
      }

      return accumulator;
    });

    return rowsWithSpacers;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Manage policies', style: Theme.of(context).textTheme.headlineLarge),
              SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(height: 16),
                      Container(
                        width: 250,
                        child: Table(children: buildPoliciesTableRows(), columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: IntrinsicColumnWidth(),
                          2: IntrinsicColumnWidth(),
                          3: IntrinsicColumnWidth(),
                        }),
                      ),
                    ],
                  ),
                ),
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
