import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crimson/crimson.dart';
import 'package:test/test.dart';

void main() {
  group('json.org', () {
    final files = Directory('json_org').listSync();
    for (final file in files) {
      if (file is File) {
        test(file.path.split('/').last, () {
          testJson(file.readAsStringSync());
        });
      }
    }
  });

  group('test_suite', () {
    final files = Directory('test_suite').listSync();
    for (final file in files) {
      if (file is File) {
        test(file.path.split('/').last, () {
          testJson(file.readAsStringSync());
        });
      }
    }
  });
}

void testJson(String json) {
  final crimson = Crimson(utf8.encode(json) as Uint8List);
  final crimsonResult = crimson.read();
  final jsonResult = jsonDecode(json);
  expect(crimsonResult, jsonResult);
}
