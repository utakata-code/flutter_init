import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/theme/studio_theme.dart';
import '../../../settings/3_application/1_states/settings_state.dart';
import '../../../settings/3_application/3_notifiers/settings_notifier.dart';

/// 仕様書ビューア — application_specification.md のリッチ表示
///
/// プロジェクトルート配下の `AI/specs/application_specification.md` を
/// flutter_markdown でレンダリングする。
class SpecViewerPage extends HookConsumerWidget {
  const SpecViewerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MarkdownViewerPage(
      title: 'APPLICATION SPECIFICATION',
      icon: Icons.description_outlined,
      accentColor: StudioTheme.accentGreen,
      relativePath: 'AI/specs/application_specification.md',
      emptyMessage: '仕様書が見つかりません',
      emptySubMessage: 'AI/specs/application_specification.md を\nプロジェクトに追加してください',
    );
  }
}

/// 構造計画書ビューア — structure_plan.md のリッチ表示
///
/// プロジェクトルート配下の `AI/specs/structure_plan.md` を
/// flutter_markdown でレンダリングする。
class PlanViewerPage extends HookConsumerWidget {
  const PlanViewerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MarkdownViewerPage(
      title: 'STRUCTURE PLAN',
      icon: Icons.account_tree_outlined,
      accentColor: StudioTheme.accentYellow,
      relativePath: 'AI/specs/structure_plan.md',
      emptyMessage: '構造計画書が見つかりません',
      emptySubMessage: 'AI/specs/structure_plan.md を\nプロジェクトに追加してください',
    );
  }
}

/// 汎用 Markdown ビューアページ
///
/// [relativePath] で指定されたファイルをプロジェクトルートから読み込み、
/// Markdown としてレンダリングする。
class _MarkdownViewerPage extends ConsumerStatefulWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final String relativePath;
  final String emptyMessage;
  final String emptySubMessage;

  const _MarkdownViewerPage({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.relativePath,
    required this.emptyMessage,
    required this.emptySubMessage,
  });

  @override
  ConsumerState<_MarkdownViewerPage> createState() =>
      _MarkdownViewerPageState();
}

class _MarkdownViewerPageState extends ConsumerState<_MarkdownViewerPage> {
  String? _content;
  String? _errorMessage;
  bool _isLoading = true;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void didUpdateWidget(covariant _MarkdownViewerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.relativePath != widget.relativePath) {
      _loadFile();
    }
  }

  void _loadFile() {
    final settingsState = ref.read(settingsNotifierProvider);
    final projectRoot = settingsState.mapOrNull(
      loaded: (s) => s.settings.projectRoot,
    );

    if (projectRoot == null || projectRoot.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'プロジェクトルートが設定されていません';
      });
      return;
    }

    final path = '$projectRoot/${widget.relativePath}';
    _filePath = path;

    final file = File(path);
    if (!file.existsSync()) {
      setState(() {
        _isLoading = false;
        _content = null;
      });
      return;
    }

    try {
      final content = file.readAsStringSync();
      setState(() {
        _isLoading = false;
        _content = content;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ファイルの読み込みに失敗しました: $e';
      });
    }
  }

  void _reload() {
    setState(() {
      _isLoading = true;
      _content = null;
      _errorMessage = null;
    });
    _loadFile();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: StudioTheme.editorBg,
      child: Column(
        children: [
          // ── ヘッダー ──
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: StudioTheme.sidebarBg,
              border: Border(
                bottom: BorderSide(color: StudioTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 16, color: widget.accentColor),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: widget.accentColor,
                        fontSize: 11,
                      ),
                ),
                const Spacer(),
                if (_filePath != null)
                  Flexible(
                    child: Text(
                      widget.relativePath,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 10,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh, size: 16),
                  color: StudioTheme.textMuted,
                  tooltip: '再読み込み',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),

          // ── コンテンツ ──
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: widget.accentColor),
                  )
                : _errorMessage != null
                    ? _buildError()
                    : _content == null
                        ? _buildEmpty()
                        : _buildMarkdown(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdown() {
    return Markdown(
      data: _content!,
      padding: const EdgeInsets.all(24),
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(
          color: StudioTheme.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.4,
        ),
        h2: const TextStyle(
          color: StudioTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        h3: TextStyle(
          color: widget.accentColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        h4: const TextStyle(
          color: StudioTheme.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        p: const TextStyle(
          color: StudioTheme.textSecondary,
          fontSize: 13,
          height: 1.7,
        ),
        listBullet: const TextStyle(
          color: StudioTheme.textMuted,
          fontSize: 13,
        ),
        code: TextStyle(
          color: widget.accentColor,
          backgroundColor: StudioTheme.surfaceBg,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: StudioTheme.surfaceBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: StudioTheme.borderColor),
        ),
        codeblockPadding: const EdgeInsets.all(16),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: widget.accentColor.withValues(alpha: 0.4),
              width: 3,
            ),
          ),
        ),
        blockquotePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tableBorder: TableBorder.all(
          color: StudioTheme.borderColor,
          width: 1,
        ),
        tableHead: const TextStyle(
          color: StudioTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tableBody: const TextStyle(
          color: StudioTheme.textSecondary,
          fontSize: 12,
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: StudioTheme.borderColor,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 48, color: StudioTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            widget.emptyMessage,
            style: const TextStyle(
              color: StudioTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.emptySubMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: StudioTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              size: 40, color: StudioTheme.accentRed),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: StudioTheme.accentRed,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('再試行'),
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.accentColor,
              side: const BorderSide(color: StudioTheme.borderColor),
            ),
          ),
        ],
      ),
    );
  }
}
