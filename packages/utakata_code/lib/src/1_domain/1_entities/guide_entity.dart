/// レイヤーごとのガイド定義エンティティ
///
/// ガイド生成に必要なすべての規約メタデータ（すべきこと、してはいけないこと、import制約、命名規則）を保持する。
class GuideEntity {
  /// タイトル（例: "Entity Layer Instructions - エンティティ層"）
  final String title;

  /// レイヤーのディレクトリパス（例: "1_domain/1_entities"）
  final String layerPath;

  /// 適用されるファイルパターン（例: "lib/features/**/1_domain/1_entities/**"）
  final String applyTo;

  /// 「すべきこと」のルールリスト
  final List<String> doList;

  /// 「してはいけないこと」のルールリスト
  final List<String> dontList;

  /// 許可される import パターンのリスト（例: "import 'dart:core';"）
  final List<String> allowedImports;

  /// 禁止される import パターンのリスト（例: "import 'package:flutter/material.dart';"）
  final List<String> forbiddenImports;

  /// 命名規則のパターン表現（例: "{対象名}_entity.dart"）
  final String namingPattern;

  /// 詳細説明やコード例などが記載されたベースとなる Markdown アセットファイルへの相対パス
  /// （例: "architectures/clean_architecture/AI/architecture/features/1_domain/1_entities/GUIDE_DETAIL.md"）
  final String detailContentPath;

  const GuideEntity({
    required this.title,
    required this.layerPath,
    required this.applyTo,
    required this.doList,
    required this.dontList,
    required this.allowedImports,
    required this.forbiddenImports,
    required this.namingPattern,
    required this.detailContentPath,
  });

  /// ガイドを Markdown テキストとしてレンダリングする
  ///
  /// [detailContent]: アセットから読み込まれた詳細な解説・コード例テキスト。null の場合はメタデータのみでレンダリングする。
  /// [importConstraints]: `import_rules`/配置宣言から生成された依存制約の
  /// Markdown。非 null なら手書きの [allowedImports]/[forbiddenImports]
  /// の代わりにこれを表示する(v2 定義: 例示の二重管理をやめ、監査規則を
  /// 単一の情報源にする)。
  String render(String? detailContent, {String? importConstraints}) {
    final buffer = StringBuffer();

    // フロントマターの出力
    buffer.writeln('---');
    buffer.writeln("applyTo: '$applyTo'");
    buffer.writeln('---');
    buffer.writeln();

    // タイトル
    buffer.writeln('# $title');
    buffer.writeln();

    // 役割と責務
    buffer.writeln('## 役割と責務');
    buffer.writeln();
    buffer.writeln('### ✅ すべきこと');
    if (doList.isEmpty) {
      buffer.writeln('- 特になし');
    } else {
      for (final item in doList) {
        buffer.writeln('- $item');
      }
    }
    buffer.writeln();

    buffer.writeln('### ❌ してはいけないこと');
    if (dontList.isEmpty) {
      buffer.writeln('- 特になし');
    } else {
      for (final item in dontList) {
        buffer.writeln('- $item');
      }
    }
    buffer.writeln();

    // 依存関係の制約
    buffer.writeln('## 依存関係の制約');
    buffer.writeln();
    if (importConstraints != null && importConstraints.trim().isNotEmpty) {
      buffer.writeln(importConstraints.trim());
      buffer.writeln();
    } else {
      buffer.writeln('### 許可されるimport');
      if (allowedImports.isEmpty) {
        buffer.writeln('特になし');
      } else {
        buffer.writeln('```dart');
        for (final imp in allowedImports) {
          buffer.writeln(imp);
        }
        buffer.writeln('```');
      }
      buffer.writeln();

      buffer.writeln('### 禁止されるimport');
      if (forbiddenImports.isEmpty) {
        buffer.writeln('特になし');
      } else {
        buffer.writeln('```dart');
        for (final imp in forbiddenImports) {
          buffer.writeln(imp);
        }
        buffer.writeln('```');
      }
      buffer.writeln();
    }

    // 命名規則
    buffer.writeln('## 命名規則');
    buffer.writeln();
    buffer.writeln('- **命名パターン**: `$namingPattern`');
    buffer.writeln();

    // 詳細解説コンテンツ（概要、実装ガイドライン、コード例、ベストプラクティス、テスト指針など）
    if (detailContent != null && detailContent.trim().isNotEmpty) {
      buffer.writeln(detailContent.trim());
      buffer.writeln();
    }

    return buffer.toString();
  }
}
