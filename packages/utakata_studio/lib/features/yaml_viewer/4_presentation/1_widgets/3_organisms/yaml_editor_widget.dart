import 'package:flutter/material.dart';

import '../../../../../core/theme/studio_theme.dart';

/// YAML テキストを編集するエディタウィジェット (Organism)
class YamlEditorWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isValid;
  final ValueChanged<String> onChanged;

  const YamlEditorWidget({
    super.key,
    required this.controller,
    required this.isValid,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StudioTheme.editorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid
              ? StudioTheme.borderColor
              : StudioTheme.accentRed.withOpacity(0.4),
          width: isValid ? 1 : 1.5,
        ),
        boxShadow: [
          if (!isValid)
            BoxShadow(
              color: StudioTheme.accentRed.withOpacity(0.06),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'Consolas',
          color: StudioTheme.textPrimary,
          fontSize: 13,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'YAML をロード中...',
          hintStyle: TextStyle(color: StudioTheme.textMuted),
        ),
      ),
    );
  }
}
