import 'package:analyzer/dart/element/element.dart';
import 'package:crimson/src/generator/util.dart';

/// @nodoc
String generateFromFactory(ClassElement element) {
  if (element.hasFromConstructor('fromJson', 'Uint8List')) {
    return _generateExtension(element, 'Json');
  } else if (element.hasFromConstructor('fromBytes', 'Uint8List')) {
    return _generateExtension(element, 'Bytes');
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
