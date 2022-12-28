// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:crimson/crimson.dart';

void main() {
  const json = '{"name": "John", "age": 42, "tags": ["a", "b"]}';
  final jsonBytes = utf8.encode(json);
  final crimson = Crimson(jsonBytes);
  final map = crimson.read() as Map<String, dynamic>;
  print(map);
}
