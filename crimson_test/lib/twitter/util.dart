import 'package:crimson/crimson.dart';
import 'package:intl/intl.dart';

DateTime? convertTwitterDateTime(String? twitterDateString) {
  if (twitterDateString == null) {
    return null;
  }

  try {
    return DateTime.parse(twitterDateString);
  } catch (e) {
    try {
      final dateString = formatTwitterDateString(twitterDateString);
      return DateFormat('E MMM dd HH:mm:ss yyyy', 'en_US')
          .parse(dateString, true);
    } catch (e) {
      return null;
    }
  }
}

String formatTwitterDateString(String twitterDateString) {
  final sanitized = twitterDateString.split(' ')
    ..removeWhere((part) => part.startsWith('+'));

  return sanitized.join(' ');
}

class TwitterDateConverter extends JsonConverter<DateTime> {
  const TwitterDateConverter();

  @override
  DateTime fromJson(dynamic json) {
    return convertTwitterDateTime(json as String?)!;
  }

  @override
  String toJson(DateTime object) {
    return object.toIso8601String();
  }
}
