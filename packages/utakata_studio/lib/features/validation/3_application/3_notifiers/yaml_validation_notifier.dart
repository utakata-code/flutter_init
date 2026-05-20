import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/yaml_validation_result_entity.dart';
import '../../1_domain/3_usecases/validate_yaml_usecase.dart';

/// YAML バリデーション状態
class YamlValidationState {
  final YamlValidationResult? result;
  final bool isLoading;
  final String? filePath;

  const YamlValidationState({
    this.result,
    this.isLoading = true,
    this.filePath,
  });

  bool get isValid => result?.isValid ?? false;
  String get yamlContent => result?.yamlContent ?? '';
  String? get errorMessage => result?.errorMessage;
}

/// YAML バリデーションを管理するノティファイア
class YamlValidationNotifier extends StateNotifier<YamlValidationState> {
  final ValidateYamlUsecase _usecase;
  final String _projectRoot;

  YamlValidationNotifier(this._usecase, this._projectRoot)
      : super(const YamlValidationState());

  /// ファイルから YAML をロードしてバリデーション実行
  Future<void> loadFromFile(String relativePath) async {
    final fullPath = p.join(_projectRoot, relativePath);
    state = YamlValidationState(isLoading: true, filePath: fullPath);
    try {
      final file = File(fullPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final result = _usecase.execute(content);
        state = YamlValidationState(
          result: result,
          isLoading: false,
          filePath: fullPath,
        );
      } else {
        state = YamlValidationState(
          result: YamlValidationResult(
            yamlContent: '',
            isValid: false,
            errorMessage: 'arch_definition.yaml が見つかりません。\n'
                'パス: $fullPath\n'
                'プロジェクトルート: $_projectRoot',
          ),
          isLoading: false,
          filePath: fullPath,
        );
      }
    } catch (e) {
      state = YamlValidationState(
        result: YamlValidationResult(
          yamlContent: '',
          isValid: false,
          errorMessage: 'ファイル読み込みエラー:\n$e',
        ),
        isLoading: false,
        filePath: fullPath,
      );
    }
  }

  /// テキスト入力のリアルタイムバリデーション
  void validateText(String yamlStr) {
    final result = _usecase.execute(yamlStr);
    state = YamlValidationState(
      result: result,
      isLoading: false,
      filePath: state.filePath,
    );
  }

  /// ファイルに保存
  Future<void> saveToFile(String content) async {
    final path = state.filePath;
    if (path == null) return;
    try {
      await File(path).writeAsString(content);
      validateText(content);
    } catch (e) {
      // 保存失敗時は状態を変えない
    }
  }
}
