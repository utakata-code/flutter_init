import 'package:flutter/material.dart';
import '../../../../../core/theme/studio_theme.dart';

/// バリデーション結果のステータス表示
class ValidationStatusMolecule extends StatelessWidget {
  final bool isValid;
  final String? errorMessage;
  final int layerCount;
  final int namingRuleCount;

  const ValidationStatusMolecule({
    super.key,
    required this.isValid,
    this.errorMessage,
    this.layerCount = 0,
    this.namingRuleCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? StudioTheme.accentGreen.withValues(alpha: 0.08)
            : StudioTheme.accentRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid
              ? StudioTheme.accentGreen.withValues(alpha: 0.25)
              : StudioTheme.accentRed.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle_outline : Icons.error_outline,
                size: 16,
                color: isValid ? StudioTheme.accentGreen : StudioTheme.accentRed,
              ),
              const SizedBox(width: 8),
              Text(
                isValid ? 'VALID' : 'ERROR',
                style: TextStyle(
                  color: isValid ? StudioTheme.accentGreen : StudioTheme.accentRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          if (!isValid && errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: StudioTheme.accentRed,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
