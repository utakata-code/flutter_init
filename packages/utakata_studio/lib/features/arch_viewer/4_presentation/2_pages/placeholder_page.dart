import 'package:flutter/material.dart';
import '../../../../core/theme/studio_theme.dart';

/// プレースホルダーページ（未実装機能用）
class PlaceholderPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: StudioTheme.editorBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: StudioTheme.textMuted),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: StudioTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description,
                style: const TextStyle(
                    color: StudioTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: StudioTheme.accentPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Coming Soon',
                  style: TextStyle(
                      color: StudioTheme.accentPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
