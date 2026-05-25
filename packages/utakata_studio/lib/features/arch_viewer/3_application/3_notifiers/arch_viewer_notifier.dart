import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../1_domain/3_usecases/load_arch_definition_usecase.dart';
import '../1_states/arch_viewer_state.dart';
import '../2_providers/arch_viewer_providers.dart';

/// アーキテクチャビューアの状態管理 Notifier
class ArchViewerNotifier extends StateNotifier<ArchViewerState> {
  final LoadArchDefinitionUsecase _usecase;

  ArchViewerNotifier(this._usecase)
      : super(const ArchViewerState.initial());

  /// プロジェクトルートを指定してロード
  Future<void> load(String projectRoot) async {
    state = ArchViewerState.loading(projectRoot: projectRoot);
    try {
      final result = await _usecase(projectRoot);
      state = ArchViewerState.loaded(
        result: result,
        projectRoot: projectRoot,
      );
    } catch (e) {
      state = ArchViewerState.error(
        message: e.toString(),
        projectRoot: projectRoot,
      );
    }
  }

  /// 手動リロード
  Future<void> reload() async {
    final root = state.mapOrNull(
      loading: (s) => s.projectRoot,
      loaded: (s) => s.projectRoot,
      error: (s) => s.projectRoot,
    );
    if (root != null) await load(root);
  }
}

final archViewerNotifierProvider =
    StateNotifierProvider<ArchViewerNotifier, ArchViewerState>(
  (ref) => ArchViewerNotifier(ref.read(loadArchDefinitionUsecaseProvider)),
);
