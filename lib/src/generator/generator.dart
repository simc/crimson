import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:crimson/src/annotations.dart';
import 'package:crimson/src/generator/class_decode.dart';
import 'package:crimson/src/generator/class_encode.dart';
import 'package:crimson/src/generator/enum_decode.dart';
import 'package:crimson/src/generator/enum_encode.dart';
import 'package:crimson/src/generator/fromJson_ext.dart';
import 'package:crimson/src/generator/util.dart';
import 'package:source_gen/source_gen.dart';

/// @nodoc
class CrimsonGenerator extends GeneratorForAnnotation<Json> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is ClassElement) {
      final jsonFactory = element.fromJsonFactory;
      return '''
      ${jsonFactory != null ? generateFromJsonExt(jsonFactory) : ''}

      extension Read${element.cleanName} on Crimson {
        ${generateClassDecode(element)}

        ${_generateListDecode(element.cleanName)}
      }

      extension Write${element.cleanName} on CrimsonWriter {
        ${generateClassEncode(element)}

        ${_generateListEncode(element.cleanName)}
      }''';
    } else if (element is EnumElement) {
      final field = annotation.read('enumField');
      final enumProperty = field.isNull ? 'name' : field.stringValue;
      return '''
      extension Read${element.displayName} on Crimson {
        ${generateEnumDecode(element, enumProperty)}

        ${_generateListDecode(element.displayName)}
      }
      
      extension Write${element.displayName} on CrimsonWriter {
        ${generateEnumEncode(element, enumProperty)}

        ${_generateListEncode(element.displayName)}
      }''';
    } else {
      return '';
    }
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
}
