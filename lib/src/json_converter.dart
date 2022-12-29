/// Allows to customize the JSON serialization and deserialization.
abstract class JsonConverter<T> {
  /// The constructor needs to be const and have no parameters.
  const JsonConverter();

  /// Converts the JSON value to the Dart value.
  T fromJson(dynamic json);

  /// Converts the Dart value to the JSON value.
  dynamic toJson(T value);
}
