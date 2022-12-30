import 'package:crimson/crimson.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart' as m;
import 'package:json_annotation/json_annotation.dart';

import 'entities.dart';
import 'geo.dart';
import 'user.dart';

part 'tweet.g.dart';

@JsonSerializable()
@m.jsonSerializable
@json
class Tweet {
  Tweet();

  factory Tweet.fromJson(Map<String, dynamic> json) => _$TweetFromJson(json);

  Map<String, dynamic> toJson() => _$TweetToJson(this);

  String? created_at;

  String? id_str;

  String? text;

  String? source;

  bool? truncated;

  String? in_reply_to_status_id_str;

  String? in_reply_to_user_id_str;

  String? in_reply_to_screen_name;

  User? user;

  Coordinates? coordinates;

  Place? place;

  String? quoted_status_id_str;

  bool? is_quote_status;

  Tweet? quoted_status;

  Tweet? retweeted_status;

  int? quote_count;

  int? reply_count;

  int? retweet_count;

  int? favorite_count;

  Entities? entities;

  Entities? extended_entities;

  bool? favorited;

  bool? retweeted;

  bool? possibly_sensitive;

  bool? possibly_sensitive_appealable;

  CurrentUserRetweet? current_user_retweet;

  String? lang;

  QuotedStatusPermalink? quoted_status_permalink;

  String? full_text;

  List<int>? display_text_range;
}

@JsonSerializable()
@m.jsonSerializable
@json
class CurrentUserRetweet {
  CurrentUserRetweet();

  factory CurrentUserRetweet.fromJson(Map<String, dynamic> json) =>
      _$CurrentUserRetweetFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentUserRetweetToJson(this);

  String? id_str;
}

@JsonSerializable()
@m.jsonSerializable
@json
class QuotedStatusPermalink {
  QuotedStatusPermalink();

  factory QuotedStatusPermalink.fromJson(Map<String, dynamic> json) =>
      _$QuotedStatusPermalinkFromJson(json);

  Map<String, dynamic> toJson() => _$QuotedStatusPermalinkToJson(this);

  String? url;

  String? expanded;

  String? display;
}
