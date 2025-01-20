# 0.4.0

- Bump dependencies, to support latest analyzer
- Fixed support for freezed classes and from factories

# 0.3.1

- Bump dependencies
- Fix small issue with nullable `dynamic` values

# 0.3.0

- Support for `.fromJson()` and `.toJson()` methods
- Support for `.fromBytes()` and `.toBytes()` methods
- Support for `.fromCrimson()` and `.toCrimson()` methods
- Fixes for encoding json

# 0.2.1

- Fixed decoding of long Strings
- Improved default value handling
- Added default enum value if no value is found
- Improved code generation

# 0.2.0

- Experimental support for serializing JSON
- Support for Sets
- Support for escape sequences in object keys
- Support for JSON pointers (RFC 6901)
- Added crimson.whatIsNext() to get the next value type

# 0.1.2

- Small improvements
- Updated readme

# 0.1.1

- Fixed edge cases
- Added verification of data types
- Minor performance improvements

# 0.1.0

- Made `skipPartialObject()` and `skipPartialList()` public
- Replaced `JsonConverter` interface with a `@JsonConvert()` annotation
- Added more unit tests

# 0.0.5

- Changed annotations again (sorry! this is the last time)
- Added `@JsonName()`, `@jsonIgnore`, `@jsonKebabCase` and `@jsonSnakeCase` annotations annotations
- Added `JsonConverter` interface to allow custom parsing and serialization

# 0.0.4

- Replaced `@json` and `@JsonEnum()` with `@Json()`
- Fixed number parsing for exotic doubles
- Improved performance
- Added logo
- Added example

# 0.0.3

- Fixed analyzer version unsupported by Flutter
- Added support for freezed
- Slightly improved performance

## 0.0.2

- Implementation

## 0.0.1

- Initial version.
