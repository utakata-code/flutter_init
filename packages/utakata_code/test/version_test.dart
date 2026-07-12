import 'dart:io';

import 'package:test/test.dart';
import 'package:utakata/src/version.g.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('version.g.dart matches pubspec.yaml version', () {
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as Map;
    expect(
      packageVersion,
      pubspec['version'],
      reason:
          'lib/src/version.g.dart is stale — run `dart run tool/generate_version.dart`',
    );
  });
}
