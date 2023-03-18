// ignore_for_file: use_string_buffers

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:crimson/src/crimson.dart';
import 'package:crimson/src/generator/util.dart';

/// @nodoc
String generateClassDecode(ClassElement element) {
  return '''
  ${element.cleanName} read${element.cleanName}() {
    ${_generateAccessorVariables(element)}

    loop:
    while(true) {
      switch(iterObjectHash()) {
        case -1:
          break loop;
        ${_generateReadAccessors(element)}
        default:
          skip();
          break;
      }
    }

    ${_generateCreateObject(element)}
    return obj;
  }''';
}

String _generateAccessorVariables(ClassElement cls) {
  var code = '';
  for (final accessor in cls.allAccessors) {
    final nullable = accessor.type.isNullable;
    final hasDefault = cls.defaultValue(accessor.name) != null;
    final prefix = nullable || hasDefault ? '' : 'late';
    final suffix = !nullable && hasDefault ? '?' : '';
    code += '$prefix ${accessor.type}$suffix ${accessor.name};';
  }
  return code;
}

String _generateReadAccessors(ClassElement cls) {
  var code = '';
  for (final accessor in cls.allAccessors) {
    final names = [accessor.jsonName, ...accessor.jsonAliases];
    for (final name in names) {
      final pointer = _pointer(name);
      code += 'case ${Crimson.hash(pointer[0].toString())}: // ${pointer[0]}\n';

      final fromJson = accessor.fromJson;
      final type = fromJson?.parameters.first.type ?? accessor.type;
      final hasDefault = cls.defaultValue(accessor.name) != null;
      var value =
          _read(type, type.isNullable || (hasDefault && fromJson == null));
      if (fromJson != null) {
        value = '${fromJson.qualifiedName}($value)';
        if (!type.isNullable && hasDefault) {
          value = 'skipNull() ? null : $value';
        }
      }
      if (pointer.length > 1) {
        var read = '${accessor.name} = $value;';
        for (final segment in pointer.skip(1).toList().reversed) {
          read = _generateReadSegment(segment, read);
        }

        code += '''
            $read
          else {
            skip();
          }''';
      } else {
        code += '${accessor.name} = $value;';
      }

      code += 'break;';
    }
  }
  return code;
}

String _generateReadSegment(dynamic segment, String read) {
  var code = '''
    final nextType = whatIsNext();
    if (nextType == JsonType.object) {
      for (var hash = iterObjectHash(); hash != -1; hash = iterObjectHash()) {
        if (hash == ${Crimson.hash(segment.toString())}) /* $segment */ {
          $read
          skipPartialObject();
          break;
        } else {
          skip();
        }
      }
    }''';

  if (segment is int) {
    code += '''
      else if (nextType == JsonType.array) {
        for (var i = 0; i <= $segment && iterArray(); i++) {
          if (i == $segment) {
            $read
            skipPartialArray();
            break;
          } else {
            skip();
          }
        }
      }''';
  }

  return code;
}

String _generateCreateObject(ClassElement cls) {
  var code = 'final obj = ${cls.cleanName}(';
  for (final accessor in cls.allAccessors) {
    final param = cls.constructorParam(accessor.name);
    if (param == null) {
      continue;
    }
    var defaultValue = '';
    if (param.defaultValueCode != null) {
      defaultValue = ' ?? ${param.defaultValueCode}';
    }
    if (param.isNamed) {
      code += '${param.name}: ${accessor.name} $defaultValue,';
    } else {
      code += '${accessor.name} $defaultValue,';
    }
  }
  code += ');';

  for (final accessor in cls.allAccessors) {
    if (cls.constructorParam(accessor.name) == null &&
        accessor.setter != null) {
      code += 'obj.${accessor.name} = ${accessor.name};';
    }
  }
  return code;
}

String _read(DartType type, bool nullable) {
  final orNull = nullable ? 'OrNull' : '';
  final skipNull = nullable ? 'skipNull() ? null : ' : '';
  if (type.hasFromCrimsonConstructor) {
    return '$skipNull ${type.name}.fromCrimson(this)';
  } else if (type.isDartCoreList || type.isDartCoreSet) {
    return '''
      $skipNull
      ${type.isDartCoreList ? '[' : '{'}
        for(;iterArray();)
          ${_read(type.listParam, type.listParam.isNullable)},
      ${type.isDartCoreList ? ']' : '}'}''';
  } else if (type.isDartCoreMap) {
    return '''
      $skipNull
      {
        for(var field = iterObject(); field != null; field = iterObject())
          field: ${_read(type.mapParam, type.mapParam.isNullable)},
      }''';
  } else if (type.isDartCoreDouble) {
    return 'readDouble$orNull()';
  } else if (type.isDartCoreInt) {
    return 'readInt$orNull()';
  } else if (type.isDartCoreNum) {
    return 'readNum$orNull()';
  } else if (type.isDartCoreString) {
    return 'readString$orNull()';
  } else if (type.isDynamic || type.isDartCoreBool) {
    return 'read()';
  } else if (type.element?.name == 'DateTime') {
    return '$skipNull DateTime.parse(readString())';
  } else if (type.hasJsonAnnotation) {
    return '$skipNull read${type.element!.name}()';
  } else {
    return '${type.element!.displayName}.fromJson(read())';
  }
}

List<dynamic> _pointer(String pointer) {
  if (!pointer.startsWith('/')) {
    return [pointer];
  }

  return pointer.substring(1).split('/').map((e) {
    final replaced = e.replaceAll('~0', '~').replaceAll('~1', '/');
    return int.tryParse(replaced) ?? replaced;
  }).toList();
}
