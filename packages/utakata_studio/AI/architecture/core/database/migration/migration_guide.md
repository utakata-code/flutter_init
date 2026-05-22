---
applyTo: 'lib/core/database/migration/**'
---

# Core Database Migration Instructions - マイグレーションガイド

## 概要
`lib/core/database/migration/` はデータベーススキーマのバージョン別マイグレーションファイルを管理します。各マイグレーションファイルはスキーマ変更の履歴として保持され、アプリのアップデート時にデータを安全に移行します。

## 役割と責務
- バージョン別のスキーマ変更を個別ファイルで管理
- テーブルの追加・変更・削除の履歴を保持
- 段階的なマイグレーション実行を可能にする

## してはいけないこと
- マイグレーションファイルの事後編集（リリース後）
- ドメインロジックやUI関連の処理の記述
- 既存マイグレーションファイルの削除

## 命名規則
- ファイル名: `migration_v{N}.dart`（N はスキーマバージョン番号）
- 例: `migration_v2.dart`, `migration_v3.dart`

## 推奨パターン

```dart
// migration_v2.dart
// バージョン1→2のマイグレーション

import 'package:drift/drift.dart';

/// スキーマバージョン2へのマイグレーション
/// 変更内容: users テーブルに email カラムを追加
MigrationStepWithVersion migrationV2() {
  return MigrationStepWithVersion(
    from: 1,
    to: 2,
    step: (Migrator m, Schema2 schema) async {
      await m.addColumn(schema.users, schema.users.email);
    },
  );
}
```

## database.dart での登録例

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: stepByStep(
    from1To2: (m, schema) => migrationV2().step(m, schema),
    from2To3: (m, schema) => migrationV3().step(m, schema),
  ),
);
```

## import 指針
### 許可（例）
```dart
import 'package:drift/drift.dart';
```
### 禁止（例）
```dart
// UI／ネットワーク層などの責務外
// import 'package:flutter/material.dart';
```

## テスト指針
- 各バージョン間のマイグレーションが正常に動作することを検証
- データの整合性確認（既存データが保持されること）
- 複数バージョンをまたぐマイグレーションのテスト
