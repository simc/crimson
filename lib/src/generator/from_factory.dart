import 'package:analyzer/dart/element/element.dart';
import 'package:crimson/src/generator/util.dart';

/// @nodoc
String generateFromFactory(ClassElement element) {
  var ele = element;
  // check originalClass for freezed
  if (element.displayName.startsWith(r'_$') &&
      element.displayName.endsWith('Impl')) {
    final interface = element.interfaces
        .firstWhere((e) => e.element.displayName == '_${element.cleanName}');
    final originalClass = interface.interfaces
        .firstWhere((e) => e.element.displayName == element.cleanName);
    ele = originalClass.element as ClassElement;
  }

  if (ele.hasFromConstructor('fromJson', 'Uint8List')) {
    return _generateExtension(ele, 'Json');
  } else if (ele.hasFromConstructor('fromBytes', 'Uint8List')) {
    return _generateExtension(ele, 'Bytes');
  } else {
    return '';
  }
}

String _generateExtension(ClassElement element, String name) {
  final cls = element.cleanName;
  return '''
$cls _\$${cls}From$name(Uint8List ${name.toLowerCase()}) => ${cls}Ext.from$name(${name.toLowerCase()});

extension ${cls}Ext on $cls {
  static $cls from$name(Uint8List ${name.toLowerCase()}) {
    final crimson = Crimson(${name.toLowerCase()});
    return crimson.read$cls();
  }

  Uint8List to$name() {
    final writer = CrimsonWriter();
    writer.write$cls(this);
    return writer.toBytes();
  }
}

extension ${cls}List on List<$cls> {
  static List<$cls> from$name(Uint8List ${name.toLowerCase()}) {
    final crimson = Crimson(${name.toLowerCase()});
    return crimson.read${cls}List();
  }

  Uint8List to$name() {
    final writer = CrimsonWriter();
    writer.write${cls}List(this);
    return writer.toBytes();
  }
}
''';
}
