import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:utakata/utakata.dart';
import '../../../../../core/theme/studio_theme.dart';

/// ガイドカード（クリックで Markdown レンダリング表示）
class GuideCardMolecule extends StatelessWidget {
  final GuideEntity guide;
  const GuideCardMolecule({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showGuideDetail(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: StudioTheme.surfaceBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: StudioTheme.borderColor),
          ),
          child:
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guide.title,
                        style: const TextStyle(
                            color: StudioTheme.accentGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(guide.layerPath,
                        style: const TextStyle(
                            color: StudioTheme.textSecondary,
                            fontSize: 11,
                            fontFamily: 'monospace')),
                  ]),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: StudioTheme.textMuted),
          ]),
        ),
      ),
    );
  }

  void _showGuideDetail(BuildContext context) {
    // ガイドの Markdown をレンダリング
    final markdown = guide.render(null);

    showDialog(
      context: context,
      builder: (context) => _GuideDetailDialog(
        guide: guide,
        markdown: markdown,
      ),
    );
  }
}

/// ガイド詳細ダイアログ（Markdown レンダリング）
class _GuideDetailDialog extends StatelessWidget {
  final GuideEntity guide;
  final String markdown;

  const _GuideDetailDialog({
    required this.guide,
    required this.markdown,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: StudioTheme.editorBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: StudioTheme.borderColor),
      ),
      child: SizedBox(
        width: 700,
        height: 600,
        child: Column(
          children: [
            // ── ヘッダー ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: StudioTheme.sidebarBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                    bottom: BorderSide(color: StudioTheme.borderColor)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book,
                      size: 18, color: StudioTheme.accentGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(guide.title,
                            style: const TextStyle(
                                color: StudioTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(guide.layerPath,
                            style: const TextStyle(
                                color: StudioTheme.textMuted,
                                fontSize: 11,
                                fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                    color: StudioTheme.textMuted,
                  ),
                ],
              ),
            ),
            // ── Markdown コンテンツ ──
            Expanded(
              child: Markdown(
                data: markdown,
                selectable: true,
                padding: const EdgeInsets.all(20),
                styleSheet: _buildMarkdownStyle(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyle(BuildContext context) {
    return MarkdownStyleSheet(
      // 見出し
      h1: const TextStyle(
          color: StudioTheme.accentCyan,
          fontSize: 20,
          fontWeight: FontWeight.w800),
      h2: const TextStyle(
          color: StudioTheme.accentPurple,
          fontSize: 16,
          fontWeight: FontWeight.w700),
      h3: const TextStyle(
          color: StudioTheme.accentYellow,
          fontSize: 14,
          fontWeight: FontWeight.w600),
      // テキスト
      p: const TextStyle(
          color: StudioTheme.textSecondary, fontSize: 13, height: 1.6),
      // リスト
      listBullet: const TextStyle(
          color: StudioTheme.accentGreen, fontSize: 13),
      // コードブロック
      code: TextStyle(
        color: StudioTheme.accentCyan,
        backgroundColor: StudioTheme.darkBg,
        fontFamily: 'monospace',
        fontSize: 12,
      ),
      codeblockDecoration: BoxDecoration(
        color: StudioTheme.darkBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: StudioTheme.borderColor),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      // 区切り線
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: StudioTheme.borderColor),
        ),
      ),
      // 強調
      strong: const TextStyle(
          color: StudioTheme.textPrimary, fontWeight: FontWeight.w700),
      em: const TextStyle(
          color: StudioTheme.textSecondary, fontStyle: FontStyle.italic),
      // ブロック引用
      blockquoteDecoration: BoxDecoration(
        color: StudioTheme.accentCyan.withValues(alpha: 0.05),
        border: const Border(
          left: BorderSide(color: StudioTheme.accentCyan, width: 3),
        ),
      ),
    );
  }
}
