import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:D2SC_editor/d2sc_policy/lib/d2sc_policy.dart';

import '../d2sc_policy/lib/src/exceptions.dart';

Policy decodeAndParsePolicy(Uint8List bytes) {
  String jsonString;
  try {
    jsonString = utf8.decode(bytes);
  } catch (_) {
    throw 'Failed to decode bytes';
  }

  dynamic jsonObject;
  try {
    jsonObject = json.decode(jsonString);
  } catch (_) {
    throw 'Failed to decode JSON';
  }

  try {
    return Policy.fromJson(jsonObject);
  } on PolicyValidationException {
    rethrow;
  } catch (e) {
    throw "Failed to parse policy: ${e.toString()}";
  }
}

Future<void> exportPolicy(Policy policy, {bool indent = true}) async {
  final encoder = indent ? JsonEncoder.withIndent('  ') : JsonEncoder();
  final jsonString = encoder.convert(policy.toJson());

  final fileName = policy.name.replaceAll(' ', '_');

  // TODO let user pick destination & file name?
  await FileSaver.instance.saveFile(name: "$fileName.json", bytes: utf8.encode(jsonString));
}
