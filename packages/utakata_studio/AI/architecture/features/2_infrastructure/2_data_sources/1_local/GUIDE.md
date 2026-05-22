---
applyTo: 'lib/features/**/2_infrastructure/2_data_sources/1_local/**'
---

# Local Data Source Layer Instructions - ローカルデータソース層

## 概要
ローカルデータソース層は、デバイス内のデータストレージ（Drift、SharedPreferences、ファイルシステムなど）へのアクセスを担当します。データの永続化、キャッシュ、オフライン対応を実現するための重要な層です。

## 役割と責務

### ✅ すべきこと
- **ローカルストレージアクセス**: Drift、SharedPreferences、ファイルシステムへの操作
- **データキャッシュ**: リモートから取得したデータのローカル保存
- **オフライン対応**: ネットワーク接続がない場合のデータ提供
- **データ同期**: ローカルとリモートデータの整合性管理
- **CRUD操作**: Create、Read、Update、Deleteの実装

### ❌ してはいけないこと
- **ビジネスロジックの実装**: ドメインルールやビジネス判断の記述
- **UIロジックの実装**: プレゼンテーション層のロジックの混入
- **ネットワーク通信**: HTTPリクエストやAPI呼び出し
- **エンティティの直接使用**: ドメインエンティティではなくモデルクラスを使用

## 実装ガイドライン
※ インターフェースと実装は必ず別ファイルに分割してください（インターフェース: `{対象名}_local_data_source.dart`、実装: `{対象名}_local_data_source_impl.dart`）。以下のコード例は理解しやすさのために同一セクションで示していますが、実際のプロジェクトでは分割して配置します。

### 1. ファイル分割構造

**📁 必須ファイル構造**
```
lib/features/{feature_name}/2_infrastructure/2_data_sources/1_local/
├── user_local_data_source.dart          # インターフェース定義
├── user_local_data_source_impl.dart     # Drift実装
├── settings_local_data_source.dart      # インターフェース定義
├── settings_local_data_source_impl.dart # SharedPreferences実装
└── exceptions/
    └── local_data_source_exceptions.dart # 例外クラス
```

### 2. Driftデータソースの基本実装

#### インターフェース定義
```dart
// user_local_data_source.dart
import '../../1_models/user_db_model.dart';

abstract interface class UserLocalDataSource {
  Future<UserDbModel?> getUser(String id);
  Future<List<UserDbModel>> getAllUsers();
  Future<List<UserDbModel>> getUsersByRole(String role);
  Future<void> saveUser(UserDbModel user);
  Future<void> saveUsers(List<UserDbModel> users);
  Future<void> updateUser(UserDbModel user);
  Future<void> deleteUser(String id);
  Future<void> deleteAllUsers();
  Future<bool> userExists(String id);
  Stream<List<UserDbModel>> watchAllUsers();
  Stream<UserDbModel?> watchUser(String id);
}
```

