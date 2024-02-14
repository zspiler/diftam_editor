import 'models.dart';
import 'dart:convert';
import 'package:file_saver/file_saver.dart';

Future<void> exportPolicy(Policy policy, {bool indent = true}) async {
  final encoder = indent ? JsonEncoder.withIndent('  ') : JsonEncoder();
  final jsonString = encoder.convert(policy.toJson());

  final fileName = policy.name.replaceAll(' ', '_');

  // TODO let user pick destination & file name?
  await FileSaver.instance.saveFile(name: "$fileName.json", bytes: utf8.encode(jsonString));
}
