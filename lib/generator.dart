import 'package:build/build.dart';
import 'package:crimson/src/generator/generator.dart';
import 'package:source_gen/source_gen.dart';

/// A builder which generates Crimson code.
Builder getCrimsonGenerator(BuilderOptions options) {
  return SharedPartBuilder([CrimsonGenerator()], 'crimson');
}