#### Drift実装クラス
```dart
// user_local_data_source_impl.dart
import 'package:drift/drift.dart';
import '../../1_models/user_db_model.dart';
import '../../../core/database/app_database.dart';
import 'user_local_data_source.dart';
import 'exceptions/local_data_source_exceptions.dart';

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final AppDatabase _database;

  UserLocalDataSourceImpl(this._database);

  @override
  Future<UserDbModel?> getUser(String id) async {
    try {
      final user = await (_database.select(_database.users)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

      if (user != null) {
        return UserDbModel.fromDriftUser(user);
      }
      return null;
    } catch (e) {
      throw LocalDataSourceException('Failed to get user: $e');
    }
  }

  @override
  Future<List<UserDbModel>> getAllUsers() async {
    try {
      final users = await (_database.select(_database.users)
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
          .get();

      return users.map((user) => UserDbModel.fromDriftUser(user)).toList();
    } catch (e) {
      throw LocalDataSourceException('Failed to get all users: $e');
    }
  }

  @override
  Future<List<UserDbModel>> getUsersByRole(String role) async {
    try {
      final users = await (_database.select(_database.users)
            ..where((tbl) => tbl.role.equals(role))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
          .get();

      return users.map((user) => UserDbModel.fromDriftUser(user)).toList();
    } catch (e) {
      throw LocalDataSourceException('Failed to get users by role: $e');
    }
  }

  @override
  Future<void> saveUser(UserDbModel user) async {
    try {
      await _database.into(_database.users).insertOnConflictUpdate(
        user.toDriftCompanion(),
      );
    } catch (e) {
      throw LocalDataSourceException('Failed to save user: $e');
    }
  }

  @override
  Future<void> saveUsers(List<UserDbModel> users) async {
    try {
      await _database.batch((batch) {
        for (final user in users) {
          batch.insertOnConflictUpdate(
            _database.users,
            user.toDriftCompanion(),
          );
        }
      });
    } catch (e) {
      throw LocalDataSourceException('Failed to save users: $e');
    }
  }

  @override
  Future<void> updateUser(UserDbModel user) async {
    try {
      final success = await (_database.update(_database.users)
            ..where((tbl) => tbl.id.equals(user.id)))
          .write(user.toDriftCompanion());

      if (success == 0) {
        throw LocalDataSourceException('User not found for update: ${user.id}');
      }
    } catch (e) {
      throw LocalDataSourceException('Failed to update user: $e');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      final count = await (_database.delete(_database.users)
            ..where((tbl) => tbl.id.equals(id)))
          .go();

      if (count == 0) {
        throw LocalDataSourceException('User not found for delete: $id');
      }
    } catch (e) {
      throw LocalDataSourceException('Failed to delete user: $e');
    }
  }

  @override
  Future<void> deleteAllUsers() async {
    try {
      await _database.delete(_database.users).go();
    } catch (e) {
      throw LocalDataSourceException('Failed to delete all users: $e');
    }
  }

  @override
  Future<bool> userExists(String id) async {
    try {
      final user = await (_database.select(_database.users)
            ..where((tbl) => tbl.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

      return user != null;
    } catch (e) {
      throw LocalDataSourceException('Failed to check user existence: $e');
    }
  }

  @override
  Stream<List<UserDbModel>> watchAllUsers() {
    return (_database.select(_database.users)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch()
        .map((users) => users.map((user) => UserDbModel.fromDriftUser(user)).toList());
  }

  @override
  Stream<UserDbModel?> watchUser(String id) {
    return (_database.select(_database.users)
          ..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull()
        .map((user) => user != null ? UserDbModel.fromDriftUser(user) : null);
  }
}
```

### 3. SharedPreferencesデータソースの実装

#### インターフェース定義
```dart
// settings_local_data_source.dart
abstract interface class SettingsLocalDataSource {
  Future<String?> getString(String key);
  Future<int?> getInt(String key);
  Future<bool?> getBool(String key);
  Future<double?> getDouble(String key);
  Future<List<String>?> getStringList(String key);
  
  Future<void> setString(String key, String value);
  Future<void> setInt(String key, int value);
  Future<void> setBool(String key, bool value);
  Future<void> setDouble(String key, double value);
  Future<void> setStringList(String key, List<String> value);
  
  Future<void> remove(String key);
  Future<void> clear();
  Future<bool> containsKey(String key);
  Future<Set<String>> getKeys();
}
```

