import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/cli_bridge/cli_bridge_provider.dart';
import '../../../../core/theme/studio_theme.dart';
import '../../3_application/1_states/settings_state.dart';
import '../../3_application/3_notifiers/settings_notifier.dart';

/// 設定画面
class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsNotifierProvider);

    return Scaffold(
      backgroundColor: StudioTheme.darkBg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: StudioTheme.sidebarBg,
      ),
      body: state.when(
        initial: () => const SizedBox.shrink(),
        loading: () => const Center(
          child: CircularProgressIndicator(color: StudioTheme.accentCyan),
        ),
        error: (message) => Center(
          child: Text('Error: $message',
              style: const TextStyle(color: StudioTheme.accentRed)),
        ),
        loaded: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── プロジェクトルート ──
              Text('Project Root',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: StudioTheme.sidebarBg,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: StudioTheme.borderColor),
                      ),
                      child: Text(
                        settings.projectRoot ?? '(未設定)',
                        style: TextStyle(
                          color: settings.projectRoot != null
                              ? StudioTheme.textPrimary
                              : StudioTheme.textMuted,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _selectProjectRoot(context, ref),
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: const Text('変更'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StudioTheme.accentCyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── CLI パス ──
              Text('utakata CLI Path',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: settings.utakataCliPath,
                decoration: InputDecoration(
                  hintText: 'utakata (default: PATH上のutakata)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onFieldSubmitted: (value) {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .updateCliPath(value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'フルパスで指定: dart run /path/to/utakata_code/bin/utakata.dart',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              // ── CLI 接続テスト ──
              Text('CLI 接続テスト',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _testCliConnection(context, ref),
                icon: const Icon(Icons.terminal, size: 16),
                label: const Text('utakata --version を実行'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: StudioTheme.textSecondary,
                  side: const BorderSide(color: StudioTheme.borderColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// プロジェクトルートを変更
  Future<void> _selectProjectRoot(
      BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.getDirectoryPath(
      dialogTitle: 'utakata プロジェクトフォルダを選択',
    );
    if (result == null) return;
    await ref
        .read(settingsNotifierProvider.notifier)
        .updateProjectRoot(result);
  }

  /// CLI 接続テスト
  Future<void> _testCliConnection(
      BuildContext context, WidgetRef ref) async {
    final bridge = ref.read(cliBridgeProvider);
    final result = await bridge.run(['--version']);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? '✅ 接続OK: ${result.stdout.trim()}'
              : '❌ 接続失敗: ${result.stderr.trim()}',
        ),
        backgroundColor:
            result.isSuccess ? StudioTheme.accentGreen : StudioTheme.accentRed,
      ),
    );
  }
}
