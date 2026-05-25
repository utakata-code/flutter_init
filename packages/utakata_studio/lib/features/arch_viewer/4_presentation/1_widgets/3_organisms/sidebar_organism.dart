import 'package:flutter/material.dart';
import '../../../../../core/theme/studio_theme.dart';
import '../../../../validation/1_domain/1_entities/validation_result_entity.dart';
import '../../../../validation/3_application/1_states/validation_state.dart';
import '../1_atoms/status_badge_atom.dart';

/// サイドバーのコールバック定義
typedef SidebarCallbacks = ({
  VoidCallback onSettingsTap,
  VoidCallback onHealthTap,
  VoidCallback onHomeTap,
  VoidCallback onFeaturesTap,
  VoidCallback onDashboardTap,
  VoidCallback onOpenProject,
});

/// 左ペイン: サイドバー
///
/// Riverpod に依存せず、状態とコールバックは引数として受け取る。
class SidebarOrganism extends StatelessWidget {
  final ValidationState validationState;
  final SidebarCallbacks callbacks;
  final String activeRoute;

  const SidebarOrganism({
    super.key,
    required this.validationState,
    required this.callbacks,
    this.activeRoute = '/',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: StudioTheme.sidebarBg,
      child: Column(children: [
        // ── ロゴ ──
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: StudioTheme.borderColor))),
          child: Row(children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [StudioTheme.accentCyan, StudioTheme.accentPurple]),
                borderRadius: BorderRadius.circular(6),
              ),
              child:
                  const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('utakata studio',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
          ]),
        ),
        // ── プロジェクトを開く ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: callbacks.onOpenProject,
              icon: const Icon(Icons.folder_open, size: 16),
              label: const Text('Open Project'),
              style: OutlinedButton.styleFrom(
                foregroundColor: StudioTheme.textSecondary,
                side: const BorderSide(color: StudioTheme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
        // ── ステータス ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: validationState.when(
            initial: () => const SizedBox.shrink(),
            loading: (_) => const Center(
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))),
            error: (message, _) =>
                StatusBadgeAtom(isValid: false, errorMessage: message),
            loaded: (result, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadgeAtom(
                    isValid: result.isValid,
                    errorMessage: result.errorMessage),
                if (!result.isValid && result.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: StudioTheme.accentRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(result.errorMessage!,
                        style: const TextStyle(
                            color: StudioTheme.accentRed,
                            fontSize: 11,
                            fontFamily: 'monospace'),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
                if (result.isValid) ...[
                  const SizedBox(height: 16),
                  _buildStats(context, result),
                ],
              ],
            ),
          ),
        ),
        const Divider(),
        // ── ナビゲーション ──
        _NavItem(
            icon: Icons.architecture,
            label: 'Architecture',
            isActive: activeRoute == '/',
            onTap: callbacks.onHomeTap),
        _NavItem(
            icon: Icons.featured_play_list_outlined,
            label: 'Features',
            isActive: activeRoute == '/features',
            onTap: callbacks.onFeaturesTap),
        _NavItem(
            icon: Icons.health_and_safety_outlined,
            label: 'Health',
            isActive: activeRoute == '/health',
            onTap: callbacks.onHealthTap),
        _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            isActive: activeRoute == '/dashboard',
            onTap: callbacks.onDashboardTap),
        const Spacer(),
        const Divider(),
        _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isActive: activeRoute == '/settings',
            onTap: callbacks.onSettingsTap),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildStats(BuildContext context, ValidationResultEntity result) {
    return Column(children: [
      _StatRow('Layers', '${result.layers.length}', StudioTheme.accentCyan),
      _StatRow('Naming Rules', '${result.namingRules.length}',
          StudioTheme.accentYellow),
      _StatRow('Core Modules', '${result.coreModules.length}',
          StudioTheme.accentPurple),
      _StatRow('Guides', '${result.guides.length}', StudioTheme.accentGreen),
      _StatRow(
          'Total Dirs', '${result.totalDirs}', StudioTheme.textSecondary),
    ]);
  }
}

// ignore: unused_element_parameter
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final String? badge;
  final VoidCallback? onTap;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.isActive,
      // ignore: unused_element_parameter
      this.badge,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color:
              isActive ? StudioTheme.accentCyan.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          const SizedBox(width: 12),
          Icon(icon,
              size: 16,
              color:
                  isActive ? StudioTheme.accentCyan : StudioTheme.textMuted),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: isActive
                      ? StudioTheme.textPrimary
                      : StudioTheme.textMuted,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
          if (badge != null) ...[
            const Spacer(),
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: StudioTheme.borderColor,
                  borderRadius: BorderRadius.circular(4)),
              child: Text(badge!,
                  style: const TextStyle(
                      color: StudioTheme.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: StudioTheme.textSecondary, fontSize: 12)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
