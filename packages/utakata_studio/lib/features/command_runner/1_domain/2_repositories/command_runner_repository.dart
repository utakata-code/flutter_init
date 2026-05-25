import '../1_entities/command_result_entity.dart';

/// CLI コマンド実行のリポジトリインターフェース
abstract class CommandRunnerRepository {
  /// コマンドを実行し結果を返す
  Future<CommandResultEntity> execute(List<String> args);

  /// コマンドをストリーミング実行し、出力行をリアルタイムに返す
  Stream<String> executeStream(List<String> args);
}
