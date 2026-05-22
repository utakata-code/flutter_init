import 'package:flutter/material.dart';
import '../../../../../core/theme/studio_theme.dart';

/// ステータスバッジ（有効/エラー表示）
class StatusBadgeAtom extends StatelessWidget {
  final bool isValid;
  final String? errorMessage;

  const StatusBadgeAtom({super.key, required this.isValid, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isValid
            ? StudioTheme.accentGreen.withValues(alpha: 0.12)
            : StudioTheme.accentRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isValid
                ? StudioTheme.accentGreen.withValues(alpha: 0.3)
                : StudioTheme.accentRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle_outline : Icons.error_outline,
            size: 14,
            color: isValid ? StudioTheme.accentGreen : StudioTheme.accentRed,
          ),
          const SizedBox(width: 6),
          Text(
            isValid ? 'VALID' : 'ERROR',
            style: TextStyle(
              color: isValid ? StudioTheme.accentGreen : StudioTheme.accentRed,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
