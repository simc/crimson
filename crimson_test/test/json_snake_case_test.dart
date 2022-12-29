import 'dart:convert';

import 'package:crimson/crimson.dart';
import 'package:test/test.dart';

part 'json_snake_case_test.g.dart';

@jsonSnakeCase
class SnakeCaseTest {
  SnakeCaseTest(
    this.testName,
    this.fieldTwo,
    this.hello,
    this.snakeEnum1,
    this.snakeEnum2,
    this.normalEnum,
  );

  final String testName;

  @JsonName('fieldThree')
  final int fieldTwo;

  final bool hello;

  final SnakeCaseEnum snakeEnum1;

  final SnakeCaseEnum snakeEnum2;

  final NormalEnum normalEnum;
}

@jsonSnakeCase
enum SnakeCaseEnum {
  @JsonName('test')
  testValue,
  testValue2,
}

@json
enum NormalEnum {
  testValue,
  testValue2,
}

void main() {
  test('@jsonSnakeCase', () {
    final json = {
      'test_name': 'John',
      'fieldThree': 42,
      'hello': true,
      'snake_enum1': 'test',
      'snake_enum2': 'test_value2',
      'normal_enum': 'testValue',
    };
    final crimson = Crimson(utf8.encode(jsonEncode(json)));
    final obj = crimson.readSnakeCaseTest();
    expect(obj.testName, 'John');
    expect(obj.fieldTwo, 42);
    expect(obj.hello, true);
    expect(obj.snakeEnum1, SnakeCaseEnum.testValue);
    expect(obj.snakeEnum2, SnakeCaseEnum.testValue2);
    expect(obj.normalEnum, NormalEnum.testValue);
  });
}
