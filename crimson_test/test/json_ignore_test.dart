import 'dart:convert';

import 'package:crimson/crimson.dart';
import 'package:test/test.dart';

part 'json_ignore_test.g.dart';

@json
class JsonIgnoreTest {
  @jsonIgnore
  String? val1;

  String? val2;

  @jsonIgnore
  String? val3;
}

void main() {
  test('@jsonIgnore', () {
    final json = {
      'val1': 'test1',
      'val2': 'test2',
      'val3': 'test3',
    };
    final crimson = Crimson(utf8.encode(jsonEncode(json)));
    final test = crimson.readJsonIgnoreTest();
    expect(test.val1, null);
    expect(test.val2, 'test2');
    expect(test.val3, null);
  });
}
