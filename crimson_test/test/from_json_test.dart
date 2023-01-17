import 'package:crimson/crimson.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:test/test.dart';

part 'from_json_test.g.dart';

part 'from_json_test.freezed.dart';

@freezed
class FJFreezed with _$FJFreezed {
  // ignore: invalid_annotation_target
  @json
  const factory FJFreezed({
    required String name,
    required int age,
  }) = _FJFreezed;

  factory FJFreezed.fromJson(List<int> buffer) => _$FJFreezedFromJson(buffer);
}

@json
class FJModel {
  FJModel(this.name, this.age);

  final String name;
  final int age;

  factory FJModel.fromJson(List<int> buffer) => _$FJModelFromJson(buffer);
}

void main() {

  test('factory json test', () {
    final model = FJModel('John', 42);
    final Uint8List map = model.toJson();
    print(map);
    final freezedModel = FJFreezed.fromJson(map);
    expect(freezedModel.name, 'John');
    expect(model.age, 42);
  });
}
