import 'package:flutter/material.dart';
import '../../../../../core/theme/studio_theme.dart';

/// セクションヘッダー（LAYERS, NAMING_RULES 等のタイトル）
class SectionHeaderAtom extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const SectionHeaderAtom({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    this.color = StudioTheme.accentCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
