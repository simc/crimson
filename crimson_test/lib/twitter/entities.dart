import 'package:crimson/crimson.dart';
import 'package:json_annotation/json_annotation.dart';

import 'media.dart';
import 'util.dart';

part 'entities.g.dart';

@JsonSerializable(createToJson: false)
@Json()
class Entities {
  Entities();

  factory Entities.fromJson(Map<String, dynamic> json) =>
      _$EntitiesFromJson(json);

  List<Hashtag>? hashtags;

  List<Media>? media;

  List<Url>? urls;

  List<UserMention>? user_mentions;

  List<Symbol>? symbols;

  List<Poll>? polls;
}

@JsonSerializable(createToJson: false)
@Json()
class Hashtag {
  Hashtag();

  factory Hashtag.fromJson(Map<String, dynamic> json) =>
      _$HashtagFromJson(json);

  List<int>? indices;

  String? text;
}

@JsonSerializable(createToJson: false)
@Json()
class Poll {
  Poll();

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);

  List<Option>? options;

  @JsonKey(fromJson: convertTwitterDateTime)
  @JsonField(fromJson: convertTwitterDateTime)
  DateTime? end_datetime;

  String? duration_minutes;
}

@JsonSerializable(createToJson: false)
@Json()
class Option {
  Option();

  factory Option.fromJson(Map<String, dynamic> json) => _$OptionFromJson(json);

  int? position;

  String? text;
}

@JsonSerializable(createToJson: false)
@Json()
class Symbol {
  Symbol();

  factory Symbol.fromJson(Map<String, dynamic> json) => _$SymbolFromJson(json);

  List<int>? indices;

  String? text;
}

@JsonSerializable(createToJson: false)
@Json()
class Url {
  Url();

  factory Url.fromJson(Map<String, dynamic> json) => _$UrlFromJson(json);

  String? display_url;

  String? expanded_url;

  List<int>? indices;

  String? url;
}

@JsonSerializable(createToJson: false)
@Json()
class UserMention {
  UserMention();

  factory UserMention.fromJson(Map<String, dynamic> json) =>
      _$UserMentionFromJson(json);

  String? id_str;

  List<int>? indices;

  String? name;

  String? screen_name;
}
