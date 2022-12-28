import 'package:crimson/crimson.dart';
import 'package:json_annotation/json_annotation.dart';

import 'entities.dart';
import 'util.dart';

part 'user.g.dart';

@JsonSerializable(createToJson: false)
@Json()
class User {
  User();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  String? id_str;

  String? name;

  String? screen_name;

  String? location;

  String? url;

  UserEntities? entities;

  String? description;

  bool? protected;

  bool? verified;

  int? followers_count;

  int? friends_count;

  int? listed_count;

  int? favorites_count;

  int? statuses_count;

  @JsonKey(fromJson: convertTwitterDateTime)
  @JsonField(fromJson: convertTwitterDateTime)
  DateTime? createt_at;

  String? profile_banner_url;

  String? profile_image_url_https;

  bool? default_profile;

  bool? default_profile_image;

  List<String>? withheld_in_countries;

  String? withheld_scope;
}

@JsonSerializable(createToJson: false)
@Json()
class UserEntities {
  UserEntities();

  factory UserEntities.fromJson(Map<String, dynamic> json) =>
      _$UserEntitiesFromJson(json);

  UserEntityUrl? url;

  UserEntityUrl? description;
}

@JsonSerializable(createToJson: false)
@Json()
class UserEntityUrl {
  UserEntityUrl();

  factory UserEntityUrl.fromJson(Map<String, dynamic> json) =>
      _$UserEntityUrlFromJson(json);

  List<Url>? urls;
}
