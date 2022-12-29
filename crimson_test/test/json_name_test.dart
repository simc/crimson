import 'dart:convert';

import 'package:crimson/crimson.dart';
import 'package:test/test.dart';

part 'json_name_test.g.dart';

@json
class NameTestClass {
  NameTestClass(this.name, this.name2);

  @JsonName('otherName')
  String name;

  @JsonName('name', aliases: {'myName1', 'myName2'})
  String name2;

  operator ==(Object other) {
    if (other is NameTestClass) {
      return name == other.name && name2 == other.name2;
    }
    return false;
  }
}

@json
enum NameTestEnum {
  @JsonName('B')
  A,
  @JsonName('D')
  B,
  C,
}

void main() {
  test('@JsonName() property', () {
    final json = [
      {'otherName': 'A', 'name': 'B'},
      {'otherName': 'C', 'myName1': 'D'},
      {'otherName': 'E', 'myName2': 'F'},
    ];
    final crimson = Crimson(utf8.encode(jsonEncode(json)));
    final list = crimson.readNameTestClassList();
    expect(list, [
      NameTestClass('A', 'B'),
      NameTestClass('C', 'D'),
      NameTestClass('E', 'F'),
    ]);
  });

  test('@JsonName() enum', () {
    final json = ['C', 'B', 'D'];
    final crimson = Crimson(utf8.encode(jsonEncode(json)));
    final list = crimson.readNameTestEnumList();
    expect(list, [NameTestEnum.C, NameTestEnum.A, NameTestEnum.B]);
  });
}
