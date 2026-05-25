import 'package:flutter/material.dart';
import '../../../../../core/theme/studio_theme.dart';

/// コマンド出力のリアルタイム表示
class CommandOutputMolecule extends StatelessWidget {
  final List<String> outputLines;
  final bool isRunning;
  final int? exitCode;

  const CommandOutputMolecule({
    super.key,
    required this.outputLines,
    this.isRunning = false,
    this.exitCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StudioTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ヘッダー ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: StudioTheme.borderColor)),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal,
                    size: 14, color: StudioTheme.textMuted),
                const SizedBox(width: 8),
                const Text('OUTPUT',
                    style: TextStyle(
                        color: StudioTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const Spacer(),
                if (isRunning)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: StudioTheme.accentCyan),
                  ),
                if (exitCode != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: exitCode == 0
                          ? StudioTheme.accentGreen.withValues(alpha: 0.15)
                          : StudioTheme.accentRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'exit: $exitCode',
                      style: TextStyle(
                        color: exitCode == 0
                            ? StudioTheme.accentGreen
                            : StudioTheme.accentRed,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── 出力本体 ──
          Expanded(
            child: outputLines.isEmpty
                ? const Center(
                    child: Text('コマンドを実行してください',
                        style: TextStyle(
                            color: StudioTheme.textMuted, fontSize: 12)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: outputLines.length,
                    itemBuilder: (context, index) {
                      final line = outputLines[index];
                      final isError = line.startsWith('[stderr]');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          line,
                          style: TextStyle(
                            color: isError
                                ? StudioTheme.accentRed
                                : StudioTheme.textSecondary,
                            fontSize: 12,
                            fontFamily: 'monospace',
                            height: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
