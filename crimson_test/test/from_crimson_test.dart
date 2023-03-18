import 'package:crimson/crimson.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:test/test.dart';

part 'from_crimson_test.g.dart';
part 'from_crimson_test.freezed.dart';

@json
class FCContainer {
  FCContainer(this.freezed, this.model, this.modelConvert);

  final FCFreezed? freezed;

  final FCModel? model;

  @JsonConvert(fromJson: fromJson, toJson: toJson)
  final String modelConvert;
}

String fromJson(FCModel? val) => '${val?.name} ${val?.age}';

FCModel? toJson(String? val) {
  if (val == null) return null;
  final parts = val.split(' ');
  return FCModel(parts[0], int.parse(parts[1]));
}

@freezed
class FCFreezed with _$FCFreezed {
  // ignore: invalid_annotation_target
  @json
  const factory FCFreezed({
    required String name,
    required int age,
  }) = _FCFreezed;

  factory FCFreezed.fromCrimson(Crimson c) {
    final map = c.read() as Map<String, dynamic>;
    return FCFreezed(name: map['name'], age: map['age']);
  }
}

extension on _$FCFreezed {
  void toCrimson(CrimsonWriter w) {
    final map = <String, dynamic>{
      'name': name,
      'age': age,
    };
    w.write(map);
  }
}

@json
class FCModel {
  FCModel(this.name, this.age);

  final String name;
  final int age;

  factory FCModel.fromCrimson(Crimson c) {
    final map = c.read() as Map<String, dynamic>;
    return FCModel(map['name'], map['age']);
  }

  void toCrimson(CrimsonWriter w) {
    final map = <String, dynamic>{
      'name': name,
      'age': age,
    };
    w.write(map);
  }
}

void main() {
  test('factory json test', () {
    final container = FCContainer(
      FCFreezed(age: 10, name: 'hello'),
      FCModel('123123', 20),
      'test1 123',
    );

    final w = CrimsonWriter();
    w.writeFCContainer(container);
  });
}
