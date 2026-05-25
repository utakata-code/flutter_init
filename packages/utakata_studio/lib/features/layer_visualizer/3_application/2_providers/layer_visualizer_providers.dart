import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../1_domain/3_usecases/build_layer_tree_usecase.dart';

/// レイヤービジュアライザの DI プロバイダ
final buildLayerTreeUsecaseProvider = Provider<BuildLayerTreeUsecase>(
  (ref) => const BuildLayerTreeUsecase(),
);
