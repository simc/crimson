// ignore_for_file: use_string_buffers

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:crimson/crimson.dart';
import 'package:crimson/src/annotations.dart';
import 'package:crimson/src/consts.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker _jsonChecker = TypeChecker.fromRuntime(Json);
const TypeChecker _jsonKebabChecker = TypeChecker.fromRuntime(JsonKebabCase);
const TypeChecker _jsonSnakeChecker = TypeChecker.fromRuntime(JsonSnakeCase);
const TypeChecker _nameChecker = TypeChecker.fromRuntime(JsonName);
const TypeChecker _ignoreChecker = TypeChecker.fromRuntime(JsonIgnore);
const TypeChecker _convertChecker = TypeChecker.fromRuntime(JsonConvert);

/// @nodoc
class CrimsonGenerator extends GeneratorForAnnotation<Json> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is ClassElement) {
      return '''
      ${_generateClassEncode(element)}
      ${_generateClassDecode(element)}
      ''';
    } else if (element is EnumElement) {
      final field = annotation.read('enumField');
      final enumProperty = field.isNull ? 'name' : field.stringValue;
      return '''
      ${_generateEnumEncode(element, enumProperty)}
      ${_generateEnumDecode(element, enumProperty)}
      ''';
    } else {
      throw UnimplementedError();
    }
  }

  String _generateClassDecode(ClassElement element) {
    final accessors = element.allAccessors;
    final defaultContstructor = element.constructors.firstWhere(
      (e) => e.name.isEmpty,
      orElse: () => throw Exception('No default constructor found'),
    );
    final params = {
      for (final param in defaultContstructor.parameters) param.name: param
    };

    final cls = element.cleanName;
    var code = 'extension Read$cls on Crimson {';

    code += '$cls read$cls() {';
    for (final accessor in accessors) {
      final nullable = accessor.type.isNullable;
      final hasDefault = params[accessor.name]?.defaultValueCode != null;
      final prefix = nullable || hasDefault ? '' : 'late';
      final suffix = !nullable && hasDefault ? '?' : '';
      code += '$prefix ${accessor.type}$suffix ${accessor.name};';
    }

    code += '''
    loop:
    while(true) {
      switch(iterObjectHash()) {
        case -1:
          break loop;''';
    for (final accessor in accessors) {
      final names = [accessor.jsonName, ...accessor.jsonAliases];
      for (final name in names) {
        final pointer = _pointer(name);
        code +=
            'case ${Crimson.hash(pointer[0].toString())}: // ${pointer[0]}\n';

        final fromJson = accessor.fromJson;
        final type = fromJson?.parameters.first.type ?? accessor.type;
        var value = _read(type);
        if (fromJson != null) {
          value = '${fromJson.name}($value)';
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
    code += '''
      default:
        skip();
        break;
      }
    }''';

    code += 'final obj = $cls(';
    for (final accessor in accessors) {
      final param = params[accessor.name];
      if (param == null) {
        continue;
      }
      var defaultValue = '';
      if (params[accessor.name]?.defaultValueCode != null) {
        defaultValue = ' ?? ${params[accessor.name]?.defaultValueCode}';
      }
      if (param.isNamed) {
        code += '${param.name}: ${accessor.name} $defaultValue,';
      } else {
        code += '${accessor.name} $defaultValue,';
      }
    }
    code += ');';

    for (final accessor in accessors) {
      if (!params.containsKey(accessor.name) && accessor.setter != null) {
        code += 'obj.${accessor.name} = ${accessor.name};';
      }
    }

    return '''
        $code
        return obj;
      }

      ${_generateListDecode(cls)}
    }''';
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

  String _generateEnumDecode(EnumElement enumClass, String propertyName) {
    final enumElements =
        enumClass.fields.where((f) => f.isEnumConstant).toList();
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
        final property =
            element.computeConstantValue()!.getField(propertyName)!;
        final propertyValue = property.toBoolValue() ??
            property.toIntValue() ??
            property.toDoubleValue() ??
            property.toStringValue();
        if (propertyValue == null) {
          _err('Null values are not supported for enum properties.', element);
        }

        if (valueMap.values.contains(propertyValue)) {
          _err('Enum property has duplicate values.', element);
        }
        valueMap[propertyValue] = element.name;
      }
    }

    final cls = enumClass.displayName;
    final map = valueMap.entries.map((e) {
      final key = e.key;
      if (key is String) {
        return "'$key': $cls.${e.value}";
      } else {
        return '$key: $cls.${e.value}';
      }
    }).join(',');
    return '''
    const _${cls}Map = {$map};
    extension Read$cls on Crimson {
      $cls read$cls() {
        return _${cls}Map[read()]!;
      }

      ${_generateListDecode(cls)}
    }''';
  }

  String _generateListDecode(String cls) {
    return '''
    List<$cls> read${cls}List() {
      final list = <$cls>[];
      while(iterArray()) {
        list.add(read$cls());
      }
      return list;
    }

    List<$cls?> read${cls}OrNullList() {
      final list = <$cls?>[];
      while(iterArray()) {
        list.add(skipNull() ? null : read$cls());
      }
      return list;
    }''';
  }

  String _read(DartType type) {
    var code = '';
    final orNull = type.isNullable ? 'OrNull' : '';
    final skipNull = type.isNullable ? 'skipNull() ? null : ' : '';
    if (type.isDartCoreList || type.isDartCoreSet) {
      code += '''
      $skipNull
      ${type.isDartCoreList ? '[' : '{'}
        for(;iterArray();)
          ${_read(type.listParam)},
      ${type.isDartCoreList ? ']' : '}'}''';
    } else if (type.isDartCoreMap) {
      code += '''
      $skipNull
      {
        for(var field = iterObject(); field != null; field = iterObject())
          field: ${_read(type.mapParam)},
      }''';
    } else if (type.isDartCoreDouble) {
      code += 'readDouble$orNull()';
    } else if (type.isDartCoreInt) {
      code += 'readInt$orNull()';
    } else if (type.isDartCoreNum) {
      code += 'readNum$orNull()';
    } else if (type.isDartCoreString) {
      code += 'readString$orNull()';
    } else if (type.isDynamic || type.isDartCoreBool) {
      code += 'read()';
    } else if (type.element?.name == 'DateTime') {
      code += '$skipNull DateTime.parse(readString())';
    } else if (type.hasJsonAnnotation) {
      code += '$skipNull read${type.element!.name}()';
    } else {
      code += '${type.element!.displayName}.fromJson(read())';
    }

    return code;
  }

  String _generateClassEncode(ClassElement element) {
    final accessors = element.allAccessors;

    final cls = element.cleanName;
    var code = '''
    extension Write$cls on CrimsonWriter {
      void write$cls($cls value) {
        writeObjectStart();''';

    for (final accessor in accessors) {
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
      code += 'final ${accessor.name} = value.${accessor.name};';
      code += _write(accessor.name, accessor.type);
    }

    return '''
        $code
        writeObjectEnd();
      }

      ${_generateListEncode(cls)}
    }''';
  }

  String _generateEnumEncode(EnumElement enumClass, String propertyName) {
    final cls = enumClass.name;
    var code = '''
    extension Write$cls on CrimsonWriter {
      void write$cls($cls value) {''';

    if (propertyName == 'name') {
      code += 'writeString(value.name);';
    } else {
      final property = enumClass.getField(propertyName)!;
      code += 'final enumValue = value.${property.name};';
      code += _write('enumValue', property.type);
    }

    return '''
        $code
      }

      ${_generateListEncode(cls)}
    }''';
  }

  String _generateListEncode(String cls) {
    return '''
    void write${cls}List(List<$cls> list) {
      writeArrayStart();
      for (final value in list) {
        write$cls(value);
      }
      writeArrayEnd();
    }

    void write${cls}OrNullList(List<$cls?> list) {
      writeArrayStart();
      for (final value in list) {
        if (value == null) {
          writeNull();
        } else {
          write$cls(value);
        }
      }
      writeArrayEnd();
    }''';
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
}

extension on ClassElement {
  String get cleanName {
    // hack to fix freezed names
    return displayName.replaceFirst(r'_$_', '');
  }

  List<PropertyInducingElement> get allAccessors {
    final accessorNames = <String>{};
    return [
      ...accessors.map((e) => e.variable),
      for (final supertype in allSupertypes) ...[
        if (!supertype.isDartCoreObject)
          ...supertype.accessors.map((e) => e.variable)
      ],
    ]
        .where(
          (e) =>
              e.isPublic &&
              !e.isStatic &&
              !e.jsonIgnore &&
              accessorNames.add(e.name),
        )
        .toList();
  }
}

extension on DartType {
  bool get hasJsonAnnotation {
    return _jsonChecker.hasAnnotationOf(element!.nonSynthetic);
  }

  bool get isNullable {
    return nullabilitySuffix == NullabilitySuffix.question;
  }

  DartType get listParam {
    if (isDartCoreList) {
      return (this as ParameterizedType).typeArguments.first;
    } else {
      throw Exception('Not a list');
    }
  }

  DartType get mapParam {
    if (isDartCoreMap) {
      return (this as ParameterizedType).typeArguments.last;
    } else {
      throw Exception('Not a map');
    }
  }
}

extension on PropertyInducingElement {
  String get jsonName {
    final ann = _nameChecker.firstAnnotationOfExact(nonSynthetic);
    final annName = ann?.getField('name')?.toStringValue();
    if (annName != null) {
      return annName;
    }

    final separator = _jsonKebabChecker.hasAnnotationOf(enclosingElement!)
        ? '-'
        : _jsonSnakeChecker.hasAnnotationOf(enclosingElement!)
            ? '_'
            : null;
    if (separator != null) {
      return name.splitMapJoin(
        RegExp('([A-Z])'),
        onMatch: (m) => '$separator${m.group(1)!.toLowerCase()}',
        onNonMatch: (s) => s,
      );
    } else {
      return name;
    }
  }

  Set<String> get jsonAliases {
    final ann = _nameChecker.firstAnnotationOfExact(nonSynthetic);
    return ann
            ?.getField('aliases')
            ?.toSetValue()
            ?.map((e) => e.toStringValue()!)
            .toSet() ??
        {};
  }

  bool get jsonIgnore {
    final ann = _ignoreChecker.firstAnnotationOfExact(nonSynthetic);
    return ann != null ||
        {'hashCode', 'runtimeType', 'copyWith'}.contains(name);
  }

  ExecutableElement? get fromJson {
    final ann = _convertChecker.firstAnnotationOf(nonSynthetic);
    return ann?.getField('fromJson')?.toFunctionValue();
  }
}

Never _err(String msg, [Element? element]) {
  throw InvalidGenerationSourceError(msg, element: element);
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
