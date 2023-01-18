// ignore_for_file: public_member_api_docs

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:crimson/src/annotations.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker _jsonChecker = TypeChecker.fromRuntime(Json);
const TypeChecker _jsonKebabChecker = TypeChecker.fromRuntime(JsonKebabCase);
const TypeChecker _jsonSnakeChecker = TypeChecker.fromRuntime(JsonSnakeCase);
const TypeChecker _nameChecker = TypeChecker.fromRuntime(JsonName);
const TypeChecker _ignoreChecker = TypeChecker.fromRuntime(JsonIgnore);
const TypeChecker _convertChecker = TypeChecker.fromRuntime(JsonConvert);

extension ClassElementX on ClassElement {
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

  ConstructorElement get jsonConstructor {
    return constructors.firstWhere(
      (e) => e.name.isEmpty,
      orElse: () => err('No default constructor found', this),
    );
  }

  NamedCtor? get fromFactoryCtor {
    for (final ctor in constructors) {
      if (ctor.isFactory && ctor.name.startsWith('from')) {
        final paramName = ctor.name.replaceFirst('from', '').toLowerCase();
        final posParam = ctor.parameters.firstWhere((e) => e.isPositional);
        if (posParam.type.toString() == 'Uint8List' &&
            posParam.displayName == paramName) {
          return NamedCtor(
            ctor.enclosingElement.displayName,
            ctor.name.replaceFirst('from', ''),
          );
        }
      }
    }
    return null;
  }

  ParameterElement? constructorParam(String name) {
    for (final param in jsonConstructor.parameters) {
      if (param.name == name) {
        return param;
      }
    }
    return null;
  }

  String? defaultValue(String name) {
    return constructorParam(name)?.defaultValueCode;
  }
}

extension DartTypeX on DartType {
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

extension PropertyInducingElementX on PropertyInducingElement {
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

extension ExecutableElementX on ExecutableElement {
  String get qualifiedName {
    if (this is FunctionElement) {
      return name;
    }

    if (this is MethodElement) {
      return '${enclosingElement.name}.$name';
    }

    if (this is ConstructorElement) {
      // Ignore the default constructor.
      if (name.isEmpty) {
        return '${enclosingElement.name}';
      }
      return '${enclosingElement.name}.$name';
    }

    throw UnsupportedError(
      'Not sure how to support typeof $runtimeType',
    );
  }
}

extension InterfaceTypeX on InterfaceType {
  NamedCtor? get fromFactoryCtor {
    for (final ctor in constructors) {
      if (ctor.isFactory && ctor.name.startsWith('from')) {
        final paramName = ctor.name.replaceFirst('from', '').toLowerCase();
        final posParam = ctor.parameters.firstWhere((e) => e.isPositional);
        if (posParam.type.toString() == 'Uint8List' &&
            posParam.displayName == paramName) {
          return NamedCtor(
            ctor.enclosingElement.displayName,
            ctor.name.replaceFirst('from', ''),
          );
        }
      }
    }
    return null;
  }
}

class NamedCtor {
  NamedCtor(this.className, this.ctorAbbr);

  final String className;
  final String ctorAbbr;
}

Never err(String msg, [Element? element]) {
  throw InvalidGenerationSourceError(msg, element: element);
}
