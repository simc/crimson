// ignore_for_file: avoid_js_rounded_ints

import 'dart:typed_data';

import 'package:crimson/src/consts.dart';

/// Crimson is a JSON parser that is optimized for speed.
class Crimson {
  /// Creates a new Crimson instance from a [buffer] that reads from [offset].
  Crimson(this.buffer, [int offset = 0]) : _offset = offset;

  /// The buffer to read from.
  final List<int> buffer;
  late Uint16List _stringBuffer = Uint16List(256);

  int _offset;

  /// The current offset.
  int get offset => _offset;

  Never _error(int offset, {String? expected}) {
    throw FormatException(
      'Unexpected token: '
      '${expected != null ? 'expected $expected actual: ' : ''}'
      '${String.fromCharCodes(buffer, offset, offset + 20)}',
      buffer,
      offset,
    );
  }

  @pragma('vm:prefer-inline')
  void _skipWhitespace() {
    var i = _offset;
    if (buffer[i] > tokenSpace) {
      return;
    }

    while (buffer[++i] <= tokenSpace) {}
    _offset = i;
  }

  /// Skips the next value.
  void skip() {
    _skipWhitespace();
    switch (buffer[_offset++]) {
      case tokenDoubleQuote:
        _skipString();
        break;
      case tokenT:
        _offset += 3;
        break;
      case tokenF:
        _offset += 4;
        break;
      case tokenN:
        _offset += 3;
        break;
      case tokenLBracket:
        skipPartialList();
        break;
      case tokenLBrace:
        skipPartialObject();
        break;
      default:
        _skipNumber();
        break;
    }
  }

