import 'package:utakata/utakata.dart';

/// レイヤーリストからツリー構造を構築するユースケース
class BuildLayerTreeUsecase {
  const BuildLayerTreeUsecase();

  /// 依存方向付きのレイヤーツリーを構築する
  /// （上位レイヤーから下位レイヤーへの依存方向）
  List<LayerDefinitionEntity> call(List<LayerDefinitionEntity> layers) {
    // 現状はそのまま返す（将来：依存関係の分析・フィルタ等を追加）
    return List.unmodifiable(layers);
  }
}
