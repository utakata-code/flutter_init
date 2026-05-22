import 'package:flutter/material.dart';
import '../../../../../core/theme/studio_theme.dart';
import '../../../3_application/1_states/command_runner_state.dart';
import '../1_atoms/command_button_atom.dart';
import '../2_molecules/command_output_molecule.dart';

/// utakata CLI コマンド群のパネル定義
class _CommandDef {
  final String label;
  final IconData icon;
  final String description;
  final List<String> args;
  const _CommandDef(this.label, this.icon, this.description, this.args);
}

const _commands = [
  _CommandDef('validate', Icons.rule, '命名規則・構造のバリデーション', ['validate']),
  _CommandDef('diff', Icons.compare, '計画 vs 実体の差分表示', ['diff']),
  _CommandDef('check', Icons.health_and_safety, 'ヘルスチェック (diff + exit code)', ['check']),
  _CommandDef('scan', Icons.radar, 'ディレクトリ構造のスキャン', ['scan']),
  _CommandDef('status', Icons.dashboard, 'プロジェクト総合ステータス', ['status']),
];

/// コマンドボタン群 + 出力パネルの統合 Organism
///
/// Riverpod 非依存。状態とコールバックは引数で受け取る。
class CommandPanelOrganism extends StatelessWidget {
  final CommandRunnerState state;
  final void Function(List<String> args) onExecute;

  const CommandPanelOrganism({
    super.key,
    required this.state,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = state.maybeWhen(
      running: (_, _) => true,
      orElse: () => false,
    );
    final outputLines = state.when(
      idle: () => <String>[],
      running: (_, lines) => lines,
      completed: (result) => result.output.split('\n'),
      error: (message) => ['❌ $message'],
    );
    final exitCode = state.mapOrNull(
      completed: (s) => s.result.exitCode,
    );

    return Container(
      color: StudioTheme.editorBg,
      child: Column(
        children: [
          // ── ヘッダー ──
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: StudioTheme.sidebarBg,
              border:
                  Border(bottom: BorderSide(color: StudioTheme.borderColor)),
            ),
            child: Row(children: [
              const Icon(Icons.terminal,
                  size: 16, color: StudioTheme.accentGreen),
              const SizedBox(width: 8),
              Text('COMMAND RUNNER',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: StudioTheme.accentGreen)),
            ]),
          ),
          Expanded(
            child: Row(
              children: [
                // ── 左: コマンドボタン群 ──
                SizedBox(
                  width: 280,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final cmd in _commands) ...[
                        CommandButtonAtom(
                          label: 'utakata ${cmd.label}',
                          icon: cmd.icon,
                          description: cmd.description,
                          isRunning: isRunning,
                          onPressed: () => onExecute(cmd.args),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // ── 右: 出力パネル ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CommandOutputMolecule(
                      outputLines: outputLines,
                      isRunning: isRunning,
                      exitCode: exitCode,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