  void _skipString() {
    var escaped = false;
    for (var i = _offset;; i++) {
      final c = buffer[i];
      if (c == tokenDoubleQuote) {
        if (!escaped) {
          _offset = i + 1;
          return;
        } else {
          var j = i - 1;
          while (true) {
            if (j < _offset || buffer[j] != tokenBackslash) {
              // even number of backslashes either end of buffer, or " found
              _offset = i + 1;
              return;
            }
            j--;
            if (j < _offset || buffer[j] != tokenBackslash) {
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
  }

  void _skipNumber() {
    var i = _offset;
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
    _offset = i - 1;
  }

  /// Skips the remaining values in the current list.
  void skipPartialList() {
    var level = 1;
    var i = _offset;
    while (true) {
      switch (buffer[i++]) {
        case tokenDoubleQuote: // If inside string, skip it
          _offset = i;
          _skipString();
          i = _offset;
          break;
        case tokenLBracket: // If open symbol, increase level
          level++;
          break;
        case tokenRBracket: // If close symbol, decrease level
          level--;
          // If we have returned to the original level, we're done
          if (level == 0) {
            _offset = i;
            return;
          }
          break;
      }
    }
  }

  /// Skips the remaining values in the current object.
  void skipPartialObject() {
    var level = 1;
    var i = _offset;
    while (true) {
      switch (buffer[i++]) {
        case tokenDoubleQuote: // If inside string, skip it
          _offset = i;
          _skipString();
          i = _offset;
          break;
        case tokenLBrace: // If open symbol, increase level
          level++;
          break;
        case tokenRBrace: // If close symbol, decrease level
          level--;

          // If we have returned to the original level, we're done
          if (level == 0) {
            _offset = i;
            return;
          }
          break;
      }
    }
  }

  /// Skips a null value if the next token is null.
  @pragma('vm:prefer-inline')
  bool skipNull() {
    _skipWhitespace();
    if (buffer[_offset] == tokenN) {
      _offset += 4;
      return true;
    } else {
      return false;
    }
  }

  /// Reads an [int] value.
  @pragma('vm:prefer-inline')
  int readInt() {
    _skipWhitespace();
    return _readInt();
  }

  /// Reads an [int] value or null.
  @pragma('vm:prefer-inline')
  int? readIntOrNull() {
    _skipWhitespace();
    if (buffer[_offset] == tokenN) {
      _offset += 4;
      return null;
    } else {
      return _readInt();
    }
  }

  int _readInt() {
    var i = _offset;
    var sign = 1;
    if (buffer[i] == tokenMinus) {
      sign = -1;
      i++;
    }

    var value = buffer[i++] ^ tokenZero;
    if (value > 9) {
      _error(i - 1, expected: 'number');
    }

    while (true) {
      final digit = buffer[i++] ^ tokenZero;
      if (digit <= 9) {
        value = 10 * value + digit;
      } else {
        break;
      }
    }

    _offset = i - 1;
    return sign * value;
  }

  /// Reads a [double] value.
  @pragma('vm:prefer-inline')
  double readDouble() {
    return readNum().toDouble();
  }

  /// Reads a [double] value or null.
  @pragma('vm:prefer-inline')
  double? readDoubleOrNull() {
    return readNumOrNull()?.toDouble();
  }

  /// Reads a numerical value. If the value has a fractional part or is too big,
  /// it is returned as a [double]. Otherwise, it is returned as an [int].
  @pragma('vm:prefer-inline')
  num readNum() {
    _skipWhitespace();
    return _readNum();
  }

  /// Reads a numerical value or null. If the value has a fractional part or is
  /// too big, it is returned as a [double]. Otherwise, it is returned as an
  /// [int].
  @pragma('vm:prefer-inline')
  num? readNumOrNull() {
    _skipWhitespace();
    if (buffer[_offset] == tokenN) {
      _offset += 4;
      return null;
    } else {
      return _readNum();
    }
  }

  num _readNum() {
    final start = _offset;
    var i = start;
    var exponent = 0;
    // Added to exponent for each digit. Set to -1 when seeing '.'.
    var exponentDelta = 0;
    var sign = 1.0;

    if (buffer[i] == tokenMinus) {
      sign = -1.0;
      i++;
    }

    var doubleValue = (buffer[i++] ^ tokenZero).toDouble();
    if (doubleValue > 9) {
      _error(i - 1, expected: 'number');
    }

    while (true) {
      final c = buffer[i++];
      final digit = c ^ tokenZero;
      if (digit <= 9) {
        doubleValue = 10.0 * doubleValue + digit;
        exponent += exponentDelta;
      } else if (c == tokenPeriod && exponentDelta == 0) {
        exponentDelta = -1;
      } else if (c == tokenE || c == tokenUpperE) {
        var expValue = 0;
        var expSign = 1;
        if (buffer[i] == tokenMinus) {
          expSign = -1;
          i++;
        } else if (buffer[i] == tokenPlus) {
          i++;
        }
        while (true) {
          final c = buffer[i++];
          final digit = c ^ tokenZero;
          if (digit <= 9) {
            expValue = 10 * expValue + digit;
          } else {
            break;
          }
        }
        exponent += expSign * expValue;
        break;
      } else {
        break;
      }
    }

    _offset = i - 1;

    if (exponent == 0) {
      if (doubleValue <= maxInt) {
        return (sign * doubleValue).toInt();
      } else {
        return sign * doubleValue;
      }
    } else if (exponent < 0) {
      final negExponent = -exponent;
      if (negExponent < powersOfTen.length) {
        return sign * (doubleValue / powersOfTen[negExponent]);
      }
    } else if (exponent < powersOfTen.length) {
      return sign * (doubleValue * powersOfTen[exponent]);
    }

    final string = String.fromCharCodes(buffer, start, _offset);
    return num.parse(string);
  }

  /// Reads a string value.
  @pragma('vm:prefer-inline')
  String readString() {
    _skipWhitespace();
    return _readString();
  }

  /// Reads a string value or null.
  @pragma('vm:prefer-inline')
  String? readStringOrNull() {
    _skipWhitespace();
    if (buffer[_offset] == tokenN) {
      _offset += 4;
      return null;
    }
    return _readString();
  }

  String _readString() {
    if (buffer[_offset] != tokenDoubleQuote) {
      _error(_offset, expected: '"');
    }
    final start = _offset + 1;
    var i = start;
    while (true) {
      final c = buffer[i++];
      if (c == tokenDoubleQuote) {
        _offset = i;
        return String.fromCharCodes(buffer, start, i - 1);
      } else if (c == tokenBackslash || c >= 128) {
        // If we encounter a backslash, which is a beginning of an escape
        // sequence or a high bit was set - indicating an UTF-8 encoded
        // multibyte character, there is no chance that we can decode the string
        // without instantiating a temporary buffer
        _offset = start;
        return _readStringSlowPath();
      }
    }
  }

  String _readStringSlowPath() {
    var i = _offset;
    var strBuf = _stringBuffer;
    var si = 0;
    while (true) {
      var bc = buffer[i++];
      if (bc == tokenDoubleQuote) {
        _offset = i;
        _stringBuffer = strBuf;
        return String.fromCharCodes(strBuf, 0, si);
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
              if (si >= strBuf.length - 1) {
                strBuf = Uint16List((strBuf.length * 1.5).toInt())
                  ..setAll(0, _stringBuffer);
              }
              strBuf[si++] = (sup >>> 10) + 0xd800;
              strBuf[si++] = (sup & 0x3ff) + 0xdc00;
              continue;
            }
          }
        }
      }
      if (si == strBuf.length) {
        strBuf = Uint16List((strBuf.length * 1.5).toInt())
          ..setAll(0, _stringBuffer);
      }
      strBuf[si++] = bc;
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
  @pragma('vm:prefer-inline')
  int readStringHash() {
    _skipWhitespace();
    return _readStringHash();
  }

  int _readStringHash() {
    if (buffer[_offset] != tokenDoubleQuote) {
      _error(_offset, expected: '"');
    }

    var i = _offset + 1;
    var hash = 0xcbf29ce484222325;
    while (true) {
      final c = buffer[i++];
      if (c == tokenDoubleQuote) {
        _offset = i;
        return hash;
      }
      hash ^= c >> 8;
      hash *= 0x100000001b3;
      hash ^= c & 0xFF;
      hash *= 0x100000001b3;
    }
  }

  /// Reads a DateTime value. Supports both ISO 8601 and UNIX second and
  /// millisecond timestamps.
  DateTime readDateTime() {
    final start = _offset;
    final value = read();
    if (value is String) {
      return DateTime.parse(value);
    } else if (value is num) {
      if (value > 20000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      } else {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);
      }
    } else {
      _error(start, expected: 'DateTime');
    }
  }

  /// Allows iterating a list value without allocating a [List].
  ///
  /// Returns `true` if there is another element in the list.
  bool iterList() {
    _skipWhitespace();
    switch (buffer[_offset++]) {
      case tokenLBracket:
      case tokenComma:
        _skipWhitespace();
        if (buffer[_offset] == tokenRBracket) {
          _offset++;
          return false;
        }
        return true;
      case tokenRBracket:
        return false;
      default:
        _error(_offset - 1, expected: '[ or , or ]');
    }
  }

  T _iterObject<T>(T Function() readField, T endValue) {
    _skipWhitespace();
    switch (buffer[_offset++]) {
      case tokenLBrace:
      case tokenComma:
        _skipWhitespace();
        if (buffer[_offset] == tokenRBrace) {
          _offset++;
          return endValue;
        }

        final field = readField();
        _skipWhitespace();
        if (buffer[_offset++] != tokenColon) {
          _error(_offset - 1, expected: ':');
        }
        return field;
      case tokenRBrace:
        return endValue;
      default:
        _error(_offset - 1, expected: '{ or , or }');
    }
  }

  /// Allows iterating a map value without allocating a [Map].
  ///
  /// Returns the next field name, or `null` if there are no more fields.
  @pragma('vm:prefer-inline')
  String? iterObject() => _iterObject(_readString, null);

  /// Allows iterating a map value without allocating a [Map].
  ///
  /// Returns a hash of the next field name, or `-1` if there are no more
  /// fields.
  @pragma('vm:prefer-inline')
  int iterObjectHash() => _iterObject(_readStringHash, -1);

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

  /// Reads the next value.
  @pragma('vm:prefer-inline')
  dynamic read() {
    _skipWhitespace();
    switch (buffer[_offset]) {
      case tokenDoubleQuote:
        return _readString();
      case tokenT:
        _offset += 4;
        return true;
      case tokenF:
        _offset += 5;
        return false;
      case tokenN:
        _offset += 4;
        return null;
      case tokenLBracket:
        return readList();
      case tokenLBrace:
        return readMap();
      default:
        return _readNum();
    }
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
