import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:utakata/utakata.dart';

part 'layer_visualizer_state.freezed.dart';

/// レイヤービジュアライザの状態
@freezed
sealed class LayerVisualizerState with _$LayerVisualizerState {
  /// 初期状態
  const factory LayerVisualizerState.initial() = LayerVisualizerStateInitial;

  /// データ読み込み完了状態
  const factory LayerVisualizerState.loaded({
    required List<LayerDefinitionEntity> layers,
  }) = LayerVisualizerStateLoaded;
}
