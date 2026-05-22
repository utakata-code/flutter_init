import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/settings/3_application/1_states/settings_state.dart';
import '../../features/settings/3_application/3_notifiers/settings_notifier.dart';
import 'cli_bridge.dart';

/// CliBridge の Provider
///
/// Settings から CLI パスとプロジェクトルートを読み取り、
/// 適切に設定された CliBridge インスタンスを返す。
final cliBridgeProvider = Provider<CliBridge>((ref) {
  final settingsState = ref.watch(settingsNotifierProvider);

  final cliPath = settingsState.mapOrNull(
        loaded: (s) => s.settings.utakataCliPath,
      ) ??
      'utakata';

  final workingDirectory = settingsState.mapOrNull(
    loaded: (s) => s.settings.projectRoot,
  );

  return CliBridge(
    cliPath: cliPath,
    workingDirectory: workingDirectory,
  );
});
