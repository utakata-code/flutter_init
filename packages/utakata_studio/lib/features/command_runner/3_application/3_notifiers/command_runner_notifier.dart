import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../1_domain/3_usecases/run_command_usecase.dart';
import '../1_states/command_runner_state.dart';
import '../2_providers/command_runner_providers.dart';

/// CLI コマンド実行の状態管理 Notifier
class CommandRunnerNotifier extends StateNotifier<CommandRunnerState> {
  final RunCommandUsecase _usecase;
  StreamSubscription<String>? _streamSub;

  CommandRunnerNotifier(this._usecase)
      : super(const CommandRunnerState.idle());

  /// コマンドを実行（同期: 完了まで待つ）
  Future<void> execute(List<String> args) async {
    final commandStr = args.join(' ');
    state = CommandRunnerState.running(command: commandStr, outputLines: []);

    try {
      final result = await _usecase(args);
      state = CommandRunnerState.completed(result: result);
    } catch (e) {
      state = CommandRunnerState.error(message: e.toString());
    }
  }

  /// コマンドをストリーミング実行（リアルタイム出力）
  Future<void> executeStream(List<String> args) async {
    final commandStr = args.join(' ');
    state = CommandRunnerState.running(command: commandStr, outputLines: []);

    _streamSub?.cancel();
    final lines = <String>[];

    _streamSub = _usecase.stream(args).listen(
      (line) {
        lines.add(line);
        state = CommandRunnerState.running(
          command: commandStr,
          outputLines: List.unmodifiable(lines),
        );
      },
      onError: (e) {
        state = CommandRunnerState.error(message: e.toString());
      },
      onDone: () {
        // ストリーム完了後、最終結果で completed 状態に遷移
        // (ストリーミング実行では result は null なので running の最終出力を保持)
        // 完了通知のために idle ではなく completed に遷移
        state = CommandRunnerState.running(
          command: commandStr,
          outputLines: List.unmodifiable(lines),
        );
      },
    );
  }

  /// 状態をリセット
  void reset() {
    _streamSub?.cancel();
    state = const CommandRunnerState.idle();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}

final commandRunnerNotifierProvider =
    StateNotifierProvider<CommandRunnerNotifier, CommandRunnerState>(
  (ref) => CommandRunnerNotifier(ref.read(runCommandUsecaseProvider)),
);
