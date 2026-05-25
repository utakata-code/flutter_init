# 実装フローサンプル

## フィーチャー: メモ管理機能の実装例

### 1. Model層

#### 1-1. エンティティ (`1_model/1_entities/memo_entity.dart`)
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'memo_entity.freezed.dart';
part 'memo_entity.g.dart';

/// メモエンティティ
/// メモのビジネスロジックで使用するデータ構造
@freezed
abstract class MemoEntity with _$MemoEntity {
  const factory MemoEntity({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MemoEntity;

  factory MemoEntity.fromJson(Map<String, dynamic> json) =>
      _$MemoEntityFromJson(json);
}
```

#### 1-2. リポジトリIF (`1_model/2_repositories/memo_repository.dart`)
```dart
import '../1_entities/memo_entity.dart';

/// メモリポジトリインターフェース
abstract interface class MemoRepository {
  Future<List<MemoEntity>> getAll();
  Future<MemoEntity?> getById(String id);
  Future<void> create(MemoEntity memo);
  Future<void> update(MemoEntity memo);
  Future<void> delete(String id);
}
```

#### 1-3. サービス (`1_model/3_services/memo_service.dart`)
```dart
import '../1_entities/memo_entity.dart';
import '../2_repositories/memo_repository.dart';

/// メモサービス — ビジネスロジックの集約
class MemoService {
  final MemoRepository _repository;

  const MemoService({required MemoRepository repository})
      : _repository = repository;

  Future<List<MemoEntity>> fetchAll() => _repository.getAll();

  Future<void> create({
    required String title,
    required String content,
  }) async {
    final now = DateTime.now();
    final memo = MemoEntity(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.create(memo);
  }
}
```

### 2. ViewModel層

#### 2-1. ノティファイア (`2_viewmodel/2_notifiers/memo_notifier.dart`)
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../1_states/memo_state.dart';
import '../../1_model/3_services/memo_service.dart';

part 'memo_notifier.g.dart';

/// メモ状態管理ノティファイア
@riverpod
class MemoNotifier extends _$MemoNotifier {
  late final MemoService _service;

  @override
  MemoState build() {
    _service = ref.read(memoServiceProvider);
    return const MemoState.initial();
  }

  /// メモ一覧を読み込み
  Future<void> loadMemos() async {
    state = const MemoState.loading();
    try {
      final memos = await _service.fetchAll();
      state = MemoState.loaded(memos: memos);
    } catch (e) {
      state = MemoState.error(message: e.toString());
    }
  }

  /// メモを追加
  Future<void> addMemo({
    required String title,
    required String content,
  }) async {
    await _service.create(title: title, content: content);
    await loadMemos();
  }
}
```

### 3. View層

#### 3-1. 画面 (`3_view/2_screens/memo_list_screen.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../2_viewmodel/2_notifiers/memo_notifier.dart';
import '../1_widgets/memo_card_widget.dart';

/// メモ一覧画面
class MemoListScreen extends ConsumerWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('メモ一覧')),
      body: switch (state) {
        MemoState.initial() => const Center(
            child: Text('読み込みを開始してください'),
          ),
        MemoState.loading() => const Center(
            child: CircularProgressIndicator(),
          ),
        MemoState.loaded(:final memos) => ListView.builder(
            itemCount: memos.length,
            itemBuilder: (context, index) => MemoCardWidget(
              memo: memos[index],
            ),
          ),
        MemoState.error(:final message) => Center(
            child: Text('エラー: $message'),
          ),
      },
    );
  }
}
```

## 実装完了後

```bash
# コード生成
dart run build_runner build --delete-conflicting-outputs

# 静的解析
flutter analyze

# ステータス更新
/status report
```
