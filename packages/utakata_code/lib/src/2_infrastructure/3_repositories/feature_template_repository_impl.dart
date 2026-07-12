import 'dart:io';

import 'package:path/path.dart' as p;

import '../../1_domain/2_repositories/feature_template_repository.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';
import '../2_data_sources/1_local/yaml_data_source.dart';

/// 解決順: project(`.utakata/feature_templates/`) → user(`~/.utakata/feature_templates/`)
/// → パッケージ内蔵(v1.0 時点では未同梱)。
class FeatureTemplateRepositoryImpl implements FeatureTemplateRepository {
  final FilesystemDataSource _fs;
  final YamlDataSource _yaml;

  const FeatureTemplateRepositoryImpl(this._fs, this._yaml);

  @override
  Future<FeatureTemplateManifest?> resolve(String projectDir, String templateId) async {
    final candidates = [
      p.join(projectDir, '.utakata', 'feature_templates', templateId, 'manifest.yaml'),
      p.join(_userHome(), '.utakata', 'feature_templates', templateId, 'manifest.yaml'),
    ];

    for (final path in candidates) {
      final content = await _fs.readFile(path);
      if (content == null) continue;
      final doc = _yaml.parse(content, source: path);
      return FeatureTemplateManifest(
        id: templateId,
        permission: (doc['permission'] as String?) ?? 'user',
        entities: (doc['entities'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
    }
    return null;
  }

  String _userHome() =>
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
}
