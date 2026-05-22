import 'dart:io';
import '../../1_domain/2_repositories/validation_repository.dart';
import '../2_data_sources/1_local/yaml_file_watcher_data_source.dart';

/// バリデーションリポジトリの実装
class ValidationRepositoryImpl implements ValidationRepository {
  final YamlFileWatcherDataSource _watcher;
  const ValidationRepositoryImpl(this._watcher);

  @override
  Future<String> readYamlFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    return file.readAsString();
  }

  @override
  Stream<void> watchFile(String filePath) => _watcher.watch(filePath);
}
