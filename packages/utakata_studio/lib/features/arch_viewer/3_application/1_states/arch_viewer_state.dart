import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../validation/1_domain/1_entities/validation_result_entity.dart';

part 'arch_viewer_state.freezed.dart';

/// アーキテクチャビューアの状態
@freezed
sealed class ArchViewerState with _$ArchViewerState {
  /// 初期状態
  const factory ArchViewerState.initial() = ArchViewerStateInitial;

  /// ローディング状態
  const factory ArchViewerState.loading({String? projectRoot}) =
      ArchViewerStateLoading;

  /// データ読み込み完了状態
  const factory ArchViewerState.loaded({
    required ValidationResultEntity result,
    required String projectRoot,
  }) = ArchViewerStateLoaded;

  /// エラー状態
  const factory ArchViewerState.error({
    required String message,
    String? projectRoot,
  }) = ArchViewerStateError;
}
