// ignore_for_file: use_string_buffers

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:crimson/crimson.dart';
import 'package:crimson/src/annotations.dart';
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
      return _generateClassDecode(element);
    } else if (element is EnumElement) {
      final field = annotation.read('enumField');
      final enumProperty = field.isNull ? 'name' : field.stringValue;
      return _generateEnumDecode(element, enumProperty);
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

    // hack to fix freezed names
    final cls = element.displayName.replaceFirst(r'_$_', '');
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
      final fromJson = accessor.fromJson;
      final type = fromJson?.parameters.first.type ?? accessor.type;
      var value = _read(type);
      if (fromJson != null) {
        value = '${fromJson.name}($value)';
      }

      for (final name in names) {
        code += 'case ${Crimson.hash(name)}: // $name\n';
      }
      code += '''
      ${accessor.name} = $value;
      break;''';
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

    code += '';

    return '''
        $code
        return obj;
      }

      List<$cls> read${cls}List() {
        final list = <$cls>[];
        while(iterList()) {
          list.add(read$cls());
        }
        return list;
      }

      List<$cls?> read${cls}OrNullList() {
        final list = <$cls?>[];
        while(iterList()) {
          list.add(skipNull() ? null : read$cls());
        }
        return list;
      }
    }''';
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

      List<$cls> read${cls}List() {
        final list = <$cls>[];
        while(iterList()) {
          list.add(read$cls());
        }
        return list;
      }

      List<$cls?> read${cls}OrNullList() {
        final list = <$cls?>[];
        while(iterList()) {
          list.add(skipNull() ? null : read$cls());
        }
        return list;
      }
    }''';
  }

  String _read(DartType type) {
    var code = '';
    final orNull = type.isNullable ? 'OrNull' : '';
    final skipNull = type.isNullable ? 'skipNull() ? null : ' : '';
    if (type.isDartCoreList) {
      code += '''
      $skipNull
      [
        for(;iterList();)
          ${_read(type.listParam)},
      ]''';
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
}

extension on ClassElement {
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
