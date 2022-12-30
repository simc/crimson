import 'dart:convert' as c;
import 'dart:io';

import 'package:crimson/crimson.dart';

import 'twitter/tweet.dart';

void main() {
  final bytes = File('twitter.json').readAsBytesSync();

  print('Benchmarking Crimson and json_serializable decoding...');

  final crimson = bench(() {
    Crimson(bytes).readTweetList();
  });

  final jsonSerialize = bench(() {
    final list = c.json.fuse(c.utf8).decode(bytes) as List;
    list.map((e) => Tweet.fromJson(e as Map<String, dynamic>)).toList();
  });

  print('\n-- JSON without whitespace --');
  print('Crimson:        ${crimson}ms');
  print('json_serialize: ${jsonSerialize}ms');

  final json = c.json.fuse(c.utf8).decode(bytes) as List;
  final prettyJson = c.JsonEncoder.withIndent('    ').convert(json);
  final prettyJsonBytes = c.utf8.encode(prettyJson);

  final crimsonPretty = bench(() {
    Crimson(prettyJsonBytes).readTweetList();
  });

  final jsonSerializePretty = bench(() {
    final list = c.json.fuse(c.utf8).decode(prettyJsonBytes) as List;
    list.map((e) => Tweet.fromJson(e as Map<String, dynamic>)).toList();
  });

  print('\n-- JSON with whitespace --');
  print('Crimson:        ${crimsonPretty}ms');
  print('json_serialize: ${jsonSerializePretty}ms');
}

int bench(void Function() f) {
  for (var i = 0; i < 10; i++) {
    f();
  }
  final s = Stopwatch()..start();
  for (var i = 0; i < 20; i++) {
    f();
  }
  s.stop();
  return s.elapsedMilliseconds ~/ 20;
}
