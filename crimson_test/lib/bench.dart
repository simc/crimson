import 'dart:convert' as c;
import 'dart:io';

import 'package:bench/bench.mapper.g.dart';
import 'package:crimson/crimson.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'twitter/tweet.dart';

void main() {
  initializeJsonMapper();
  final bytes = File('twitter.json').readAsBytesSync();
  final json = c.json.fuse(c.utf8).decode(bytes) as List;

  final prettyJson = c.JsonEncoder.withIndent('    ').convert(json);
  final prettyJsonBytes = c.utf8.encode(prettyJson);

  final mediumJson = json.sublist(0, 500);
  final mediumJsonBytes = c.utf8.encode(c.json.encode(mediumJson));

  final smallJson = json.sublist(0, 50);
  final smallJsonBytes = c.utf8.encode(c.json.encode(smallJson));

  print('Benchmarking encoding...');
  runEncodeBenchmark('Big JSON', bytes);
  runEncodeBenchmark('Medium JSON', mediumJsonBytes);
  runEncodeBenchmark('Small JSON', smallJsonBytes);

  print('\nBenchmarking decoding...');
  runDecodeBenchmark('Big JSON without whitespace', bytes);
  runDecodeBenchmark('Big JSON with whitespace', prettyJsonBytes);
  runDecodeBenchmark('Medium JSON without whitespace', mediumJsonBytes);
  runDecodeBenchmark('Small JSON without whitespace', smallJsonBytes);
}

void runEncodeBenchmark(String name, List<int> jsonBytes) {
  final tweets = Crimson(jsonBytes).readTweetList();
  print('\n-- $name --');

  final crimson = bench(() {
    final w = CrimsonWriter();
    w.writeTweetList(tweets);
  });
  print('Crimson:             ${formatTime(crimson)}');

  final jsonSerialize = bench(() {
    final json = tweets.map((e) => e.toJson()).toList();
    c.json.fuse(c.utf8).encode(json);
  });
  print('json_serialize:      ${formatTime(jsonSerialize)}');

  final jsonMapper = bench(() {
    final json = tweets.map((e) => JsonMapper.serialize(e)).toList();
    c.json.fuse(c.utf8).encode(json);
  }, times: 2);
  print('dart_json_mapper:    ${formatTime(jsonMapper)}');
}

void runDecodeBenchmark(String name, List<int> jsonBytes) {
  print('\n-- $name --');

  final crimson = bench(() {
    Crimson(jsonBytes).readTweetList();
  });
  print('Crimson:             ${formatTime(crimson)}');

  final jsonSerialize = bench(() {
    final list = c.json.fuse(c.utf8).decode(jsonBytes) as List;
    list.map((e) => Tweet.fromJson(e as Map<String, dynamic>)).toList();
  });
  print('json_serialize:      ${formatTime(jsonSerialize)}');

  final jsonMapper = bench(() {
    final list = c.json.fuse(c.utf8).decode(jsonBytes) as List;
    list.map((e) => JsonMapper.deserialize<Tweet>(e)).toList();
  }, times: 2);
  print('dart_json_mapper:    ${formatTime(jsonMapper)}');
}

int bench(void Function() f, {int times = 20}) {
  for (var i = 0; i < times / 2; i++) {
    f();
  }
  final s = Stopwatch()..start();
  for (var i = 0; i < times; i++) {
    f();
  }
  s.stop();
  return s.elapsedMicroseconds ~/ times;
}

String formatTime(int microseconds) {
  if (microseconds < 5000) {
    return '${microseconds}µs';
  } else if (microseconds < 1000000) {
    return '${microseconds / 1000}ms';
  } else {
    return '${microseconds / 1000000}s';
  }
}
