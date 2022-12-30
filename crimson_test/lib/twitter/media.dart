import 'package:crimson/crimson.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart' as m;
import 'package:json_annotation/json_annotation.dart';

part 'media.g.dart';

@JsonSerializable(createToJson: false)
@m.jsonSerializable
@json
class Media {
  Media();

  factory Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);

  String? display_url;

  String? expanded_url;

  String? id_str;

  List<int>? indices;

  String? media_url;

  String? media_url_https;

  Sizes? sizes;

  String? source_status_id_str;

  String? type;

  String? url;

  VideoInfo? video_info;

  AdditionalMediaInfo? additional_mediaInfo;
}

@JsonSerializable(createToJson: false)
@m.jsonSerializable
@json
class Sizes {
  Sizes();

  factory Sizes.fromJson(Map<String, dynamic> json) => _$SizesFromJson(json);

  Size? thumb;

  Size? medium;

  Size? small;

  Size? large;
}

@JsonSerializable(createToJson: false)
@m.jsonSerializable
@json
class Size {
  Size();

  factory Size.fromJson(Map<String, dynamic> json) => _$SizeFromJson(json);

  int? w;

  int? h;

  String? resize;
}

@JsonSerializable(createToJson: false)
@m.jsonSerializable
@json
class AdditionalMediaInfo {
  AdditionalMediaInfo();

  factory AdditionalMediaInfo.fromJson(Map<String, dynamic> json) =>
      _$AdditionalMediaInfoFromJson(json);

  String? title;

  String? description;

  bool? embeddable;

  bool? monetizable;
}

@JsonSerializable(createToJson: false)
@m.jsonSerializable
@json
class VideoInfo {
  VideoInfo();

  factory VideoInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoFromJson(json);

  List<int>? aspect_ratio;

  int? duration_millis;

  List<Variant>? variants;
}

@JsonSerializable(createToJson: false)
@m.jsonSerializable
@json
class Variant {
  Variant();

  factory Variant.fromJson(Map<String, dynamic> json) =>
      _$VariantFromJson(json);

  int? bitrate;

  String? content_type;

  String? url;
}
