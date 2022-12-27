// ignore_for_file: avoid_js_rounded_ints

import 'dart:math';
import 'dart:typed_data';

import 'package:crimson/src/consts.dart';

/// Crimson is a JSON parser that is optimized for speed.
class Crimson {
  /// Creates a new Crimson instance from a [buffer] that reads between [head]
  /// and [tail].
  Crimson(this.buffer, [int head = 0, int? tail])
      : _head = head,
        _tail = tail ?? buffer.length;

  /// The buffer to read from.
  final List<int> buffer;
  late Uint16List _stringBuffer = Uint16List(256);

  int _head;
  final int _tail;

  Never _error(int offset, {String? expected}) {
    throw FormatException(
      'Unexpected token: '
      '${expected != null ? 'expected $expected actual: ' : ''}'
      '${String.fromCharCode(buffer[offset])}',
      buffer,
      offset,
    );
  }

  int _nextToken() {
    var i = _head;

    final token = buffer[i];
    if (token != tokenSpace &&
        token != tokenTab &&
        token != tokenLineFeed &&
        token != tokenCarriageReturn) {
      _head += 1;
      return token;
    }
    while (true) {
      final token = buffer[i++];
      if (token != tokenSpace &&
          token != tokenTab &&
          token != tokenLineFeed &&
          token != tokenCarriageReturn) {
        _head = i;
        return token;
      }
    }
  }

  /// Skips the next value.
  void skip() {
    switch (_nextToken()) {
      case tokenDoubleQuote:
        _skipString();
        break;
      case tokenT:
        _head += 3;
        break;
      case tokenF:
        _head += 4;
        break;
      case tokenN:
        _head += 3;
        break;
      case tokenLBracket:
        _skipList();
        break;
      case tokenLBrace:
        _skipObject();
        break;
      default:
        _skipNumber();
        break;
    }
  }

  void _skipString() {
    var escaped = false;
    for (var i = _head; i < _tail; i++) {
      final c = buffer[i];
      if (c == tokenDoubleQuote) {
        if (!escaped) {
          _head = i + 1;
          return;
        } else {
          var j = i - 1;
          while (true) {
            if (j < _head || buffer[j] != tokenBackslash) {
              // even number of backslashes either end of buffer, or " found
              _head = i + 1;
              return;
            }
            j--;
            if (j < _head || buffer[j] != tokenBackslash) {
              // odd number of backslashes it is \" or \\\"
              break;
            }
            j--;
          }
        }
      } else if (c == tokenBackslash) {
        escaped = true;
      }
    }
    _error(_head - 1, expected: '"');
  }

  void _skipNumber() {
    var i = _head;
    while (true) {
      final c = buffer[i++];
      if (c ^ tokenZero > 9 &&
          c != tokenMinus &&
          c != tokenPlus &&
          c != tokenPeriod &&
          c != tokenE &&
          c != tokenUpperE) {
        break;
      }
    }
    _head = i - 1;
  }

  void _skipList() {
    var level = 1;
    for (var i = _head; i < _tail; i++) {
      switch (buffer[i]) {
        case tokenDoubleQuote: // If inside string, skip it
          _head = i + 1;
          _skipString();
          i = _head - 1;
          break;
        case tokenLBracket: // If open symbol, increase level
          level++;
          break;
        case tokenRBracket: // If close symbol, decrease level
          level--;
          // If we have returned to the original level, we're done
          if (level == 0) {
            _head = i + 1;
            return;
          }
          break;
      }
    }
    _error(_head - 1, expected: ']');
  }

  void _skipObject() {
    var level = 1;
    for (var i = _head; i < _tail; i++) {
      switch (buffer[i]) {
        case tokenDoubleQuote: // If inside string, skip it
          _head = i + 1;
          _skipString();
          i = _head - 1;
          break;
        case tokenLBrace: // If open symbol, increase level
          level++;
          break;
        case tokenRBrace: // If close symbol, decrease level
          level--;

          // If we have returned to the original level, we're done
          if (level == 0) {
            _head = i + 1;
            return;
          }
          break;
      }
    }
    _error(_head - 1, expected: '}');
  }

