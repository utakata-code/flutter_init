import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'cli_result.dart';

/// utakata CLI との通信を担うブリッジ
///
/// F-01: utakata CLI コマンドを Process.run 経由で実行し、
/// stdout/stderr をリアルタイムにキャプチャする共通基盤。
///
/// 使用例:
/// ```dart
/// final bridge = CliBridge(cliPath: 'dart run utakata');
/// final result = await bridge.run(['validate']);
/// print(result.stdout);
/// ```
class CliBridge {
  /// utakata CLI の実行パス
  ///
  /// デフォルト: `utakata`（PATH 上）
  /// オーバーライド例: `dart run /path/to/utakata_code/bin/utakata.dart`
  final String cliPath;

  /// 作業ディレクトリ（プロジェクトルート）
  final String? workingDirectory;

  const CliBridge({
    this.cliPath = 'utakata',
    this.workingDirectory,
  });

  /// コマンドを同期的に実行し、完了を待つ
  ///
  /// [args] は utakata のサブコマンド + 引数（例: `['validate']`, `['diff']`）
  Future<CliResult> run(List<String> args) async {
    final stopwatch = Stopwatch()..start();

    final (executable, baseArgs) = _resolveCommand(args);

    try {
      final process = await Process.run(
        executable,
        baseArgs,
        workingDirectory: workingDirectory,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
        environment: {'LANG': 'ja_JP.UTF-8'},
        includeParentEnvironment: true,
      );
      stopwatch.stop();

      return CliResult(
        command: executable,
        arguments: baseArgs,
        exitCode: process.exitCode,
        stdout: _stripAnsi(process.stdout as String),
        stderr: _stripAnsi(process.stderr as String),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return CliResult(
        command: executable,
        arguments: baseArgs,
        exitCode: -1,
        stdout: '',
        stderr: 'Failed to execute: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// コマンドをストリーミング実行し、出力をリアルタイムに受け取る
  ///
  /// 長時間コマンド（`utakata feature init` 等）の進捗表示に使用。
  Stream<CliStreamEvent> runStream(List<String> args) async* {
    final stopwatch = Stopwatch()..start();

    final (executable, baseArgs) = _resolveCommand(args);

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    try {
      final process = await Process.start(
        executable,
        baseArgs,
        workingDirectory: workingDirectory,
        environment: {'LANG': 'ja_JP.UTF-8'},
        includeParentEnvironment: true,
      );

      // stdout ストリーム
      await for (final event in _mergeStreams(
        process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .map((line) {
          final cleaned = _stripAnsi(line);
          stdoutBuffer.writeln(cleaned);
          return CliStdoutEvent(cleaned) as CliStreamEvent;
        }),
        process.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .map((line) {
          final cleaned = _stripAnsi(line);
          stderrBuffer.writeln(cleaned);
          return CliStderrEvent(cleaned) as CliStreamEvent;
        }),
      )) {
        yield event;
      }

      final exitCode = await process.exitCode;
      stopwatch.stop();

      yield CliDoneEvent(CliResult(
        command: executable,
        arguments: baseArgs,
        exitCode: exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        duration: stopwatch.elapsed,
      ));
    } catch (e) {
      stopwatch.stop();
      yield CliDoneEvent(CliResult(
        command: executable,
        arguments: baseArgs,
        exitCode: -1,
        stdout: stdoutBuffer.toString(),
        stderr: 'Failed to execute: $e',
        duration: stopwatch.elapsed,
      ));
    }
  }

  /// 2つのストリームをマージする
  Stream<T> _mergeStreams<T>(Stream<T> a, Stream<T> b) {
    final controller = StreamController<T>();
    var doneCount = 0;

    void onDone() {
      doneCount++;
      if (doneCount == 2) controller.close();
    }

    a.listen(controller.add, onError: controller.addError, onDone: onDone);
    b.listen(controller.add, onError: controller.addError, onDone: onDone);

    return controller.stream;
  }

  /// ANSI エスケープコードを除去
  static final _ansiRegex = RegExp(r'\x1B\[[0-9;]*[A-Za-z]');
  static String _stripAnsi(String input) => input.replaceAll(_ansiRegex, '');

  /// cliPath を解析して executable と args に分解する
  ///
  /// - `utakata` → (`utakata`, [...args])
  /// - `dart run /path/to/utakata.dart` → (`<dart_full_path>`, [`run`, `/path/...`, ...args])
  /// - `/path/to/utakata.dart` → (`<dart_full_path>`, [`/path/...`, ...args])  ← 自動補完
  (String, List<String>) _resolveCommand(List<String> args) {
    final trimmed = cliPath.trim();

    // .dart で終わるパスが指定された場合、自動で dart を前置
    if (trimmed.endsWith('.dart') && !trimmed.startsWith('dart ')) {
      return (_dartExecutable, [trimmed, ...args]);
    }

    // "dart ..." で始まる場合もフルパスに置換
    if (trimmed.startsWith('dart ')) {
      final rest = trimmed.substring(5); // "dart " を除去
      return (_dartExecutable, [...rest.split(' '), ...args]);
    }

    // スペース区切りで分割
    final parts = trimmed.split(' ');
    return (parts.first, [...parts.skip(1), ...args]);
  }

  /// dart 実行ファイルのフルパスを取得
  ///
  /// Flutter デスクトップアプリでは PATH に dart が無い場合がある。
  /// `where.exe` → dart-sdk の実体 → PATH 手動スキャンの順で探索。
  static String? _cachedDartPath;
  static String get _dartExecutable {
    if (_cachedDartPath != null) return _cachedDartPath!;

    // 1. where.exe で PATH 上の dart を検索 → dart-sdk の実体を特定
    if (Platform.isWindows) {
      try {
        final result = Process.runSync(
          'where.exe', ['dart'],
          stdoutEncoding: const SystemEncoding(),
        );
        if (result.exitCode == 0) {
          final wherePath = (result.stdout as String).trim().split('\n').first.trim();

          // flutter/bin/dart → flutter/bin/cache/dart-sdk/bin/dart.exe を探す
          final whereDir = File(wherePath).parent.path;
          final dartSdkExe = '$whereDir${Platform.pathSeparator}cache${Platform.pathSeparator}dart-sdk${Platform.pathSeparator}bin${Platform.pathSeparator}dart.exe';
          if (File(dartSdkExe).existsSync()) {
            _cachedDartPath = dartSdkExe;
            return dartSdkExe;
          }

          // .exe 付きを直接チェック
          final withExe = wherePath.endsWith('.exe') ? wherePath : '$wherePath.exe';
          if (File(withExe).existsSync()) {
            _cachedDartPath = withExe;
            return withExe;
          }
        }
      } catch (_) {
        // where.exe が使えない場合はフォールバック
      }
    }

    // 2. PATH 環境変数を手動スキャン（dart.exe を直接探す）
    final pathEnv = Platform.environment['PATH'] ?? Platform.environment['Path'] ?? '';
    final sep = Platform.isWindows ? ';' : ':';
    for (final dir in pathEnv.split(sep)) {
      // dart-sdk の bin を優先チェック
      if (dir.contains('flutter')) {
        final sdkDir = dir.replaceAll(RegExp(r'[/\\]bin$'), '');
        final dartSdkExe = '$sdkDir${Platform.pathSeparator}bin${Platform.pathSeparator}cache${Platform.pathSeparator}dart-sdk${Platform.pathSeparator}bin${Platform.pathSeparator}dart.exe';
        if (File(dartSdkExe).existsSync()) {
          _cachedDartPath = dartSdkExe;
          return dartSdkExe;
        }
      }
      final candidate = '$dir${Platform.pathSeparator}dart.exe';
      if (File(candidate).existsSync()) {
        _cachedDartPath = candidate;
        return candidate;
      }
    }

    // フォールバック: PATH 上の dart に期待
    _cachedDartPath = 'dart';
    return 'dart';
  }
}