#### SharedPreferences実装クラス
```dart
// settings_local_data_source_impl.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_local_data_source.dart';
import 'exceptions/local_data_source_exceptions.dart';

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences _prefs;

  SettingsLocalDataSourceImpl(this._prefs);

  @override
  Future<String?> getString(String key) async {
    try {
      return _prefs.getString(key);
    } catch (e) {
      throw LocalDataSourceException('Failed to get string: $e');
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    try {
      final success = await _prefs.setString(key, value);
      if (!success) {
        throw LocalDataSourceException('Failed to set string for key: $key');
      }
    } catch (e) {
      throw LocalDataSourceException('Failed to set string: $e');
    }
  }

  @override
  Future<int?> getInt(String key) async {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      throw LocalDataSourceException('Failed to get int: $e');
    }
  }

  @override
  Future<void> setInt(String key, int value) async {
    try {
      final success = await _prefs.setInt(key, value);
      if (!success) {
        throw LocalDataSourceException('Failed to set int for key: $key');
      }
    } catch (e) {
      throw LocalDataSourceException('Failed to set int: $e');
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      throw LocalDataSourceException('Failed to get bool: $e');
    }
  }

  @override
  Future<void> setBool(String key, bool value) async {
    try {
      final success = await _prefs.setBool(key, value);
      if (!success) {
        throw LocalDataSourceException('Failed to set bool for key: $key');
      }
    } catch (e) {
      throw LocalDataSourceException('Failed to set bool: $e');
    }
  }

  @override
  Future<double?> getDouble(String key) async {
    try {
      return _prefs.getDouble(key);
    } catch (e) {
      throw LocalDataSourceException('Failed to get double: $e');
    }
  }

  @override
  Future<void> setDouble(String key, double value) async {
    try {
      final success = await _prefs.setDouble(key, value);
      if (!success) {
        throw LocalDataSourceException('Failed to set double for key: $key');
      }
    } catch (e) {
      throw LocalDataSourceException('Failed to set double: $e');
    }
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    try {
      return _prefs.getStringList(key);
    } catch (e) {
      throw LocalDataSourceException('Failed to get string list: $e');
    }
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    try {
      final success = await _prefs.setStringList(key, value);
      if (!success) {
        throw LocalDataSourceException('Failed to set string list for key: $key');
      }
    } catch (e) {
      throw LocalDataSourceException('Failed to set string list: $e');
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      final success = await _prefs.remove(key);
      if (!success) {
        throw LocalDataSourceException('Failed to remove key: $key');
      }
    } catch (e) {
      throw LocalDataSourceException('Failed to remove key: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      final success = await _prefs.clear();
      if (!success) {
        throw LocalDataSourceException('Failed to clear preferences');
      }
    } catch (e) {
      throw LocalDataSourceException('Failed to clear preferences: $e');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return _prefs.containsKey(key);
    } catch (e) {
      throw LocalDataSourceException('Failed to check key existence: $e');
    }
  }

  @override
  Future<Set<String>> getKeys() async {
    try {
      return _prefs.getKeys();
    } catch (e) {
      throw LocalDataSourceException('Failed to get keys: $e');
    }
  }
}
```

### 4. ファイルシステムデータソースの実装

#### インターフェース定義
```dart
// file_local_data_source.dart
abstract interface class FileLocalDataSource {
  Future<String> readTextFile(String fileName);
  Future<void> writeTextFile(String fileName, String content);
  Future<Map<String, dynamic>> readJsonFile(String fileName);
  Future<void> writeJsonFile(String fileName, Map<String, dynamic> data);
  Future<bool> fileExists(String fileName);
  Future<void> deleteFile(String fileName);
  Future<List<String>> listFiles({String? extension});
  Future<void> copyFile(String sourceFileName, String targetFileName);
  Future<int> getFileSize(String fileName);
  Future<DateTime> getLastModified(String fileName);
}
```

#### ファイルシステム実装クラス
```dart
// file_local_data_source_impl.dart
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'file_local_data_source.dart';
import 'exceptions/local_data_source_exceptions.dart';

class FileLocalDataSourceImpl implements FileLocalDataSource {
  late final Directory _appDocumentDir;
  
  FileLocalDataSourceImpl();

  Future<void> initialize() async {
    _appDocumentDir = await getApplicationDocumentsDirectory();
  }

  File _getFile(String fileName) {
    return File('${_appDocumentDir.path}/$fileName');
  }

  @override
  Future<String> readTextFile(String fileName) async {
    try {
      final file = _getFile(fileName);
      
      if (!await file.exists()) {
        throw LocalDataSourceException('File not found: $fileName');
      }
      
      return await file.readAsString();
    } catch (e) {
      throw LocalDataSourceException('Failed to read text file: $e');
    }
  }

  @override
  Future<void> writeTextFile(String fileName, String content) async {
    try {
      final file = _getFile(fileName);
      await file.writeAsString(content);
    } catch (e) {
      throw LocalDataSourceException('Failed to write text file: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> readJsonFile(String fileName) async {
    try {
      final content = await readTextFile(fileName);
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      throw LocalDataSourceException('Failed to read JSON file: $e');
    }
  }

  @override
  Future<void> writeJsonFile(String fileName, Map<String, dynamic> data) async {
    try {
      final content = json.encode(data);
      await writeTextFile(fileName, content);
    } catch (e) {
      throw LocalDataSourceException('Failed to write JSON file: $e');
    }
  }

  @override
  Future<bool> fileExists(String fileName) async {
    try {
      final file = _getFile(fileName);
      return await file.exists();
    } catch (e) {
      throw LocalDataSourceException('Failed to check file existence: $e');
    }
  }

  @override
  Future<void> deleteFile(String fileName) async {
    try {
      final file = _getFile(fileName);
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw LocalDataSourceException('Failed to delete file: $e');
    }
  }

  @override
  Future<List<String>> listFiles({String? extension}) async {
    try {
      final files = await _appDocumentDir.list().toList();
      final fileNames = files
          .whereType<File>()
          .map((file) => file.path.split('/').last)
          .where((name) => extension == null || name.endsWith(extension))
          .toList();
      
      return fileNames;
    } catch (e) {
      throw LocalDataSourceException('Failed to list files: $e');
    }
  }

  @override
  Future<void> copyFile(String sourceFileName, String targetFileName) async {
    try {
      final sourceFile = _getFile(sourceFileName);
      final targetFile = _getFile(targetFileName);
      
      if (!await sourceFile.exists()) {
        throw LocalDataSourceException('Source file does not exist: $sourceFileName');
      }
      
      await sourceFile.copy(targetFile.path);
    } catch (e) {
      throw LocalDataSourceException('Failed to copy file: $e');
    }
  }

  @override
  Future<int> getFileSize(String fileName) async {
    try {
      final file = _getFile(fileName);
      if (!await file.exists()) {
        throw LocalDataSourceException('File does not exist: $fileName');
      }
      return await file.length();
    } catch (e) {
      throw LocalDataSourceException('Failed to get file size: $e');
    }
  }

  @override
  Future<DateTime> getLastModified(String fileName) async {
    try {
      final file = _getFile(fileName);
      if (!await file.exists()) {
        throw LocalDataSourceException('File does not exist: $fileName');
      }
      return await file.lastModified();
    } catch (e) {
      throw LocalDataSourceException('Failed to get last modified date: $e');
    }
  }
}
```

