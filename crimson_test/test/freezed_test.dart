import 'dart:convert' as c;

import 'package:crimson/crimson.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:test/test.dart';

part 'freezed_test.g.dart';
part 'freezed_test.freezed.dart';

@freezed
class TestObject with _$TestObject {
  // ignore: invalid_annotation_target
  @Json()
  const factory TestObject({
    required String name,
    required int age,
  }) = _TestObject;
}

void main() {
  test('freezed test', () {
    final json = {'name': 'John', 'age': 42};
    final crimson = Crimson(c.utf8.encode(c.json.encode(json)));
    final obj = crimson.readTestObject();
    expect(obj.name, 'John');
    expect(obj.age, 42);
  });
}
