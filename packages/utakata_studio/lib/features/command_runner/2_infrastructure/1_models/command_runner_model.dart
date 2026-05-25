import '../../1_domain/1_entities/command_result_entity.dart';
import '../../../../core/cli_bridge/cli_result.dart';

/// CliResult → CommandResultEntity への変換モデル
class CommandRunnerModel {
  const CommandRunnerModel._();

  /// Core の CliResult をドメインエンティティに変換
  static CommandResultEntity toEntity(CliResult result) {
    return CommandResultEntity(
      command: result.command,
      arguments: result.arguments,
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr,
      duration: result.duration,
    );
  }
}
