import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utakata/utakata.dart';
import '../../1_domain/3_usecases/build_layer_tree_usecase.dart';
import '../1_states/layer_visualizer_state.dart';
import '../2_providers/layer_visualizer_providers.dart';

/// レイヤービジュアライザの状態管理 Notifier
class LayerVisualizerNotifier extends StateNotifier<LayerVisualizerState> {
  final BuildLayerTreeUsecase _usecase;

  LayerVisualizerNotifier(this._usecase)
      : super(const LayerVisualizerState.initial());

  /// レイヤーデータを更新する
  void updateLayers(List<LayerDefinitionEntity> layers) {
    final tree = _usecase(layers);
    state = LayerVisualizerState.loaded(layers: tree);
  }
}

final layerVisualizerNotifierProvider =
    StateNotifierProvider<LayerVisualizerNotifier, LayerVisualizerState>(
  (ref) =>
      LayerVisualizerNotifier(ref.read(buildLayerTreeUsecaseProvider)),
);
