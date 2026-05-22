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

    // cliPath が "dart run ..." の形式かチェック
    final parts = cliPath.split(' ');
    final executable = parts.first;
    final baseArgs = [...parts.skip(1), ...args];

    try {
      final process = await Process.run(
        executable,
        baseArgs,
        workingDirectory: workingDirectory,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      stopwatch.stop();

      return CliResult(
        command: executable,
        arguments: baseArgs,
        exitCode: process.exitCode,
        stdout: process.stdout as String,
        stderr: process.stderr as String,
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

    final parts = cliPath.split(' ');
    final executable = parts.first;
    final baseArgs = [...parts.skip(1), ...args];

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    try {
      final process = await Process.start(
        executable,
        baseArgs,
        workingDirectory: workingDirectory,
      );

      // stdout ストリーム
      await for (final event in _mergeStreams(
        process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .map((line) {
          stdoutBuffer.writeln(line);
          return CliStdoutEvent(line) as CliStreamEvent;
        }),
        process.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .map((line) {
          stderrBuffer.writeln(line);
          return CliStderrEvent(line) as CliStreamEvent;
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
}
