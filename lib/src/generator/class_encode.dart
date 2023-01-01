// ignore_for_file: use_string_buffers

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:crimson/src/consts.dart';
import 'package:crimson/src/generator/util.dart';

/// @nodoc
String generateClassEncode(ClassElement element) {
  return '''
  void write${element.cleanName}(${element.cleanName} value) {
    writeObjectStart();
    ${_writeAccessor(element)}
    writeObjectEnd();
  }''';
}

String _writeAccessor(ClassElement cls) {
  var code = '';
  for (final accessor in cls.allAccessors) {
    if (accessor.jsonName.startsWith('/')) {
      continue; // we don't support serializing nested objects
    }

    final raw = !accessor.jsonName.codeUnits
        .any((e) => e == tokenDoubleQuote || e == tokenBackslash || e > 127);
    if (raw) {
      code += "writeObjectKeyRaw('${accessor.jsonName}');";
    } else {
      code += "writeObjectKey('${accessor.jsonName}');";
    }
    code += 'final ${accessor.name}Val = value.${accessor.name};';
    code += _write('${accessor.name}Val', accessor.type);
  }
  return code;
}

String _write(String name, DartType type) {
  var code = '';
  if (type.isNullable) {
    code += '''
      if ($name == null) {
        writeNull();
      } else {''';
  }
  if (type.isDartCoreList || type.isDartCoreSet) {
    code += '''
      writeArrayStart();
      for (final value in $name) {
        ${_write('value', type.listParam)}
      }
      writeArrayEnd();''';
  } else if (type.isDartCoreMap) {
    code += '''
      writeObjectStart();
      for (final key in $name.keys) {
        writeObjectKey(key);
        final ${name}Value = $name[key] ${type.mapParam.isNullable ? '' : '!'};
        ${_write('${name}Value', type.mapParam)}
      }
      writeObjectEnd();''';
  } else if (type.isDartCoreDouble ||
      type.isDartCoreInt ||
      type.isDartCoreNum) {
    code += 'writeNum($name);';
  } else if (type.isDartCoreString) {
    code += 'writeString($name);';
  } else if (type.isDartCoreBool) {
    code += 'writeBool($name);';
  } else if (type.isDynamic) {
    code += 'write($name);';
  } else if (type.element?.name == 'DateTime') {
    code += 'writeString($name.toIso8601String());';
  } else if (type.hasJsonAnnotation) {
    code += 'write${type.element!.name}($name);';
  } else {
    code += 'write($name.toJson());';
  }

  if (type.isNullable) {
    code += '}';
  }

  return code;
}