### 4. キャッシュ機能付きデータソース
```dart
// data_sources/local/cache_local_data_source.dart
class CacheLocalDataSource<T> {
  final Map<String, CacheEntry<T>> _cache = {};
  final Duration _defaultTtl;

  CacheLocalDataSource({Duration? defaultTtl})
      : _defaultTtl = defaultTtl ?? const Duration(hours: 1);

  T? get(String key) {
    final entry = _cache[key];
    
    if (entry == null) {
      return null;
    }
    
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value;
  }

  void put(String key, T value, {Duration? ttl}) {
    final expiry = DateTime.now().add(ttl ?? _defaultTtl);
    _cache[key] = CacheEntry(value, expiry);
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  bool containsKey(String key) {
    final entry = _cache[key];
    if (entry == null) {
      return false;
    }
    
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }

  int get size => _cache.length;

  void cleanExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => entry.expiry.isBefore(now));
  }
}

class CacheEntry<T> {
  final T value;
  final DateTime expiry;

  CacheEntry(this.value, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}
```

## 命名規則

### ファイル名規則
インターフェースと実装を必ず別ファイルに分割します。

#### インターフェースファイル
- **命名形式**: `{対象名}_local_data_source.dart`
- **例**: `user_local_data_source.dart`, `settings_local_data_source.dart`

#### 実装ファイル
- **命名形式**: `{対象名}_local_data_source_impl.dart`
- **例**: `user_local_data_source_impl.dart`, `settings_local_data_source_impl.dart`

#### 例外ファイル
- **命名形式**: `exceptions/local_data_source_exceptions.dart`

### クラス名規則

#### インターフェース
- **命名形式**: `{対象名}LocalDataSource`
- **例**: `UserLocalDataSource`, `SettingsLocalDataSource`

#### 実装クラス
- **命名形式**: `{対象名}LocalDataSourceImpl`
- **例**: `UserLocalDataSourceImpl`, `SettingsLocalDataSourceImpl`

#### 例外クラス
- **基底クラス**: `LocalDataSourceException`
- **Drift関連**: `DatabaseException`
- **SharedPreferences関連**: `CacheException`
- **ファイル操作関連**: `FileSystemException`

### メソッド名規則

#### CRUD操作
- **取得系**: `get{対象}`, `getAll{対象}`, `get{対象}By{条件}`
- **保存系**: `save{対象}`, `save{対象}s` (新規作成・更新両対応)
- **作成系**: `create{対象}`, `create{対象}s` (新規作成専用)
- **更新系**: `update{対象}`, `update{対象}s` (更新専用)
- **削除系**: `delete{対象}`, `deleteAll{対象}s`, `delete{対象}sBy{条件}`
- **存在確認**: `{対象}Exists`, `has{対象}`

