---
applyTo: 'lib/core/routing/**'
---

# Core Routing Instructions - ルーティングガイド

## 概要
`lib/core/routing/` はアプリ全体のルーティング設定を提供します。`GoRouter` などの共通ルーティングを初期化し、画面遷移のポリシー（認証ガード、リダイレクト、Deep Link 対応）を統一します。画面ごとのパスは `routing/path/` に定義し、UI からはその定義を参照して遷移します。

## 役割と責務
- ルーター本体の初期化（`GoRouter` 設定、リダイレクト方針）
- 認証／権限ガード・遷移中のハンドリング（スプラッシュ、保護ページ等）
- `routing/path/` のパス定義を参照した型安全な遷移

## してはいけないこと
- UI ウィジェットや画面ロジックの直接実装
- フィーチャー固有のロジック（ドメイン知識）の混入
- 画面のビルドや状態管理の記述（Presentation 層へ）

## 推奨構成
```
lib/core/routing/
├── app_router.dart   # GoRouter 初期化・設定
└── path/             # 画面パス定義（定数・型）
```

## 設計ガイドライン
- 画面パスはすべて `routing/path/` に集約し、文字列散在を回避
- リダイレクト方針（ログイン必須、初回起動導線等）はここで統一
- 型安全な遷移（引数必須のルートはクラスやヘルパーで表現）

## import 指針
### 許可（例）
```dart
import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';
```
### 禁止（例）
```dart
// UI コンポーネントに依存する material ベースの画面実装
// import 'package:flutter/material.dart';
```

## テスト指針
- ルート解決／ガード動作／リダイレクトの単体テスト
- `path` 定義に対する遷移ヘルパーの検証（必須引数の漏れ防止）