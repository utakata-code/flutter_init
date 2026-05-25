# API ガイド — MVVM

## 概要

`lib/core/api/` は HTTP クライアント（Dio）の基盤設定を管理する。

## ファイル構成

```
lib/core/api/
├── api_client.dart        # Dio インスタンスの設定
├── interceptors/          # カスタムインターセプター
│   ├── auth_interceptor.dart
│   └── logging_interceptor.dart
└── api_constants.dart     # ベースURL・タイムアウト等
```

## 実装例

```dart
// api_client.dart
import 'package:dio/dio.dart';
import 'api_constants.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  Dio get dio => _dio;
}
```

```dart
// api_constants.dart
abstract class ApiConstants {
  static const baseUrl = 'https://api.example.com/v1';
}
```

## ルール

- API キーやシークレットは環境変数で管理する（ハードコード禁止）
- エラーハンドリングはインターセプターで一元化する
- フィーチャー固有の API 呼び出しは各フィーチャーの Repository 実装で行う
