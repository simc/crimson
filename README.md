<h1 align="center">
  <a href="https://github.com/simc/crimson">
    <img src="https://raw.githubusercontent.com/simc/crimson/main/.github/crimson.svg" width="350">
  </a>
</h1>

<p align="center">
  <a href="https://pub.dev/packages/crimson">
    <img src="https://img.shields.io/pub/v/crimson?label=pub.dev&labelColor=333940&logo=dart">
  </a>
  <a href="https://github.com/simc/crimson/actions/workflows/test.yaml">
    <img src="https://img.shields.io/github/actions/workflow/status/simc/crimson/test.yaml?branch=main&label=tests&labelColor=333940&logo=github">
  </a>
  <a href="https://app.codecov.io/gh/simc/crimson">
    <img src="https://img.shields.io/codecov/c/github/simc/crimson?logo=codecov&logoColor=fff&labelColor=333940">
  </a>
  <a href="https://twitter.com/simonleier">
    <img src="https://img.shields.io/twitter/follow/simonleier?style=flat&label=Follow&color=1DA1F2&labelColor=333940&logo=twitter&logoColor=fff">
  </a>
</p>

<p align="center">Fast, efficient and easy-to-use JSON parser and serializer for Dart.</p>

> 🚧 **Crimson is still in early development and is not ready for production use. <br> Only parsing is supported for now** 🚧

## Features

- 🏎️ **Fast**: Like really fast. Crimson parses JSON in a single pass.
- 🌻 **Easy to use**: Crimson is designed to be easy to use and understand.
- 💃 **Flexible**: Crimson can partially parse and serialize JSON.
- 🥶 **Freezed support**: Crimson supports [freezed](https://pub.dev/packages/freezed) classes.
- 🪶 **Lightweight**: Crimson is lightweight and has no third-party dependencies.

## Usage

After adding Crimson to your `pubspec.yaml`, you can start annotating your classes with `@Json()` and optionally `@JsonField()`:

```dart
import 'package:crimson/crimson.dart';

part 'tweet.g.dart';

@Json()
class Tweet {
  DateTime? created_at;

  @JsonField(name: 'text')
  String? tweet;

  int? reply_count;

  int? retweet_count;

  int? favorite_count;
}
```

Now you just need to run `pub run build_runner build` to generate the necessary code.

```dart
import 'package:crimson/crimson.dart';

void main() {
  final jsonBytes = downloadTweets();
  final crimson = Crimson(jsonBytes);

  final tweets = crimson.parseTweetList();
}
```

That's it! You can now parse and serialize JSON with ease.

## Freezed Support

Crimson supports classes annotated with `@freezed` from the [freezed](https://pub.dev/packages/freezed) package.

```dart
import 'package:crimson/crimson.dart';

part 'tweet.g.dart';
part 'tweet.freezed.dart';

@freezed
class Tweet with _$Tweet {
  @Json()
  const factory Tweet({
    DateTime? created_at,
    @JsonField(name: 'text') String? tweet,
    int? reply_count,
    int? retweet_count,
    int? favorite_count,
  }) = _Tweet;
}
```

### License

```
Copyright 2022 Simon Choi

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
