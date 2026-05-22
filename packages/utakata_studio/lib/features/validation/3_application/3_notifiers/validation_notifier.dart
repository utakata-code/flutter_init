import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../1_domain/2_repositories/validation_repository.dart';
import '../../1_domain/3_usecases/validate_yaml_usecase.dart';
import '../1_states/validation_state.dart';
import '../2_providers/validation_providers.dart';

/// バリデーション状態管理 + ファイル変更検知
class ValidationNotifier extends StateNotifier<ValidationState> {
  final ValidateYamlUsecase _usecase;
  final ValidationRepository _repository;
  StreamSubscription<void>? _watcher;

  ValidationNotifier(this._usecase, this._repository)
      : super(const ValidationState.initial());

  /// YAML をロードし、バリデーションを実行する
  Future<void> loadAndValidate(String filePath) async {
    state = ValidationState.loading(filePath: filePath);
    await _validate(filePath);
    _startWatching(filePath);
  }

  Future<void> _validate(String filePath) async {
    try {
      final content = await _repository.readYamlFile(filePath);
      final result = _usecase(content);
      state = ValidationState.loaded(result: result, filePath: filePath);
    } on FileSystemException {
      state = ValidationState.error(
        message: 'ファイルが見つかりません: $filePath',
        filePath: filePath,
      );
    } catch (e) {
      state = ValidationState.error(
        message: e.toString(),
        filePath: filePath,
      );
    }
  }

  void _startWatching(String filePath) {
    _watcher?.cancel();
    _watcher = _repository.watchFile(filePath).listen((_) {
      _validate(filePath);
    });
  }

  /// 手動リロード
  Future<void> reload() async {
    final path = state.mapOrNull(
      loading: (s) => s.filePath,
      loaded: (s) => s.filePath,
      error: (s) => s.filePath,
    );
    if (path != null) await _validate(path);
  }

  @override
  void dispose() {
    _watcher?.cancel();
    super.dispose();
  }
}

final validationNotifierProvider =
    StateNotifierProvider<ValidationNotifier, ValidationState>(  (ref) => ValidationNotifier(
    ref.read(validateYamlUsecaseProvider),
    ref.read(validationRepositoryProvider),
  ),
);
