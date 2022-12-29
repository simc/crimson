import 'package:crimson/crimson.dart';
import 'package:json_annotation/json_annotation.dart';

import 'entities.dart';
import 'geo.dart';
import 'user.dart';
import 'util.dart';

part 'tweet.g.dart';

@JsonSerializable(createToJson: false)
@json
class Tweet {
  Tweet();

  factory Tweet.fromJson(Map<String, dynamic> json) => _$TweetFromJson(json);

  @JsonKey(fromJson: convertTwitterDateTime)
  @TwitterDateConverter()
  DateTime? created_at;

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

@JsonSerializable(createToJson: false)
@json
class CurrentUserRetweet {
  CurrentUserRetweet();

  factory CurrentUserRetweet.fromJson(Map<String, dynamic> json) =>
      _$CurrentUserRetweetFromJson(json);

  String? id_str;
}

@JsonSerializable(createToJson: false)
@json
class QuotedStatusPermalink {
  QuotedStatusPermalink();

  factory QuotedStatusPermalink.fromJson(Map<String, dynamic> json) =>
      _$QuotedStatusPermalinkFromJson(json);

  String? url;

  String? expanded;

  String? display;
}
