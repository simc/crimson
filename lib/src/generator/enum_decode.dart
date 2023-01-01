import 'package:analyzer/dart/element/element.dart';
import 'package:crimson/src/generator/util.dart';

/// @nodoc
String generateEnumDecode(EnumElement cls, String propertyName) {
  final enumName = cls.displayName;
  return '''
  static const _${enumName}Map = {${_generateEnumMap(cls, propertyName)}};

  $enumName read$enumName() {
    return _${enumName}Map[read()] ?? $enumName.values.first;
  }''';
}

String _generateEnumMap(EnumElement cls, String propertyName) {
  final enumElements = cls.fields.where((f) => f.isEnumConstant).toList();
  final valueMap = <dynamic, String>{};

  if (propertyName == 'name') {
    for (final element in enumElements) {
      valueMap[element.jsonName] = element.name;
      for (final alias in element.jsonAliases) {
        valueMap[alias] = element.name;
      }
    }
  } else {
    for (final element in enumElements) {
      final field = element.computeConstantValue()!.getField(propertyName);
      if (field == null) {
        err('Enum field $propertyName not found.', element);
      }
      final value = field.toBoolValue() ??
          field.toIntValue() ??
          field.toDoubleValue() ??
          field.toStringValue();
      if (value == null) {
        err('Null values are not supported for enum properties.', element);
      }

      if (valueMap.values.contains(value)) {
        err('Enum property has duplicate values.', element);
      }
      valueMap[value] = element.name;
    }
  }

  final enumName = cls.displayName;
  return valueMap.entries.map((e) {
    final key = e.key;
    if (key is String) {
      return "'$key': $enumName.${e.value}";
    } else {
      return '$key: $enumName.${e.value}';
    }
  }).join(',');
}
