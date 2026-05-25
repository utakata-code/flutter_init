import 'package:utakata/utakata.dart';
import '../../1_domain/2_repositories/layer_visual_repository.dart';

/// レイヤービジュアルリポジトリの実装
///
/// validation のパース結果からレイヤーデータを取得するため、
/// コンストラクタでレイヤーリストを受け取る。
class LayerVisualRepositoryImpl implements LayerVisualRepository {
  final List<LayerDefinitionEntity> _layers;
  const LayerVisualRepositoryImpl(this._layers);

  @override
  List<LayerDefinitionEntity> getLayers() => _layers;
}
