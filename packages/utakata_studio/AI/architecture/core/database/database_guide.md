---
applyTo: 'lib/core/database/**'
---

# Core Database Instructions - データベースガイド

## 概要
`lib/core/database/` は DB 接続と共通ユーティリティを提供します。パス管理、暗号化、マイグレーション方針を統一し、フィーチャー間で再利用可能とします。テーブル定義は `database/table/` に配置します。

## 役割と責務
- DB の初期化／接続管理（例：Drift）
- 共通ユーティリティ（パス、暗号化、マイグレーション）
- テーブル定義の参照と登録（`table/` 配下）

## してはいけないこと
- ドメイン固有の CRUD 実装（Repository／DataSource に配置）
- UI／状態管理への依存や表示ロジックの混在

## 推奨構成
```
lib/core/database/
├── database.dart        # 接続初期化・テーブル登録・マイグレーション定義
├── table/               # テーブル定義（Drift スキーマ等）
└── migration/           # バージョン別マイグレーションファイル
    ├── migration_v2.dart
    ├── migration_v3.dart
    └── ...
```

## マイグレーション管理
- `migration/` にバージョンごとのマイグレーションファイルを配置
- 命名規則: `migration_v{N}.dart`（N はスキーマバージョン番号）
- 各ファイルにはそのバージョンでのスキーマ変更内容を記述
- `database.dart` 内の `migration` プロパティで各バージョンのマイグレーションを登録

## import 指針
### 許可（例）
```dart
import 'package:drift/drift.dart';
```
### 禁止（例）
```dart
// UI／ネットワーク層などの責務外
// import 'package:flutter/material.dart';
// import 'package:dio/dio.dart';
```

## テスト指針
- マイグレーションの整合性（バージョンアップ時の移行）
- 接続初期化・テーブル登録の検証