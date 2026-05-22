import 'package:freezed_annotation/freezed_annotation.dart';
import '../../1_domain/1_entities/command_result_entity.dart';

part 'command_runner_state.freezed.dart';

/// CLI コマンド実行の状態
@freezed
sealed class CommandRunnerState with _$CommandRunnerState {
  /// 待機中
  const factory CommandRunnerState.idle() = _Idle;

  /// 実行中（リアルタイム出力を蓄積）
  const factory CommandRunnerState.running({
    required String command,
    required List<String> outputLines,
  }) = _Running;

  /// 完了
  const factory CommandRunnerState.completed({
    required CommandResultEntity result,
  }) = _Completed;

  /// エラー
  const factory CommandRunnerState.error({
    required String message,
  }) = _Error;
}
