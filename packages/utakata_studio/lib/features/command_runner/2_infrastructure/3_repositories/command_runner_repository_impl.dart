import 'dart:async';
import '../../../../core/cli_bridge/cli_result.dart';
import '../../1_domain/1_entities/command_result_entity.dart';
import '../../1_domain/2_repositories/command_runner_repository.dart';
import '../1_models/command_runner_model.dart';
import '../2_data_sources/1_local/command_runner_local_data_source.dart';

/// CommandRunnerRepository の実装
class CommandRunnerRepositoryImpl implements CommandRunnerRepository {
  final CommandRunnerLocalDataSource _dataSource;
  const CommandRunnerRepositoryImpl(this._dataSource);

  @override
  Future<CommandResultEntity> execute(List<String> args) async {
    final result = await _dataSource.run(args);
    return CommandRunnerModel.toEntity(result);
  }

  @override
  Stream<String> executeStream(List<String> args) {
    final controller = StreamController<String>();

    _dataSource.runStream(args).listen(
      (event) {
        switch (event) {
          case CliStdoutEvent(:final line):
            controller.add(line);
          case CliStderrEvent(:final line):
            controller.add('[stderr] $line');
          case CliDoneEvent():
            controller.close();
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    return controller.stream;
  }
}