  int? _tryReadInt() {
    var i = _head;
    var sign = 1;
    if (buffer[i] == tokenMinus) {
      i++;
      sign = -1;
    }

    var number = 0;
    while (true) {
      final c = buffer[i++];
      final digit = c ^ tokenZero;
      if (digit <= 9) {
        number = number * 10 + digit;
      } else {
        break;
      }
    }

    _head = i - 1;
    return number * sign;
  }

  /// Reads a number value. This method always returns an [int] value for whole
  /// numbers, and a [double] value for numbers with a fractional part.
  num readNum() {
    final start = _head;
    final number = _tryReadInt();
    if (number == null) {
      return _readNumSlowPath(start);
    }

    if (_head == _tail) {
      return number;
    }

    double? doubleNumber;
    if (buffer[_head] == tokenPeriod) {
      _head++;
      final decimalStart = _head;
      final decimal = _tryReadInt();
      if (decimal == null) {
        return _readNumSlowPath(start);
      }
      doubleNumber = number + decimal / pow(10, _head - decimalStart);
      if (_head == _tail) {
        return doubleNumber;
      }
    }

    if (_head != _tail) {
      final nextToken = buffer[_head];
      if (nextToken == tokenE || nextToken == tokenUpperE) {
        return _readNumSlowPath(start);
      }
    }

    return doubleNumber ?? number;
  }

  num _readNumSlowPath(int start) {
    _skipNumber();
    final string = String.fromCharCodes(buffer, start, _head);
    final number = double.parse(string);
    if (number % 1 == 0) {
      return number.toInt();
    } else {
      return number;
    }
  }

  /// Returns whether the next value is null.
  @pragma('vm:prefer-inline')
  bool isNull() {
    return buffer[_head] == tokenN;
  }

  /// Reads a null value. You need to call this method to skip a null value.
  @pragma('vm:prefer-inline')
  // ignore: prefer_void_to_null
  Null readNull() {
    _head += 4;
  }

  /// Reads a string value.
  String readString() {
    var i = _head;
    if (buffer[i++] != tokenDoubleQuote) {
      _error(_head - 1, expected: '"');
    }

    var si = 0;
    while (true) {
      var bc = buffer[i++];
      if (bc == tokenDoubleQuote) {
        _head = i;
        return String.fromCharCodes(_stringBuffer, 0, si);
      }
      if (bc == tokenBackslash) {
        bc = buffer[i++];
        switch (bc) {
          case tokenB:
            bc = tokenBackspace;
            break;
          case tokenT:
            bc = tokenTab;
            break;
          case tokenN:
            bc = tokenLineFeed;
            break;
          case tokenF:
            bc = tokenFormFeed;
            break;
          case tokenR:
            bc = tokenCarriageReturn;
            break;
          case tokenDoubleQuote:
          case tokenSlash:
          case tokenBackslash:
            break;
          case tokenU:
            bc = (_parseHexDigit(i++) << 12) +
                (_parseHexDigit(i++) << 8) +
                (_parseHexDigit(i++) << 4) +
                _parseHexDigit(i++);
            break;
          default:
            _error(i - 1, expected: 'valid escape sequence');
        }
      } else if ((bc & 0x80) != 0) {
        final u2 = buffer[i++];
        if ((bc & 0xE0) == 0xC0) {
          bc = ((bc & 0x1F) << 6) + (u2 & 0x3F);
        } else {
          final u3 = buffer[i++];
          if ((bc & 0xF0) == 0xE0) {
            bc = ((bc & 0x0F) << 12) + ((u2 & 0x3F) << 6) + (u3 & 0x3F);
          } else {
            final u4 = buffer[i++];
            bc = ((bc & 0x07) << 18) +
                ((u2 & 0x3F) << 12) +
                ((u3 & 0x3F) << 6) +
                (u4 & 0x3F);

            if (bc >= 0x10000) {
              // split surrogates
              final sup = bc - 0x10000;
              if (si >= _stringBuffer.length - 1) {
                final old = _stringBuffer;
                _stringBuffer = Uint16List(_stringBuffer.length * 2);
                _stringBuffer.setAll(0, old);
              }
              _stringBuffer[si++] = (sup >>> 10) + 0xd800;
              _stringBuffer[si++] = (sup & 0x3ff) + 0xdc00;
              continue;
            }
          }
        }
      }
      if (si == _stringBuffer.length) {
        final old = _stringBuffer;
        _stringBuffer = Uint16List(_stringBuffer.length * 2);
        _stringBuffer.setAll(0, old);
      }
      _stringBuffer[si++] = bc;
    }
  }

