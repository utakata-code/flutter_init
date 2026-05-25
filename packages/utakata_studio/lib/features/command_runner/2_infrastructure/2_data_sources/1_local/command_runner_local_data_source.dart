import '../../../../../core/cli_bridge/cli_bridge.dart';
import '../../../../../core/cli_bridge/cli_result.dart';

/// CLI ブリッジのローカルデータソース
///
/// CliBridge を直接ラップし、Infrastructure 層から利用する。
class CommandRunnerLocalDataSource {
  final CliBridge _bridge;
  const CommandRunnerLocalDataSource(this._bridge);

  /// コマンドを同期実行
  Future<CliResult> run(List<String> args) => _bridge.run(args);

  /// コマンドをストリーミング実行
  Stream<CliStreamEvent> runStream(List<String> args) =>
      _bridge.runStream(args);
}
