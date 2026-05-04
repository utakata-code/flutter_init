import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../1_domain/exceptions/domain_exceptions.dart';

/// 外部プロセス実行を担うデータソース
///
/// flutter create / flutter analyze 等を呼び出す。
/// flutter 実行ファイルのパスはコンストラクタ時に自動解決し、キャッシュする。
///
/// インスタンス生成は [ProcessDataSource.create] を使用すること。
class ProcessDataSource {
  /// 解決済みの flutter 実行ファイルパス
  final String _flutterExe;

  ProcessDataSource._(this._flutterExe);

  /// 非同期ファクトリコンストラクタ
  ///
  /// 以下の優先順位で flutter 実行ファイルを自動解決する:
  ///   1. 環境変数 FLUTTER_PATH
  ///   2. 環境変数 FLUTTER_ROOT → {root}/bin/flutter
  ///   3. which (macOS/Linux) / where (Windows) で PATH 検索
  ///   4. 見つからなければ [FlutterNotFoundException] をスロー
  static Future<ProcessDataSource> create() async {
    final exe = await _resolveFlutterExecutable();
    return ProcessDataSource._(exe);
  }

  /// flutter 実行ファイルのパスを解決する
  static Future<String> _resolveFlutterExecutable() async {
    // 1. 環境変数 FLUTTER_PATH（フルパス指定）
    final envPath = Platform.environment['FLUTTER_PATH'];
    if (envPath != null && envPath.isNotEmpty && File(envPath).existsSync()) {
      return envPath;
    }

    // 2. 環境変数 FLUTTER_ROOT（SDK ルートディレクトリ）
    final envRoot = Platform.environment['FLUTTER_ROOT'];
    if (envRoot != null && envRoot.isNotEmpty) {
      final candidate = p.join(envRoot, 'bin', 'flutter');
      if (File(candidate).existsSync()) return candidate;
    }

    // 3. PATH 検索（which / where）
    final result = await Process.run(
      Platform.isWindows ? 'where' : 'which',
      ['flutter'],
    );
    if (result.exitCode == 0) {
      final line = (result.stdout as String).trim().split('\n').first.trim();
      if (line.isNotEmpty) return line;
    }

    throw const FlutterNotFoundException();
  }

  /// flutter create を実行する
  ///
  /// 成功時は true を返す
  Future<bool> flutterCreate({
    required String appName,
    required String projectName,
    required String org,
    required String platforms,
    required String description,
    String? workingDir,
  }) async {
    final result = await Process.run(
      _flutterExe,
      [
        'create',
        '--empty',
        '--project-name=$projectName',
        '--org=$org',
        '--description=$description',
        '--platforms=$platforms',
        appName,
      ],
      workingDirectory: workingDir,
    );

    stdout.write(result.stdout);
    if (result.exitCode != 0) {
      stderr.write(result.stderr);
      return false;
    }
    return true;
  }

  /// flutter analyze を実行してその出力を返す
  Future<String> flutterAnalyze(String projectDir) async {
    final result = await Process.run(
      _flutterExe,
      ['analyze'],
      workingDirectory: projectDir,
    );
    return result.stdout as String;
  }

  /// flutter --version を実行してバージョン文字列を返す
  Future<String> flutterVersion() async {
    final result = await Process.run(
      _flutterExe,
      ['--version', '--machine'],
    );
    return result.stdout as String;
  }
}
