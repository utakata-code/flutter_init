/// レイヤービジュアライザ関連の例外
class LayerVisualizerException implements Exception {
  final String message;
  const LayerVisualizerException(this.message);

  @override
  String toString() => 'LayerVisualizerException: $message';
}
