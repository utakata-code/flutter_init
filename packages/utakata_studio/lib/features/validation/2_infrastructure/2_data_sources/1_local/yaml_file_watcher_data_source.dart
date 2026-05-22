import 'dart:async';
import 'dart:io';

/// YAML ファイルの変更を監視するデータソース
///
/// 親ディレクトリを `FileSystemEntity.watch` で監視し、
/// 対象ファイルの変更イベントをデバウンスして通知する。
class YamlFileWatcherDataSource {
  StreamSubscription<FileSystemEvent>? _subscription;

  /// ファイルの親ディレクトリを監視し、対象ファイルの変更イベントを返す
  ///
  /// デバウンス（500ms）付きで、連続的なファイル保存イベントを集約する。
  Stream<void> watch(String filePath) {
    final controller = StreamController<void>.broadcast();
    Timer? debounceTimer;

    try {
      final file = File(filePath);
      final parent = file.parent;
      if (parent.existsSync()) {
        _subscription?.cancel();
        _subscription = parent.watch().listen((event) {
          if (event.path == filePath ||
              event.path.endsWith(file.uri.pathSegments.last)) {
            // デバウンス: 500ms 以内の連続イベントを集約
            debounceTimer?.cancel();
            debounceTimer = Timer(const Duration(milliseconds: 500), () {
              controller.add(null);
            });
          }
        });
      }
    } catch (_) {
      // Web 等のファイル監視非対応プラットフォームでは無視
    }

    controller.onCancel = () {
      debounceTimer?.cancel();
    };

    return controller.stream;
  }

  /// 監視を停止する
  void dispose() {
    _subscription?.cancel();
  }
}
