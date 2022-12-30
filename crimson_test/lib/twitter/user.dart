import 'package:crimson/crimson.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart' as m;
import 'package:json_annotation/json_annotation.dart';

import 'entities.dart';

part 'user.g.dart';

@JsonSerializable()
@m.jsonSerializable
@json
class User {
  User();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

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

  String? createt_at;

  String? profile_banner_url;

  String? profile_image_url_https;

  bool? default_profile;

  bool? default_profile_image;

  List<String>? withheld_in_countries;

  String? withheld_scope;
}

@JsonSerializable()
@m.jsonSerializable
@json
class UserEntities {
  UserEntities();

  factory UserEntities.fromJson(Map<String, dynamic> json) =>
      _$UserEntitiesFromJson(json);

  Map<String, dynamic> toJson() => _$UserEntitiesToJson(this);

  UserEntityUrl? url;

  UserEntityUrl? description;
}

@JsonSerializable()
@m.jsonSerializable
@json
class UserEntityUrl {
  UserEntityUrl();

  factory UserEntityUrl.fromJson(Map<String, dynamic> json) =>
      _$UserEntityUrlFromJson(json);

  Map<String, dynamic> toJson() => _$UserEntityUrlToJson(this);

  List<Url>? urls;
}
