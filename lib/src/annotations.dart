/// Annotation for classes and enums to generate Crimson JSON support.
class Json {
  /// Annotation for classes and enums to generate Crimson JSON support.
  const Json({this.enumField});

  /// The name of the field to use for enum classes.
  ///
  /// Defaults to `name`. You can also `index` to use the enum ordinal or a
  /// custom field.
  final String? enumField;
}

/// Annotation for classes and enums to generate Crimson JSON support.
const json = Json();

/// @nodoc
class JsonKebabCase extends Json {
  /// @nodoc
  const JsonKebabCase();
}

/// Annotation for classes to generate Crimson JSON support and change the
/// field names to kebab-case.
const jsonKebabCase = JsonKebabCase();

/// @nodoc
class JsonSnakeCase extends Json {
  /// @nodoc
  const JsonSnakeCase();
}

/// Annotation for classes to generate Crimson JSON support and change the
/// field names to snake_case.
const jsonSnakeCase = JsonSnakeCase();

/// Annotation for fields to customize the JSON field name.
class JsonName {
  /// Annotation for fields to customize the JSON field name.
  const JsonName(this.name, {this.aliases});

  /// The name of the field in the JSON.
  final String name;

  /// Aliases for the field in the JSON.
  final Set<String>? aliases;
}

/// @nodoc
class JsonIgnore {
  /// @nodoc
  const JsonIgnore();
}

/// Annotation to ignore a field.
const jsonIgnore = JsonIgnore();
