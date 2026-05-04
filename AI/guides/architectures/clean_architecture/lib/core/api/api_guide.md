---
applyTo: 'lib/core/api/**'
---

# Core API Instructions - APIクライアントガイド

## 概要
`lib/core/api/` は HTTP クライアント（例：Dio）の共通設定を提供します。ベース URL、タイムアウト、インターセプタ、リトライ方針などを統一し、各フィーチャーの DataSource から再利用します。

## 役割と責務
- クライアント初期化と共通インターセプタ（認証ヘッダ、ログ、エラーハンドリング）
- 環境別設定（開発／本番の切り替え）
- リトライ・タイムアウト・ベース URL の統一

## してはいけないこと
- 具体的なエンドポイント・DTO の定義（フィーチャー側の DataSource に配置）
- フィーチャー固有のビジネスロジックの実装

## 推奨構成
```
lib/core/api/
├── http_client.dart         # Dio 等の初期化
└── interceptors/            # 認証／ログ／変換インターセプタ
```

## import 指針
### 許可（例）
```dart
import 'package:dio/dio.dart';
```
### 禁止（例）
```dart
// UI／状態管理など Core の責務外
// import 'package:flutter/material.dart';
```

## テスト指針
- インターセプタの挙動（ヘッダ付与、ログ、エラーマッピング）
- タイムアウトやベース URL 設定の検証