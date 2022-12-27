// ignore_for_file: use_string_buffers

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:crimson/crimson.dart';
import 'package:crimson/src/annotations.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker _fieldChecker = TypeChecker.fromRuntime(JsonField);
const TypeChecker _enumChecker = TypeChecker.fromRuntime(JsonEnum);

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
      return _generateEnumDecode(element);
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
    var code = '''
    extension Read$cls on Crimson {
      $cls read$cls() {''';
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
      final name = accessor.jsonName;
      final fromJson = accessor.jsonFromJson;
      final fromJsonParamType = fromJson?.parameters.first.type;
      final value = _read(fromJsonParamType ?? accessor.type);

      code += '''
      case ${Crimson.hash(name)}:
        ${accessor.name} = ${fromJson != null ? '${fromJson.name}(' : '('} $value);
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
          list.add(this.isNull() ? readNull() : read$cls());
        }
        return list;
      }
    }''';
  }

  String _generateEnumDecode(EnumElement enumClass) {
    final enumElements =
        enumClass.fields.where((f) => f.isEnumConstant).toList();
    final propertyName = enumClass.jsonEnumField;
    final valueMap = <String, dynamic>{};

    if (propertyName == 'name') {
      for (final element in enumElements) {
        valueMap[element.name] = element.name;
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
        valueMap[element.name] = propertyValue;
      }
    }

    final cls = enumClass.displayName;
    final map = valueMap.entries.map((e) {
      final value = e.value;
      if (value is String) {
        return "'${e.value}': $cls.${e.key}";
      } else {
        return '${e.value}: $cls.${e.key}';
      }
    }).join(',');
    return '''
    final _${cls}Map = {$map};
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
          list.add(this.isNull() ? readNull() : read$cls());
        }
        return list;
      }
    }''';
  }

  String _read(DartType type) {
    var code = '';
    if (!type.isDynamic && !type.isDartCoreBool && type.isNullable) {
      code += 'this.isNull() ? readNull() : ';
    }
    if (type.isDartCoreList) {
      code += '''
      [
        for(;iterList();)
          ${_read(type.listParam)},
      ]''';
    } else if (type.isDartCoreMap) {
      code += '''
      {
        for(var field = iterObject(); field != null; field = iterObject())
          field: ${_read(type.mapParam)},
      }''';
    } else if (type.isDartCoreDouble) {
      code += 'readDouble()';
    } else if (type.isDartCoreInt) {
      code += 'readInt()';
    } else if (type.isDartCoreNum) {
      code += 'readNum()';
    } else if (type.isDartCoreString) {
      code += 'readString()';
    } else if (type.isDynamic || type.isDartCoreBool) {
      code += 'read()';
    } else {
      code += 'read${type.element!.name}()';
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

extension on EnumElement {
  String get jsonEnumField {
    final ann = _enumChecker.firstAnnotationOfExact(this);
    return ann?.getField('field')?.toStringValue() ?? 'name';
  }
}

extension on DartType {
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
    final ann = _fieldChecker.firstAnnotationOfExact(nonSynthetic);
    return ann?.getField('name')?.toStringValue() ?? name;
  }

  bool get jsonIgnore {
    final ann = _fieldChecker.firstAnnotationOfExact(nonSynthetic);
    final ignore = ann?.getField('ignore')?.toBoolValue() ?? false;
    if (ignore) {
      return true;
    }

    return {'hashCode', 'runtimeType', 'copyWith'}.contains(name);
  }

  ExecutableElement? get jsonFromJson {
    final ann = _fieldChecker.firstAnnotationOfExact(nonSynthetic);
    return ann?.getField('fromJson')?.toFunctionValue();
  }
}

Never _err(String msg, [Element? element]) {
  throw InvalidGenerationSourceError(msg, element: element);
}
