import 'dart:convert';

import 'package:crimson/crimson.dart';
import 'package:test/test.dart';

part 'factory_json_test.g.dart';

@json
class Model {
  Model(this.id, this.foo, this.bar);

  final int id;
  String? foo;
  bool? bar;

  factory Model.fromJson(List<int> buffer) => _$Model(buffer);
}

void main() {
  test('factory json test', () {
    final json = {'id': 0, 'foo': 'lorem ipsum', 'bar': true};
    final model = Model.fromJson(utf8.encode(jsonEncode(json)));
    final Uint8List map = model.toJson();
    expect(model.id, 0);
    expect(model.foo, 'lorem ipsum');
  });
}
