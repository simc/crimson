import 'dart:convert';
import 'dart:io';

import 'package:crimson/crimson.dart';

import 'twitter/tweet.dart';

void main() {
  final bytes = File('twitter.json').readAsBytesSync();

  for (var i = 0; i < 5; i++) {
    final s = Stopwatch()..start();
    Crimson(bytes).readTweetList();
    s.stop();

    final s2 = Stopwatch()..start();
    final list = json.fuse(utf8).decode(bytes) as List;
    list.map((e) => Tweet.fromJson(e as Map<String, dynamic>)).toList();
    s2.stop();

    print(
        'Crimson: ${s.elapsedMilliseconds}ms JSON: ${s2.elapsedMilliseconds}ms');
  }
}