#### リアクティブ操作
- **監視系**: `watch{対象}`, `watchAll{対象}s`, `watch{対象}sBy{条件}`
- **ストリーム系**: `stream{対象}`, `streamAll{対象}s`

#### 設定操作（SharedPreferences）
- **取得系**: `get{Type}`, `getString`, `getInt`, `getBool`, `getDouble`, `getStringList`
- **設定系**: `set{Type}`, `setString`, `setInt`, `setBool`, `setDouble`, `setStringList`
- **削除系**: `remove`, `removeKey`
- **クリア系**: `clear`, `clearAll`
- **確認系**: `containsKey`, `hasKey`

#### ファイル操作
- **読み込み系**: `readFile`, `readTextFile`, `readJsonFile`, `readBinaryFile`
- **書き込み系**: `writeFile`, `writeTextFile`, `writeJsonFile`, `writeBinaryFile`
- **削除系**: `deleteFile`, `deleteFiles`
- **操作系**: `copyFile`, `moveFile`
- **情報取得系**: `getFileSize`, `getLastModified`, `listFiles`

## ベストプラクティス

### 1. ファイル分割の原則

#### インターフェースと実装の分離
```dart
// ✅ 良い例: インターフェースファイル
// user_local_data_source.dart
abstract interface class UserLocalDataSource {
  Future<UserDbModel?> getUser(String id);
  // メソッド定義のみ
}

// ✅ 良い例: 実装ファイル
// user_local_data_source_impl.dart
class UserLocalDataSourceImpl implements UserLocalDataSource {
  // 具体的な実装
}

// ❌ 悪い例: 一つのファイルに両方
// user_local_data_source.dart
abstract interface class UserLocalDataSource { /* ... */ }
class UserLocalDataSourceImpl implements UserLocalDataSource { /* ... */ }
```

#### 依存関係の管理
```dart
// ✅ 良い例: インターフェースファイルでは外部依存を最小化
// user_local_data_source.dart
import '../../1_models/user_db_model.dart'; // モデルのみ

// ✅ 良い例: 実装ファイルで具体的な依存関係
// user_local_data_source_impl.dart
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import 'user_local_data_source.dart';
import 'exceptions/local_data_source_exceptions.dart';
```

### 2. トランザクション処理
```dart
class UserLocalDataSourceImpl implements UserLocalDataSource {
  final Database _database;

  Future<void> saveUserWithProfile(
    UserDbModel user,
    UserProfileDbModel profile,
  ) async {
    await _database.transaction((txn) async {
      try {
        // ユーザー保存
        await txn.insert(
          UserDbModel.tableName,
          user.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // プロフィール保存
        await txn.insert(
          UserProfileDbModel.tableName,
          profile.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        // トランザクションは自動的にロールバックされる
        throw LocalDataSourceException('Failed to save user with profile: $e');
      }
    });
  }
}
```

### 2. バッチ操作の最適化
```dart
class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  @override
  Future<void> saveProducts(List<ProductDbModel> products) async {
    if (products.isEmpty) return;

    const batchSize = 500; // バッチサイズを制限
    
    for (int i = 0; i < products.length; i += batchSize) {
      final batch = _database.batch();
      final end = (i + batchSize < products.length) ? i + batchSize : products.length;
      
      for (int j = i; j < end; j++) {
        batch.insert(
          ProductDbModel.tableName,
          products[j].toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
    }
  }
}
```

### 3. エラーハンドリングと例外定義
```dart
// exceptions/local_data_source_exceptions.dart
abstract class LocalDataSourceException implements Exception {
  final String message;
  LocalDataSourceException(this.message);
  
  @override
  String toString() => 'LocalDataSourceException: $message';
}

class DatabaseException extends LocalDataSourceException {
  DatabaseException(super.message);
}

class FileSystemException extends LocalDataSourceException {
  FileSystemException(super.message);
}

class CacheException extends LocalDataSourceException {
  CacheException(super.message);
}
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ 標準ライブラリ
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ✅ ローカルストレージライブラリ
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

// ✅ モデルクラス
import '../../1_models/user_db_model.dart';

// ✅ 例外クラス
import '../exceptions/local_data_source_exceptions.dart';
```

### 禁止されるimport
```dart
// ❌ UIフレームワーク
import 'package:flutter/material.dart';

// ❌ HTTP通信
import 'package:dio/dio.dart';
import 'package:http/http.dart';

// ❌ ドメインエンティティ
import '../../../1_domain/1_entities/user_entity.dart';

// ❌ アプリケーション層
import '../../../3_application/states/user_state.dart';
```

