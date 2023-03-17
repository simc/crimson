import 'package:crimson/crimson.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:test/test.dart';

part 'from_bytes_test.g.dart';
part 'from_bytes_test.freezed.dart';

@freezed
class FBFreezed with _$FBFreezed {
  // ignore: invalid_annotation_target
  @json
  const factory FBFreezed({
    required String name,
    required int age,
  }) = _FBFreezed;

  factory FBFreezed.fromBytes(Uint8List bytes) => _$FBFreezedFromBytes(bytes);
}

@json
class FBModel {
  FBModel(this.name, this.age);

  final String name;
  final int age;

  factory FBModel.fromBytes(Uint8List bytes) => _$FBModelFromBytes(bytes);
}

void main() {
  test('factory json test', () {
    final model = FBModel('John', 42);
    final Uint8List list = model.toBytes();
    final freezedModel = FBFreezed.fromBytes(list);
    expect(freezedModel.name, 'John');
    expect(freezedModel.age, 42);
  });
}
