import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
        loaded: (settings) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
        ),
      ),
    );
  }
}
