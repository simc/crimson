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
                'deep': {'list': [], 'map': {}}
              }
            ],
            'map': {}
          },
          'b': {'list': [], 'map': {}}
        },
        {
          'b': {'list': [], 'map': {}},
          'c': {'list': [], 'map': {}}
        },
      ],
      'map': {
        'a': [
          {
            'list': [],
            'map': {
              'deep2': [
                {'list': [], 'map': {}}
              ]
            }
          },
          {'list': [], 'map': {}}
        ],
        'b': [
          {'list': [], 'map': {}},
          {'list': [], 'map': {}}
        ],
      },
    };

    final crimson = Crimson(utf8.encode(jsonEncode(json)));
    crimson.readNestedValues();
  });
}
