import 'package:crimson/crimson.dart';

/// @nodoc
extension ReadDateTime on Crimson {
  /// @nodoc
  DateTime readDateTime() {
    final date = readString();
    return DateTime.parse(date);
  }
}
