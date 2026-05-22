import 'dart:async';
import 'dart:io';

/// YAML ファイルの変更を監視するデータソース
class YamlFileWatcherDataSource {
  StreamSubscription<FileSystemEvent>? _subscription;

  /// ファイルの親ディレクトリを監視し、対象ファイルの変更イベントを返す
  Stream<void> watch(String filePath) {
    final controller = StreamController<void>.broadcast();
    try {
      final file = File(filePath);
      final parent = file.parent;
      if (parent.existsSync()) {
        _subscription = parent.watch().listen((event) {
          if (event.path == filePath ||
              event.path.endsWith(file.uri.pathSegments.last)) {
            controller.add(null);
          }
        });
      }
    } catch (_) {
      // Web 等のファイル監視非対応プラットフォームでは無視
    }
    return controller.stream;
  }

  /// 監視を停止する
  void dispose() {
    _subscription?.cancel();
  }
}