  int _parseHexDigit(int offset) {
    final char = buffer[offset];
    final digit = char ^ 0x30;
    if (digit <= 9) return digit;
    final letter = (char | 0x20) ^ 0x60;
    // values 1 .. 6 are 'a' through 'f'
    if (letter <= 6 && letter > 0) return letter + 9;
    _error(offset, expected: 'hex digit');
  }

  /// Reads a string value as hash.
  ///
  /// The hash function is based on the FNV-1a algorithm. [hash] yields the same
  /// value as [readStringHash] for the same string.
  int readStringHash() {
    var i = _head;
    if (buffer[i++] != tokenDoubleQuote) {
      _error(_head - 1, expected: '"');
    }

    var hash = 0xcbf29ce484222325;
    while (true) {
      final c = buffer[i++];
      if (c == tokenDoubleQuote) {
        _head = i;
        return hash;
      }
      hash ^= c >> 8;
      hash *= 0x100000001b3;
      hash ^= c & 0xFF;
      hash *= 0x100000001b3;
    }
  }

  /// Allows iterating a list value without allocating a [List].
  ///
  /// Returns `true` if there is another element in the list.
  bool iterList() {
    var c = _nextToken();
    switch (c) {
      case tokenLBracket:
      case tokenComma:
        c = _nextToken();
        if (c == tokenRBracket) {
          return false;
        }
        _head--;
        return true;
      case tokenRBracket:
        return false;
      default:
        _error(_head - 1, expected: '[ or , or ]');
    }
  }

  T _iterObject<T>(T Function() readField, T endValue) {
    var c = _nextToken();
    switch (c) {
      case tokenLBrace:
      case tokenComma:
        c = _nextToken();
        if (c == tokenRBrace) {
          return endValue;
        }
        _head--;
        final field = readField();
        final colon = _nextToken();
        if (colon != tokenColon) {
          _error(_head - 1, expected: ':');
        }
        return field;
      case tokenRBrace:
        return endValue;
      default:
        _error(_head - 1, expected: '{ or , or }');
    }
  }

  /// Allows iterating a map value without allocating a [Map].
  ///
  /// Returns the next field name, or `null` if there are no more fields.
  @pragma('vm:prefer-inline')
  String? iterObject() => _iterObject(readString, null);

  /// Allows iterating a map value without allocating a [Map].
  ///
  /// Returns a hash of the next field name, or `-1` if there are no more
  /// fields.
  @pragma('vm:prefer-inline')
  int iterObjectHash() => _iterObject(readStringHash, -1);

  /// Convenience method to read a list.
  List<dynamic> readList() {
    final list = <dynamic>[];
    while (iterList()) {
      list.add(read());
    }
    return list;
  }

  /// Convenience method to read a map.
  Map<String, dynamic> readMap() {
    final map = <String, dynamic>{};
    for (var field = iterObject(); field != null; field = iterObject()) {
      map[field] = read();
    }
    return map;
  }

  dynamic _read() {
    switch (buffer[_head]) {
      case tokenDoubleQuote:
        return readString();
      case tokenT:
        _head += 4;
        return true;
      case tokenF:
        _head += 5;
        return false;
      case tokenN:
        _head += 4;
        return null;
      case tokenLBracket:
        return readList();
      case tokenLBrace:
        return readMap();
      default:
        return readNum();
    }
  }

  /// Reads the next value.
  @pragma('vm:prefer-inline')
  dynamic read() {
    _nextToken();
    _head--;
    return _read();
  }

  /// Hashes the given String with the same algorithm as [readStringHash] and
  /// [iterObjectHash].
  static int hash(String string) {
    var hash = 0xcbf29ce484222325;

    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }

    return hash;
  }
}
