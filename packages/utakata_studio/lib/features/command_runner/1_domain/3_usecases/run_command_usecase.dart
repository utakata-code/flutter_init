import '../1_entities/command_result_entity.dart';
import '../2_repositories/command_runner_repository.dart';

/// CLI コマンドを実行するユースケース
class RunCommandUsecase {
  final CommandRunnerRepository _repository;
  const RunCommandUsecase(this._repository);

  /// コマンドを実行し結果を返す
  Future<CommandResultEntity> call(List<String> args) =>
      _repository.execute(args);

  /// ストリーミング実行
  Stream<String> stream(List<String> args) =>
      _repository.executeStream(args);
}
