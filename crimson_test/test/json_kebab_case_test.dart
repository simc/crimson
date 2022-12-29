import 'dart:convert';

import 'package:crimson/crimson.dart';
import 'package:test/test.dart';

part 'json_kebab_case_test.g.dart';

@jsonKebabCase
class KebabCaseTest {
  KebabCaseTest(
    this.testName,
    this.fieldTwo,
    this.hello,
    this.kebabEnum1,
    this.kebabEnum2,
    this.normalEnum,
  );

  final String testName;

  @JsonName('fieldThree')
  final int fieldTwo;

  final bool hello;

  final KebabCaseEnum kebabEnum1;

  final KebabCaseEnum kebabEnum2;

  final NormalEnum normalEnum;
}

@jsonKebabCase
enum KebabCaseEnum {
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
  test('@jsonKebabCase', () {
    final json = {
      'test-name': 'John',
      'fieldThree': 42,
      'hello': true,
      'kebab-enum1': 'test',
      'kebab-enum2': 'test-value2',
      'normal-enum': 'testValue',
    };
    final crimson = Crimson(utf8.encode(jsonEncode(json)));
    final obj = crimson.readKebabCaseTest();
    expect(obj.testName, 'John');
    expect(obj.fieldTwo, 42);
    expect(obj.hello, true);
    expect(obj.kebabEnum1, KebabCaseEnum.testValue);
    expect(obj.kebabEnum2, KebabCaseEnum.testValue2);
    expect(obj.normalEnum, NormalEnum.testValue);
  });
}
