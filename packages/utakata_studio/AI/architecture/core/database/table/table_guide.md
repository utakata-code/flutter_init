---
applyTo: 'lib/core/database/table/**'
---

# Core Database Table Instructions - テーブル定義ガイド

## 概要
`lib/core/database/table/` は DB のテーブル定義（例：Drift テーブル）を管理します。フィーチャー間で再利用可能な共通スキーマをここに定義し、CRUD の実装はフィーチャー側の Repository／DataSource で行います。

## 役割と責務
- テーブルスキーマ定義とインデックス設計
- スキーマの命名規則とバージョニング
- 参照・外部キー関係の明確化（必要に応じて）

## してはいけないこと
- データアクセスのロジック実装（クエリやリポジトリはフィーチャー側）
- UI／状態管理の記述

## 命名・設計指針
- テーブル名は `snake_case`、カラム名も一貫した規則に従う
- テーブルごとに `PRIMARY KEY` とインデックスを適切に設計
- 変更はマイグレーションルールに従い、後方互換性を意識

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
- スキーマ定義の検証（必須カラム、制約、インデックス）
- マイグレーション時の整合性確認（カラム追加／変更）