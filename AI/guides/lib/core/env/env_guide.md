---
applyTo: 'lib/core/env/**'
---

# Core Env Instructions - 環境変数・アプリ設定ガイド

## 概要
`lib/core/env/` は `envied` と `envied_gen` を使用して、アプリケーション全体の環境変数と設定値をセキュアに管理します。`.env` ファイルからの読み込みと難読化（obfuscate）により、APIキーやベースURLなどの機密情報を安全に扱います。

## 役割と責務
- `.env` ファイルを利用した環境変数の管理
- `envied` によるコンパイル時のセキュアな定数ジェネレートと難読化
- 開発・ステージング・本番環境など、ビルドに応じた設定値の提供
- アプリ全体で参照される構成値・設定の一元管理

## してはいけないこと
- **`.env` ファイルを Git リポジトリにコミットすること（必ず `.gitignore` に追加してください）**
- `env.g.dart` などの自動生成ファイルを直接編集すること
- UI／状態管理層から直接 `env.dart` を参照すること（テストや環境切り替えを容易にするため、`AppConfig` 等のWrapperクラスを通すことを推奨します）
- ソースコードへの直接的なAPIキーやシークレットのハードコーディング

## 推奨構成
```text
lib/core/env/
├── config/
│   └── app_config.dart # 環境変数をラップしてアプリに提供する構成クラス（任意）
├── env.dart            # Enviedを定義する抽象クラス
└── env.g.dart          # build_runnerで自動生成されるファイル
```

プロジェクトルートには、各環境ごとの `.env` ファイルを用意します（例: `.env.dev`, `.env.production`）。

## 推奨パターン

### 1. 依存関係の追加
`pubspec.yaml` にパッケージを追加します。
```yaml
dependencies:
  envied: ^x.x.x

dev_dependencies:
  envied_gen: ^x.x.x
  build_runner: ^x.x.x
```

### 2. 環境変数の定義 (.env ファイル)
```env
# .env.dev の例
API_BASE_URL=http://localhost:8080
API_KEY=your_dev_api_key_here
```

### 3. Envクラスの定義
```dart
// lib/core/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

/// 開発環境向けの設定
@Envied(path: '.env.dev', obfuscate: true)
abstract class EnvDev {
  @EnviedField(varName: 'API_BASE_URL')
  static const String apiBaseUrl = _EnvDev.apiBaseUrl;

  @EnviedField(varName: 'API_KEY', obfuscate: true)
  static final String apiKey = _EnvDev.apiKey;
}

/// 本番環境向けの設定
@Envied(path: '.env.production', obfuscate: true)
abstract class EnvProd {
  @EnviedField(varName: 'API_BASE_URL')
  static const String apiBaseUrl = _EnvProd.apiBaseUrl;

  @EnviedField(varName: 'API_KEY', obfuscate: true)
  static final String apiKey = _EnvProd.apiKey;
}
```

※ 注意: `envied` によって生成されるフィールドは `static const`（または `static final`）になります。実行環境（`--dart-define` 等）に応じてこれらを動的に切り替えるには、以下のような Wrapper クラスを作成して依存性注入（DI）を利用します。

### 4. 設定のラップと切り替え (AppConfig)
```dart
// lib/core/env/config/app_config.dart
import '../env.dart';

enum Environment { dev, production }

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String apiKey;

  AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.apiKey,
  });

  factory AppConfig.dev() {
    return AppConfig._(
      environment: Environment.dev,
      apiBaseUrl: EnvDev.apiBaseUrl,
      apiKey: EnvDev.apiKey,
    );
  }

  factory AppConfig.production() {
    return AppConfig._(
      environment: Environment.production,
      apiBaseUrl: EnvProd.apiBaseUrl,
      apiKey: EnvProd.apiKey,
    );
  }
}
```

## import 指針
### 許可（例）
```dart
import 'package:envied/envied.dart';
```
### 禁止（例）
```dart
// UIやネットワーク層など、直接関係のないパッケージのインポート
// import 'package:flutter/material.dart';
// import 'package:dio/dio.dart';
```

## テスト指針
- `env.dart` 自体は `static` メソッドを持つため、直接モック化することが困難です。テスト対象のクラスには直接 `EnvDev.apiKey` などを読ませず、`AppConfig` などのインスタンスを DI し、モックを利用できるように設計してください。
- CI環境などで環境変数が欠落していると `build_runner` 実行時にエラーとなります。適切なプレースホルダーを持ったダミーの `.env` を用意するか、環境変数をCIの実行環境から注入する設定が必要です。
