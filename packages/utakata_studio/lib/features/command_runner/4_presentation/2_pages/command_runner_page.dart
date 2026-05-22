import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/theme/studio_theme.dart';
import '../../3_application/3_notifiers/command_runner_notifier.dart';
import '../1_widgets/3_organisms/command_panel_organism.dart';

/// Health タブのメインページ
///
/// 状態の監視とイベントディスパッチを担当。
class CommandRunnerPage extends HookConsumerWidget {
  const CommandRunnerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commandRunnerNotifierProvider);

    return Scaffold(
      backgroundColor: StudioTheme.darkBg,
      body: CommandPanelOrganism(
        state: state,
        onExecute: (args) {
          ref.read(commandRunnerNotifierProvider.notifier).execute(args);
        },
      ),
    );
  }
}
