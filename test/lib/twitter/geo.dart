import 'package:crimson/crimson.dart';
import 'package:json_annotation/json_annotation.dart';

part 'geo.g.dart';

@JsonSerializable()
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
enum PlaceType {
  admin,
  country,
  city,
  poi,
  neighborhood;
}

@JsonSerializable()
@json
class Coordinates {
  Coordinates();

  factory Coordinates.fromJson(Map<String, dynamic> json) =>
      _$CoordinatesFromJson(json);

  List<double>? coordinates;

  String? type;
}
