import 'package:meta/meta_meta.dart';

/// Annotation for classes to generate Crimson converters.
@Target({TargetKind.classType})
class Json {
  /// Annotation for classes to generate Crimson converters.
  const Json();
}

/// Annotation for classes to generate Crimson converters.
const json = Json();

/// Annotation for fields to customize the JSON field name or to ignore it.
@Target({TargetKind.field, TargetKind.getter, TargetKind.setter})
class JsonField {
  /// Annotation for fields to customize the JSON field name or to ignore it.
  const JsonField({
    this.name,
    this.fromJson,
    this.ignore = false,
  });

  /// The name of the field in the JSON.
  final String? name;

  /// A function to convert the JSON value to the field value.
  final Function? fromJson;

  /// Whether to ignore this field.
  final bool ignore;
}

/// Annotation for enum classes to generate Crimson enum converters.
@Target({TargetKind.enumType})
class JsonEnum {
  /// Annotation for enum classes to generate Crimson enum converters.
  const JsonEnum({this.field = 'name'});

  /// The name of the field to use for the enum value.
  ///
  /// Defaults to `name`. You can also `index` to use the enum ordinal or a
  /// custom field.
  final String field;
}
