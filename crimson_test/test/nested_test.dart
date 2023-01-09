import 'dart:convert';

import 'package:crimson/crimson.dart';
import 'package:test/test.dart';

part 'nested_test.g.dart';

@json
class NestedValues {
  final List<Map<String, NestedValues?>> list;

  final Map<String, List<NestedValues?>> map;

  NestedValues(this.list, this.map);
}

void main() {
  test('nested json', () {
    final json = {
      'list': [
        {
          'a': {
            'list': [
              {
                'deep': {'list':<dynamic>[], 'map': <String, dynamic>{},}
              }
            ],
            'map': <String, dynamic>{},
          },
          'b': {'list':<dynamic>[], 'map': <String, dynamic>{},}
        },
        {
          'b': {'list':<dynamic>[], 'map': <String, dynamic>{},},
          'c': {'list':<dynamic>[], 'map': <String, dynamic>{},}
        },
      ],
      'map': {
        'a': [
          {
            'list':<dynamic>[],
            'map': {
              'deep2': [
                {'list':<dynamic>[], 'map':<String, dynamic>{}}
              ]
            }
          },
          {'list':<dynamic>[], 'map':<String, dynamic>{}}
        ],
        'b': [
          {'list':<dynamic>[], 'map':<String, dynamic>{}},
          {'list':<dynamic>[], 'map':<String, dynamic>{}}
        ],
      },
    };

    final crimson = Crimson(utf8.encode(jsonEncode(json)));
    crimson.readNestedValues();
  });
}
