import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';
import 'package:utakata/src/version.g.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('version.g.dart matches pubspec.yaml version', () async {
    // Directory.current はプロセス全体で共有され、並列実行中の別スイート
    // (utakata_test.dart)が一時ディレクトリへ chdir するため、CWD 相対の
    // File('pubspec.yaml') はフレークする。パッケージ URI から解決する。
    final libUri = await Isolate.resolvePackageUri(Uri.parse('package:utakata/'));
    final packageRoot = Directory.fromUri(libUri!).parent;
    final pubspecFile = File('${packageRoot.path}/pubspec.yaml');

    final pubspec = loadYaml(pubspecFile.readAsStringSync()) as Map;
    expect(
      packageVersion,
      pubspec['version'],
      reason:
          'lib/src/version.g.dart is stale — run `dart run tool/generate_version.dart`',
    );
  });
}
