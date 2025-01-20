import 'dart:convert';
import 'dart:io';

import 'package:crimson/crimson.dart';
import 'package:test/test.dart';

const ignoreWriteTests = {
  'i_string_incomplete_surrogates_escape_valid.json',
  'i_string_invalid_surrogate.json',
  'i_string_1st_valid_surrogate_2nd_invalid.json',
  'i_object_key_lone_2nd_surrogate.json',
  'i_string_1st_surrogate_but_2nd_missing.json',
  'i_string_inverted_surrogates_U+1D11E.json',
  'y_string_unescaped_char_delete.json',
  'y_string_with_del_character.json',
  'i_string_invalid_lonely_surrogate.json',
  'i_string_incomplete_surrogate_pair.json',
  'i_string_incomplete_surrogate_and_escape_valid.json',
  'i_string_lone_second_surrogate.json',
};

void main() {
  group('json.org', () {
    final files = Directory('json_org').listSync();
    for (final file in files) {
      if (file is File) {
        test(file.path.split('/').last, () {
          final json = file.readAsStringSync();
          testJsonRead(json);
          testJsonWrite(json);
        });
      }
      break;
    }
  });

  group('test_suite', () {
    final files = Directory('test_suite').listSync();
    for (final file in files) {
      if (file is File) {
        test(file.path.split('/').last, () {
          final json = file.readAsStringSync();
          testJsonRead(json);
          if (!ignoreWriteTests.contains(file.path.split('/').last)) {
            testJsonWrite(json);
          }
        });
      }
    }
  });
}

void testJsonRead(String json) {
  final crimson = Crimson(utf8.encode(json));
  final crimsonResult = crimson.read();
  final jsonResult = jsonDecode(json);
  expect(crimsonResult, equals(jsonResult, 1000));
}

void testJsonWrite(String json) {
  try {
    expect(
      jsonDecode(jsonEncode(jsonDecode(json))),
      equals(jsonDecode(json), 1000),
    );
  } catch (_) {
    return;
  }
  final crimson = CrimsonWriter();
  crimson.write(jsonDecode(json));
  final bytes = crimson.toBytes();
  final string = utf8.decode(bytes);
  expect(jsonDecode(string), equals(jsonDecode(json), 1000));
}
