import 'package:utakata/utakata.dart';

/// レイヤービジュアライザのリポジトリインターフェース
///
/// パース済みレイヤー情報の取得を抽象化する。
abstract interface class LayerVisualRepository {
  /// パース済みレイヤーリストを取得する
  List<LayerDefinitionEntity> getLayers();
}
