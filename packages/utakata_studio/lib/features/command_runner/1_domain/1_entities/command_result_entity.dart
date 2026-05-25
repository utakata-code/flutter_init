/// CLI コマンドの実行結果エンティティ
///
/// ドメイン層のため外部依存なし。
class CommandResultEntity {
  /// 実行したコマンド全体
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

  const CommandResultEntity({
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
