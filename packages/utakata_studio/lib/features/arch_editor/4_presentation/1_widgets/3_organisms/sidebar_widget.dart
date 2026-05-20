import 'package:flutter/material.dart';

import '../../../../../core/theme/studio_theme.dart';
import '../../../../validation/3_application/3_notifiers/yaml_validation_notifier.dart';

/// 左サイドバー (Organism)
///
/// プロジェクト情報、アーキテクチャ選択、バリデーションステータスを表示する。
class SidebarWidget extends StatelessWidget {
  final YamlValidationState state;

  const SidebarWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: StudioTheme.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ヘッダー ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: StudioTheme.accentCyan.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: StudioTheme.accentCyan.withOpacity(0.15),
                    ),
                  ),
                  child: const Icon(Icons.blur_on_sharp,
                      color: StudioTheme.accentCyan, size: 26),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UTAKATA',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            letterSpacing: 2.5,
                          ),
                    ),
                    Text(
                      'architecture studio',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: StudioTheme.accentCyan.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // ── コンテンツ ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              children: [
                const _SectionHeader('ACTIVE ARCHITECTURE'),
                const _NavItem(
                  icon: Icons.lan_outlined,
                  label: 'clean_architecture',
                  selected: true,
                ),
                const SizedBox(height: 28),
                const _SectionHeader('VALIDATION'),
                _StatusCard(state: state),
                if (state.isValid) ...[
                  const SizedBox(height: 20),
                  const _SectionHeader('STRUCTURE'),
                  _InfoRow('レイヤー数', '${state.result?.layers.length ?? 0}'),
                  _InfoRow('ディレクトリ総数', '${state.result?.totalDirs ?? 0}'),
                  _InfoRow('命名規則', '${state.result?.namingRules.length ?? 0}'),
                  _InfoRow('コアモジュール', '${state.result?.coreModules.length ?? 0}'),
                  _InfoRow('ガイド', '${state.result?.guides.length ?? 0}'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10, left: 4),
      child: Text(title, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? StudioTheme.surfaceBg : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: selected ? Border.all(color: StudioTheme.borderLight) : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon,
            color: selected ? StudioTheme.accentCyan : StudioTheme.textMuted,
            size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? StudioTheme.textPrimary : StudioTheme.textMuted,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final YamlValidationState state;
  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final valid = state.isValid;
    final statusColor = valid ? StudioTheme.accentGreen : StudioTheme.accentRed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                valid ? Icons.check_circle : Icons.error,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                valid ? 'YAML: 有効' : 'YAML: エラー',
                style: TextStyle(
                  color: valid ? StudioTheme.textPrimary : statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (valid)
            Text(
              '${state.result?.layers.length ?? 0} 個のレイヤーが正常に定義されています。',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  state.errorMessage ?? '原因不明のエラー',
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    color: Color(0xFFFF8297),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: StudioTheme.surfaceBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: StudioTheme.accentCyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
