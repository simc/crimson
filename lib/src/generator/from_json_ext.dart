/// @nodoc
String generateFromJsonExt(String name) {
  return '''
  $name _\$$name(List<int> buffer) => ${name}Ext.fromJson(buffer);
  
  extension ${name}Ext on $name {
    static $name fromJson(List<int> buffer) {
      final crimson = Crimson(buffer);
      return crimson.read$name();
    }
  
    Uint8List toJson() {
      final writer = CrimsonWriter();
      writer.write$name(this);
      return writer.toBytes();
    }
  }
  
  extension ${name}List on List<$name> {
    static List<$name> fromJson(List<int> buffer) {
      final crimson = Crimson(buffer);
      return crimson.read${name}List();
    }
  
    Uint8List toJson() {
      final writer = CrimsonWriter();
      writer.write${name}List(this);
      return writer.toBytes();
    }
  }''';
}
