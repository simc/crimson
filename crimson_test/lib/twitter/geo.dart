import 'package:crimson/crimson.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart' as m;
import 'package:json_annotation/json_annotation.dart';

part 'geo.g.dart';

@JsonSerializable(createToJson: false)
@m.jsonSerializable
@json
class Place {
  Place();

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);

  String? id;

  String? url;

  PlaceType? place_type;

  String? name;

  String? full_name;

  String? country_code;

  String? country;
}

@json
@m.jsonSerializable
enum PlaceType {
  admin,
  country,
  city,
  poi,
  neighborhood;
}

@JsonSerializable(createToJson: false)
@m.jsonSerializable
@json
class Coordinates {
  Coordinates();

  factory Coordinates.fromJson(Map<String, dynamic> json) =>
      _$CoordinatesFromJson(json);

  List<double>? coordinates;

  String? type;
}
