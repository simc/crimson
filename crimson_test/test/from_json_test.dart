import 'package:crimson/crimson.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:test/test.dart';

part 'from_json_test.g.dart';
part 'from_json_test.freezed.dart';

// Need to disable fromJson/toJson OR it generates:
// FJFreezed _$FJFreezedFromJson(Map<String, dynamic> json) {...}
@Freezed(fromJson: false, toJson: false)
class FJFreezed with _$FJFreezed {
  // ignore: invalid_annotation_target
  @json
  const factory FJFreezed({
    required String name,
    required int age,
  }) = _FJFreezed;

  // and would THEN throw this error
  // The name '_$FJFreezedFromJson' is already defined.
  // Try renaming one of the declarations.
  factory FJFreezed.fromJson(Uint8List json) => _$FJFreezedFromJson(json);
}

@json
class FJModel {
  FJModel(this.name, this.age);

  final String name;
  final int age;

  factory FJModel.fromJson(Uint8List json) => _$FJModelFromJson(json);
}

void main() {
  test('factory json test', () {
    final model = FJModel('John', 42);
    final Uint8List list = model.toJson();
    final freezedModel = FJFreezed.fromJson(list);
    expect(freezedModel.name, 'John');
    expect(freezedModel.age, 42);
  });
}
