import 'package:analyzer/dart/element/element.dart';

/// @nodoc
String generateEnumEncode(EnumElement cls, String propertyName) {
  return '''
  void write${cls.name}(${cls.name} value) {
    write(value.$propertyName);
  }''';
}
