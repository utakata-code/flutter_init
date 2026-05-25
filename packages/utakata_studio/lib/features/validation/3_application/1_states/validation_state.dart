import 'package:freezed_annotation/freezed_annotation.dart';
import '../../1_domain/1_entities/validation_result_entity.dart';

part 'validation_state.freezed.dart';

/// バリデーションの状態
@freezed
sealed class ValidationState with _$ValidationState {
  /// 初期状態
  const factory ValidationState.initial() = ValidationStateInitial;

  /// ローディング状態
  const factory ValidationState.loading({String? filePath}) =
      ValidationStateLoading;

  /// データ読み込み完了状態
  const factory ValidationState.loaded({
    required ValidationResultEntity result,
    required String filePath,
  }) = ValidationStateLoaded;

  /// エラー状態
  const factory ValidationState.error({
    required String message,
    String? filePath,
  }) = ValidationStateError;
}
