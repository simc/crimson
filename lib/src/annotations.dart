import 'package:meta/meta_meta.dart';

/// Annotation for classes to generate Crimson converters.
@Target({TargetKind.classType, TargetKind.enumType})
class Json {
  /// Annotation for classes to generate Crimson converters.
  const Json({this.enumField});

  /// The name of the field to use for enum classes.
  ///
  /// Defaults to `name`. You can also `index` to use the enum ordinal or a
  /// custom field.
  final String? enumField;
}

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
