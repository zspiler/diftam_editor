import 'models.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html; // https://dart.dev/tools/linter-rules/avoid_web_libraries_in_flutter

void exportPolicyWeb(PolicyData policy, {bool indent = true}) {
  final encoder = indent ? JsonEncoder.withIndent('  ') : JsonEncoder();
  final jsonString = encoder.convert(policy.toJson());
  final blob = html.Blob([jsonString]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final fileName = policy.name.replaceAll(' ', '_');
  html.AnchorElement(href: url)
    ..setAttribute("download", "$fileName.json")
    ..click();
  html.Url.revokeObjectUrl(url);
}

// TODO Desktop