## テスト指針

### ファイル分割に対応したテスト構造

**📁 推奨テストファイル構造**
```
test/features/{feature_name}/data/data_sources/local/
├── user_local_data_source_test.dart          # インターフェーステスト
├── user_local_data_source_impl_test.dart     # Drift実装テスト
├── settings_local_data_source_test.dart      # インターフェーステスト
├── settings_local_data_source_impl_test.dart # SharedPreferences実装テスト
└── file_local_data_source_impl_test.dart     # ファイルシステム実装テスト
```

### 1. Driftデータソースのテスト

#### インターフェーステスト（契約テスト）
```dart
// test/features/user/data/data_sources/local/user_local_data_source_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../../../lib/features/user/data/data_sources/local/user_local_data_source.dart';
import '../../../../../lib/features/user/data/models/user_db_model.dart';

@GenerateMocks([UserLocalDataSource])
import 'user_local_data_source_test.mocks.dart';

void main() {
  late MockUserLocalDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockUserLocalDataSource();
  });

  group('UserLocalDataSource Contract Tests', () {
    test('should define all required methods', () {
      // インターフェースの契約をテスト
      expect(mockDataSource.getUser, isA<Function>());
      expect(mockDataSource.saveUser, isA<Function>());
      expect(mockDataSource.deleteUser, isA<Function>());
      expect(mockDataSource.watchAllUsers, isA<Function>());
    });

    test('should handle user retrieval contract', () async {
      // Arrange
      const user = UserDbModel(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
      );
      when(mockDataSource.getUser('1')).thenAnswer((_) async => user);

      // Act
      final result = await mockDataSource.getUser('1');

      // Assert
      expect(result, equals(user));
      verify(mockDataSource.getUser('1')).called(1);
    });
  });
}
```

#### 実装クラステスト
```dart
// test/features/user/data/data_sources/local/user_local_data_source_impl_test.dart
void main() {
  group('UserLocalDataSourceImpl', () {
    late AppDatabase database;
    late UserLocalDataSourceImpl dataSource;

    setUp(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      dataSource = UserLocalDataSourceImpl(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('should save and retrieve user', () async {
      // Given
      final user = UserDbModel(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // When
      await dataSource.saveUser(user);
      final retrievedUser = await dataSource.getUser('1');

      // Then
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.id, '1');
      expect(retrievedUser.name, 'Test User');
    });

    test('should return null when user not found', () async {
      // When
      final user = await dataSource.getUser('nonexistent');

      // Then
      expect(user, isNull);
    });

    test('should handle batch operations', () async {
      // Arrange
      final users = [
        UserDbModel(
          id: '1',
          name: 'User 1',
          email: 'user1@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UserDbModel(
          id: '2',
          name: 'User 2',
          email: 'user2@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      await dataSource.saveUsers(users);
      final result = await dataSource.getAllUsers();

      // Assert
      expect(result.length, equals(2));
      expect(result.map((u) => u.id), containsAll(['1', '2']));
    });

    test('should handle stream operations', () async {
      // Arrange
      final user = UserDbModel(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final stream = dataSource.watchAllUsers();
      await dataSource.saveUser(user);

      // Assert
      await expectLater(
        stream,
        emits(isA<List<UserDbModel>>()),
      );
    });
  });
}
```

### 2. SharedPreferencesデータソースのテスト

```dart
// test/features/settings/data/data_sources/local/settings_local_data_source_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../lib/features/settings/data/data_sources/local/settings_local_data_source_impl.dart';

void main() {
  late SettingsLocalDataSourceImpl dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    dataSource = SettingsLocalDataSourceImpl(prefs);
  });

  group('SettingsLocalDataSourceImpl', () {
    test('should save and retrieve string value', () async {
      // Arrange
      const key = 'test_key';
      const value = 'test_value';

      // Act
      await dataSource.setString(key, value);
      final result = await dataSource.getString(key);

      // Assert
      expect(result, equals(value));
    });

    test('should return null for non-existent key', () async {
      // Act
      final result = await dataSource.getString('non_existent_key');

      // Assert
      expect(result, isNull);
    });

    test('should handle boolean values', () async {
      // Arrange
      const key = 'bool_key';
      const value = true;

      // Act
      await dataSource.setBool(key, value);
      final result = await dataSource.getBool(key);

      // Assert
      expect(result, equals(value));
    });

    test('should clear all preferences', () async {
      // Arrange
      await dataSource.setString('key1', 'value1');
      await dataSource.setString('key2', 'value2');

      // Act
      await dataSource.clear();
      final result1 = await dataSource.getString('key1');
      final result2 = await dataSource.getString('key2');

      // Assert
      expect(result1, isNull);
      expect(result2, isNull);
    });
  });
}
```

