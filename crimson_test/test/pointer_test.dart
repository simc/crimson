import 'dart:convert';

import 'package:crimson/crimson.dart';
import 'package:test/test.dart';

part 'pointer_test.g.dart';

@json
class RfcNoPointer {
  @JsonName('foo')
  List<String>? foo;

  @JsonName('')
  int? empty;

  @JsonName('a/b')
  int? ab;

  @JsonName('c%d')
  int? cd;

  @JsonName('e^f')
  int? ef;

  @JsonName('g|h')
  int? gh;

  @JsonName('i\\j')
  int? ij;

  @JsonName('k\"l')
  int? kl;

  @JsonName(' ')
  int? space;

  @JsonName('m~n')
  int? mn;
}

@json
class RfcPointer {
  @JsonName('/foo')
  List<String>? foo;

  @JsonName('/')
  int? empty;

  @JsonName('/a~1b')
  int? ab;

  @JsonName('/c%d')
  int? cd;

  @JsonName('/e^f')
  int? ef;

  @JsonName('/g|h')
  int? gh;

  @JsonName('/i\\j')
  int? ij;

  @JsonName('/k\"l')
  int? kl;

  @JsonName('/ ')
  int? space;

  @JsonName('/m~0n')
  int? mn;
}

@json
class PointerTest {
  String? before;

  @JsonName('/foo/2/bar')
  String? deep1;

  @JsonName('/2/foo/1')
  String? deep2;

  String? after;
}

Uint8List bytes(Map<String, dynamic> json) {
  return utf8.encode(jsonEncode(json));
}

const rfcJson = {
  "foo": ["bar", "baz"],
  "": 0,
  "a/b": 1,
  "c%d": 2,
  "e^f": 3,
  "g|h": 4,
  "i\\j": 5,
  "k\"l": 6,
  " ": 7,
  "m~n": 8
};

void main() {
  group('Pointer', () {
    test('RFC no pointer', () {
      final rfc = Crimson(bytes(rfcJson)).readRfcNoPointer();
      expect(rfc.foo, ['bar', 'baz']);
      expect(rfc.empty, 0);
      expect(rfc.ab, 1);
      expect(rfc.cd, 2);
      expect(rfc.ef, 3);
      expect(rfc.gh, 4);
      expect(rfc.ij, 5);
      expect(rfc.kl, 6);
      expect(rfc.space, 7);
      expect(rfc.mn, 8);
    });

    test('RFC pointer', () {
      final rfc = Crimson(bytes(rfcJson)).readRfcPointer();
      expect(rfc.foo, ['bar', 'baz']);
      expect(rfc.empty, 0);
      expect(rfc.ab, 1);
      expect(rfc.cd, 2);
      expect(rfc.ef, 3);
      expect(rfc.gh, 4);
      expect(rfc.ij, 5);
      expect(rfc.kl, 6);
      expect(rfc.space, 7);
      expect(rfc.mn, 8);
    });

    test('missing field', () {
      final json = {
        'before': '123',
        'after': '456',
      };
      final obj = Crimson(bytes(json)).readPointerTest();
      expect(obj.before, '123');
      expect(obj.after, '456');
      expect(obj.deep1, isNull);
      expect(obj.deep2, isNull);
    });

    test('missing deep field', () {
      final json = {
        'before': '123',
        'foo': [
          {},
          {},
          {'baz': 'a'}
        ],
        '2': {
          'moo': ['b', 'c']
        },
        'after': '456',
      };
      final obj = Crimson(bytes(json)).readPointerTest();
      expect(obj.before, '123');
      expect(obj.after, '456');
      expect(obj.deep1, isNull);
      expect(obj.deep2, isNull);
    });

    test('wrong field type', () {
      final json = {
        'before': '123',
        'foo': 4,
        '2': 'a',
        'after': '456',
      };
      final obj = Crimson(bytes(json)).readPointerTest();
      expect(obj.before, '123');
      expect(obj.after, '456');
      expect(obj.deep1, isNull);
      expect(obj.deep2, isNull);

      final json2 = {
        'before': '123',
        'foo': {'2': 'c'},
        '2': {'foo': 3.3},
        'after': '456',
      };
      final obj2 = Crimson(bytes(json2)).readPointerTest();
      expect(obj2.before, '123');
      expect(obj2.after, '456');
      expect(obj2.deep1, isNull);
      expect(obj2.deep2, isNull);
    });

    test('empty field', () {
      final json = {
        'before': '123',
        'foo': {},
        '2': {},
        'after': '456',
      };
      final obj = Crimson(bytes(json)).readPointerTest();
      expect(obj.before, '123');
      expect(obj.after, '456');
      expect(obj.deep1, isNull);
      expect(obj.deep2, isNull);

      final json2 = {
        'before': '123',
        'foo': {'2': []},
        '2': {'foo': {}},
        'after': '456',
      };
      final obj2 = Crimson(bytes(json2)).readPointerTest();
      expect(obj2.before, '123');
      expect(obj2.after, '456');
      expect(obj2.deep1, isNull);
      expect(obj2.deep2, isNull);
    });

    test('existing field', () {
      final json = {
        'before': '123',
        'foo': [
          'a',
          'b',
          {'bar': 'c'}
        ],
        '2': {
          'foo': ['d', 'e']
        },
        'after': '456',
      };
      final obj = Crimson(bytes(json)).readPointerTest();
      expect(obj.before, '123');
      expect(obj.after, '456');
      expect(obj.deep1, 'c');
      expect(obj.deep2, 'e');
    });
  });
}
