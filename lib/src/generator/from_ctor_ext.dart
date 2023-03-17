/// @nodoc
String generateFromFactoryCtorExt(String eleName, String ctorAbbr) {
  return '''
$eleName _\$${eleName}From$ctorAbbr(Uint8List ${ctorAbbr.toLowerCase()}) => ${eleName}Ext.from$ctorAbbr(${ctorAbbr.toLowerCase()});

extension ${eleName}Ext on $eleName {
  static $eleName from$ctorAbbr(Uint8List ${ctorAbbr.toLowerCase()}) {
    final crimson = Crimson(${ctorAbbr.toLowerCase()});
    return crimson.read$eleName();
  }

  Uint8List to$ctorAbbr() {
    final writer = CrimsonWriter();
    writer.write$eleName(this);
    return writer.toBytes();
  }
}

extension ${eleName}List on List<$eleName> {
  static List<$eleName> from$ctorAbbr(Uint8List ${ctorAbbr.toLowerCase()}) {
    final crimson = Crimson(${ctorAbbr.toLowerCase()});
    return crimson.read${eleName}List();
  }

  Uint8List to$ctorAbbr() {
    final writer = CrimsonWriter();
    writer.write${eleName}List(this);
    return writer.toBytes();
  }
}
''';
}
