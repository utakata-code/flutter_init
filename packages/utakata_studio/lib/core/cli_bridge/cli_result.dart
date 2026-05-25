/// CLI コマンドの実行結果
class CliResult {
  /// 実行したコマンド
  final String command;

  /// サブコマンドと引数
  final List<String> arguments;

  /// 終了コード
  final int exitCode;

  /// 標準出力
  final String stdout;

  /// 標準エラー出力
  final String stderr;

  /// 実行時間
  final Duration duration;

  const CliResult({
    required this.command,
    required this.arguments,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.duration,
  });

  /// 成功したかどうか
  bool get isSuccess => exitCode == 0;

  /// 出力全体（stdout + stderr）
  String get output => '$stdout$stderr'.trim();
}

/// CLI 実行中のストリーミング出力イベント
sealed class CliStreamEvent {
  const CliStreamEvent();
}

/// 標準出力行
class CliStdoutEvent extends CliStreamEvent {
  final String line;
  const CliStdoutEvent(this.line);
}

/// 標準エラー出力行
class CliStderrEvent extends CliStreamEvent {
  final String line;
  const CliStderrEvent(this.line);
}

/// 実行完了イベント
class CliDoneEvent extends CliStreamEvent {
  final CliResult result;
  const CliDoneEvent(this.result);
}
