---
applyTo: 'lib/core/routing/path/**'
---

# Core Routing Path Instructions - パス定義ガイド

## 概要
`lib/core/routing/path/` は画面パスとルート名を一元管理します。UI／フィーチャー側はここで定義された定数や型を参照して遷移を実行し、パス文字列の散在や変更コストを削減します。

## 役割と責務
- 画面パスの定数化／命名規則の提供（`/settings`, `/profile/:id` など）
- ルート名（`name`）の一意性と衝突防止
- 必須引数を型で表現するためのヘルパー提供（必要に応じて）

## してはいけないこと
- UI ロジックや画面ビルドの記述
- ルーター初期化やリダイレクト方針の記述（`routing/` 側へ）

## 命名・設計指針
- `snake_case` でパス定数を定義し、意味が伝わる語彙を使用
- パラメータ付きパスは `:id` 等の表記を統一
- ルート名（`name`）は一意・機械可読（例：`profile_detail`）

## import 指針
### 許可（例）
```dart
import 'dart:core';
```
### 禁止（例）
```dart
// UI／状態管理／外部通信など
// import 'package:flutter/material.dart';
// import 'package:riverpod/riverpod.dart';
```

## テスト指針
- パス定義の整合性（重複なし、命名規則順守）
- 必須引数ヘルパーの入力検証（不足時に失敗）