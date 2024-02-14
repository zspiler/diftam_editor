import 'models.dart';
import 'dart:convert';
import 'dart:typed_data';

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
  } catch (_) {
    throw 'Failed to parse policy';
  }
}
