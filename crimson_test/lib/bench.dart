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

  print('Benchmarking Crimson and json_serializable decoding...');
  runBenchmark('Big JSON without whitespace', bytes);

  final prettyJson = c.JsonEncoder.withIndent('    ').convert(json);
  final prettyJsonBytes = c.utf8.encode(prettyJson);
  runBenchmark('Big JSON with whitespace', prettyJsonBytes);

  final mediumJson = json.sublist(0, 500);
  final mediumJsonBytes = c.utf8.encode(c.json.encode(mediumJson));
  runBenchmark('Medium JSON without whitespace', mediumJsonBytes);

  final smallJson = json.sublist(0, 50);
  final smallJsonBytes = c.utf8.encode(c.json.encode(smallJson));
  runBenchmark('Small JSON without whitespace', smallJsonBytes);
}

void runBenchmark(String name, List<int> jsonBytes) {
  final crimson = bench(() {
    Crimson(jsonBytes).readTweetList();
  });

  final jsonSerialize = bench(() {
    final list = c.json.fuse(c.utf8).decode(jsonBytes) as List;
    list.map((e) => Tweet.fromJson(e as Map<String, dynamic>)).toList();
  });

  final jsonMapper = bench(() {
    final list = c.json.fuse(c.utf8).decode(jsonBytes) as List;
    list.map((e) => JsonMapper.deserialize<Tweet>(e)).toList();
  }, times: 2);

  print('\n-- $name --');
  print('Crimson:             ${formatTime(crimson)}');
  print('json_serialize:      ${formatTime(jsonSerialize)}');
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