### 3. ファイルシステムデータソースのテスト

```dart
// test/features/file/data/data_sources/local/file_local_data_source_impl_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import '../../../../../lib/features/file/data/data_sources/local/file_local_data_source_impl.dart';

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  late FileLocalDataSourceImpl dataSource;
  late Directory tempDir;

  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('test_');
    dataSource = FileLocalDataSourceImpl();
    await dataSource.initialize();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileLocalDataSourceImpl', () {
    test('should write and read text file', () async {
      // Arrange
      const fileName = 'test.txt';
      const content = 'Hello, World!';

      // Act
      await dataSource.writeTextFile(fileName, content);
      final result = await dataSource.readTextFile(fileName);

      // Assert
      expect(result, equals(content));
    });

    test('should handle JSON files', () async {
      // Arrange
      const fileName = 'test.json';
      final data = {'key': 'value', 'number': 42};

      // Act
      await dataSource.writeJsonFile(fileName, data);
      final result = await dataSource.readJsonFile(fileName);

      // Assert
      expect(result, equals(data));
    });

    test('should check file existence', () async {
      // Arrange
      const fileName = 'test.txt';
      const content = 'test content';

      // Act & Assert
      expect(await dataSource.fileExists(fileName), isFalse);
      
      await dataSource.writeTextFile(fileName, content);
      expect(await dataSource.fileExists(fileName), isTrue);
    });

    test('should delete file', () async {
      // Arrange
      const fileName = 'test.txt';
      const content = 'test content';
      await dataSource.writeTextFile(fileName, content);

      // Act
      await dataSource.deleteFile(fileName);

      // Assert
      expect(await dataSource.fileExists(fileName), isFalse);
    });
  });
}
```

## 依存性注入

### GetItを使用した登録例
```dart
// core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';

// インターフェース
import '../../features/user/data/data_sources/local/user_local_data_source.dart';
import '../../features/user/data/data_sources/local/settings_local_data_source.dart';
import '../../features/user/data/data_sources/local/file_local_data_source.dart';

// 実装クラス
import '../../features/user/data/data_sources/local/user_local_data_source_impl.dart';
import '../../features/user/data/data_sources/local/settings_local_data_source_impl.dart';
import '../../features/user/data/data_sources/local/file_local_data_source_impl.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Database
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  
  // Data Sources - インターフェースに対して実装クラスを登録
  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(sl<AppDatabase>()),
  );
  
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(sl<SharedPreferences>()),
  );
  
  sl.registerLazySingleton<FileLocalDataSource>(
    () => FileLocalDataSourceImpl(),
  );
}
```

### Riverpodを使用した登録例
```dart
// core/providers/local_data_source_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';

// インターフェース
import '../../features/user/data/data_sources/local/user_local_data_source.dart';
import '../../features/user/data/data_sources/local/settings_local_data_source.dart';
import '../../features/user/data/data_sources/local/file_local_data_source.dart';

// 実装クラス
import '../../features/user/data/data_sources/local/user_local_data_source_impl.dart';
import '../../features/user/data/data_sources/local/settings_local_data_source_impl.dart';
import '../../features/user/data/data_sources/local/file_local_data_source_impl.dart';

// Database Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// SharedPreferences Provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Local Data Source Providers
final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return UserLocalDataSourceImpl(database);
});

final settingsLocalDataSourceProvider = FutureProvider<SettingsLocalDataSource>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SettingsLocalDataSourceImpl(prefs);
});

final fileLocalDataSourceProvider = Provider<FileLocalDataSource>((ref) {
  return FileLocalDataSourceImpl();
});
```

## 注意事項

1. **パフォーマンス**: 大量データの処理時はバッチ操作やページネーションを使用
2. **エラーハンドリング**: データベースやファイルシステムの例外を適切にキャッチ
3. **データ整合性**: トランザクションを使用して一貫性を保証
4. **メモリ管理**: 大きなデータを扱う際はメモリリークに注意
5. **セキュリティ**: 機密データは適切に暗号化して保存
