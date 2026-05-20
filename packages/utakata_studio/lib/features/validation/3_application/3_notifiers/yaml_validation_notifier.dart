import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  YamlValidationNotifier(this._usecase)
      : super(const YamlValidationState());

  /// ファイルから YAML をロードしてバリデーション実行
  Future<void> loadFromFile(String filePath) async {
    state = YamlValidationState(isLoading: true, filePath: filePath);
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final result = _usecase.execute(content);
        state = YamlValidationState(
          result: result,
          isLoading: false,
          filePath: filePath,
        );
      } else {
        state = YamlValidationState(
          result: const YamlValidationResult(
            yamlContent: '',
            isValid: false,
            errorMessage: 'arch_definition.yaml が見つかりません。',
          ),
          isLoading: false,
          filePath: filePath,
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
        filePath: filePath,
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
