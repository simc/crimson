/// @nodoc
String generateFromJsonExt(String eleName) {
  return '''
$eleName _\$${eleName}FromJson(List<int> buffer) => ${eleName}Ext.fromJson(buffer);

extension ${eleName}Ext on $eleName {
  static $eleName fromJson(List<int> buffer) {
    final crimson = Crimson(buffer);
    return crimson.read$eleName();
  }

  Uint8List toJson() {
    final writer = CrimsonWriter();
    writer.write$eleName(this);
    return writer.toBytes();
  }
}

extension ${eleName}List on List<$eleName> {
  static List<$eleName> fromJson(List<int> buffer) {
    final crimson = Crimson(buffer);
    return crimson.read${eleName}List();
  }

  Uint8List toJson() {
    final writer = CrimsonWriter();
    writer.write${eleName}List(this);
    return writer.toBytes();
  }
}
''';
}
