import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/cli_bridge/cli_bridge_provider.dart';
import '../../../../core/routing/path/app_paths.dart';
import '../../../../core/theme/studio_theme.dart';

/// アーキテクチャ管理画面 — `utakata arch list` の GUI 版
///
/// 組み込みアーキテクチャテンプレートの一覧をカード形式で表示する。
/// 各カードを選択すると、`utakata arch show <id>` の結果を詳細ビューで表示する。
class ArchitecturesPage extends HookConsumerWidget {
  const ArchitecturesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: StudioTheme.darkBg,
      body: Column(
        children: [
          // ── ヘッダー ──
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: StudioTheme.sidebarBg,
              border: Border(
                bottom: BorderSide(color: StudioTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go(AppPaths.launcher),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  color: StudioTheme.textSecondary,
                  tooltip: 'ランチャーに戻る',
                ),
                const SizedBox(width: 8),
                const Icon(Icons.architecture_outlined,
                    size: 18, color: StudioTheme.accentPurple),
                const SizedBox(width: 10),
                Text(
                  'ARCHITECTURE MANAGEMENT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: StudioTheme.accentPurple,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                ),
              ],
            ),
          ),

          // ── コンテンツ ──
          Expanded(
            child: _ArchitectureListBody(),
          ),
        ],
      ),
    );
  }
}

/// アーキテクチャ一覧のボディ
class _ArchitectureListBody extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ArchitectureListBody> createState() =>
      _ArchitectureListBodyState();
}

class _ArchitectureListBodyState extends ConsumerState<_ArchitectureListBody> {
  bool _isLoading = true;
  String? _errorMessage;
  List<_ArchInfo> _architectures = [];
  String? _selectedId;
  String _detailOutput = '';
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadArchitectures();
  }

  Future<void> _loadArchitectures() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bridge = ref.read(cliBridgeProvider);
      final result = await bridge.run(['arch', 'list']);

      if (result.exitCode != 0) {
        setState(() {
          _isLoading = false;
          _errorMessage = result.stderr.isNotEmpty
              ? result.stderr
              : 'arch list failed (exit code: ${result.exitCode})';
        });
        return;
      }

      // stdout から一覧をパース
      final lines = result.stdout
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      final archs = <_ArchInfo>[];
      for (final line in lines) {
        // 形式: "- clean_architecture" or "clean_architecture" 等
        final cleaned = line.replaceFirst(RegExp(r'^[-*•]\s*'), '').trim();
        if (cleaned.isNotEmpty && !cleaned.startsWith('Available')) {
          archs.add(_ArchInfo(
            id: cleaned,
            name: cleaned.replaceAll('_', ' '),
          ));
        }
      }

      setState(() {
        _isLoading = false;
        _architectures = archs;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'エラー: $e';
      });
    }
  }

  Future<void> _showDetail(String id) async {
    setState(() {
      _selectedId = id;
      _isLoadingDetail = true;
      _detailOutput = '';
    });

    try {
      final bridge = ref.read(cliBridgeProvider);
      final result = await bridge.run(['arch', 'show', id]);

      setState(() {
        _isLoadingDetail = false;
        _detailOutput = result.exitCode == 0
            ? result.stdout
            : 'エラー: ${result.stderr}';
      });
    } catch (e) {
      setState(() {
        _isLoadingDetail = false;
        _detailOutput = 'エラー: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: StudioTheme.accentPurple),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 40, color: StudioTheme.accentYellow),
            const SizedBox(height: 16),
            Text(
              'アーキテクチャ一覧を取得できませんでした',
              style: TextStyle(color: StudioTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: StudioTheme.surfaceBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: StudioTheme.borderColor),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: StudioTheme.textMuted,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadArchitectures,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('再試行'),
              style: OutlinedButton.styleFrom(
                foregroundColor: StudioTheme.accentPurple,
                side: const BorderSide(color: StudioTheme.borderColor),
              ),
            ),
          ],
        ),
      );
    }

    if (_architectures.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 48, color: StudioTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'アーキテクチャが見つかりません',
              style: TextStyle(color: StudioTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // 2ペイン: 左に一覧カード、右に詳細
    return Row(
      children: [
        // ── 左ペイン: カード一覧 ──
        SizedBox(
          width: 320,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: StudioTheme.borderColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    '組み込みテンプレート (${_architectures.length})',
                    style: const TextStyle(
                      color: StudioTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _architectures.length,
                    itemBuilder: (context, index) {
                      final arch = _architectures[index];
                      final isSelected = arch.id == _selectedId;
                      return _ArchCard(
                        arch: arch,
                        isSelected: isSelected,
                        onTap: () => _showDetail(arch.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── 右ペイン: 詳細 ──
        Expanded(
          child: _selectedId == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_outlined,
                          size: 40, color: StudioTheme.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'アーキテクチャを選択してください',
                        style: TextStyle(
                          color: StudioTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : _isLoadingDetail
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: StudioTheme.accentPurple),
                    )
                  : _buildDetailView(),
        ),
      ],
    );
  }

  Widget _buildDetailView() {
    return Container(
      color: StudioTheme.editorBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 詳細ヘッダー
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
                const Icon(Icons.description_outlined,
                    size: 16, color: StudioTheme.accentPurple),
                const SizedBox(width: 8),
                Text(
                  _selectedId!.replaceAll('_', ' ').toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: StudioTheme.accentPurple,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          // 詳細コンテンツ
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SelectableText(
                _detailOutput,
                style: const TextStyle(
                  color: StudioTheme.textSecondary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// アーキテクチャ情報
class _ArchInfo {
  final String id;
  final String name;
  const _ArchInfo({required this.id, required this.name});
}

/// アーキテクチャカード
class _ArchCard extends StatefulWidget {
  final _ArchInfo arch;
  final bool isSelected;
  final VoidCallback onTap;

  const _ArchCard({
    required this.arch,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ArchCard> createState() => _ArchCardState();
}

class _ArchCardState extends State<_ArchCard> {
  bool _isHovered = false;

  IconData get _archIcon {
    final id = widget.arch.id.toLowerCase();
    if (id.contains('clean')) return Icons.layers_outlined;
    if (id.contains('mvvm')) return Icons.view_compact_outlined;
    if (id.contains('bloc')) return Icons.hub_outlined;
    return Icons.architecture_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? StudioTheme.accentPurple.withValues(alpha: 0.1)
                : _isHovered
                    ? StudioTheme.surfaceBg
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? StudioTheme.accentPurple.withValues(alpha: 0.3)
                  : _isHovered
                      ? StudioTheme.borderLight
                      : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _archIcon,
                size: 18,
                color: widget.isSelected
                    ? StudioTheme.accentPurple
                    : StudioTheme.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.arch.name,
                      style: TextStyle(
                        color: widget.isSelected
                            ? StudioTheme.textPrimary
                            : StudioTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.arch.id,
                      style: const TextStyle(
                        color: StudioTheme.textMuted,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: widget.isSelected
                    ? StudioTheme.accentPurple
                    : StudioTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
