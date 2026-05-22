import 'package:flutter/material.dart';
import '../../../../../core/theme/studio_theme.dart';

/// CLI コマンド実行ボタン
class CommandButtonAtom extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final bool isRunning;
  final VoidCallback? onPressed;

  const CommandButtonAtom({
    super.key,
    required this.label,
    required this.icon,
    required this.description,
    this.isRunning = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isRunning ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: StudioTheme.textPrimary,
          side: const BorderSide(color: StudioTheme.borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: StudioTheme.accentCyan),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 11, color: StudioTheme.textMuted)),
                ],
              ),
            ),
            if (isRunning)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: StudioTheme.accentCyan),
              ),
          ],
        ),
      ),
    );
  }
}
