import '../1_entities/architecture_definition_entity.dart';
import '../2_repositories/config_repository.dart';
import '../2_repositories/plan_repository.dart';
import '../2_repositories/architecture_repository.dart';

/// 解決結果。
class GuideForFileResult {
  final String layerPath;
  final String guide;

  const GuideForFileResult({required this.layerPath, required this.guide});
}

/// `utakata guide for <file>` — ファイルパスから該当レイヤーのガイドを
/// 決定論的に解決する(実装計画 S5 / v1.0.0 ロードマップC)。
///
/// lint エラーの発生ファイルをそのまま渡すと、修正時に参照すべきガイドが
/// 返る。AI エージェントの修正コンテキスト供給が主用途。
class GuideForFileUsecase {
  final ArchitectureRepository _archRepo;
  final ConfigRepository _configRepo;
  final PlanRepository? _planRepo;
  final Future<String> Function(String architectureId, String layerPath) _showGuide;

  const GuideForFileUsecase({
    required ArchitectureRepository archRepo,
    required ConfigRepository configRepo,
    PlanRepository? planRepo,
    required Future<String> Function(String architectureId, String layerPath) showGuide,
  })  : _archRepo = archRepo,
        _configRepo = configRepo,
        _planRepo = planRepo,
        _showGuide = showGuide;

  static const _permissionDirs = {'admin', 'user', 'shared'};

  Future<GuideForFileResult?> execute(String projectDir, String filePath) async {
    final archId = (await _configRepo.read(projectDir))?.architecture ??
        (await _planRepo?.read(projectDir))?.defaultArchitectureId ??
        'clean_architecture';
    final arch = await _archRepo.getById(archId);

    final layerPath = layerPathOf(filePath);
    if (layerPath == null) return null;

    final guide = _bestMatch(arch, layerPath);
    if (guide == null) return null;

    return GuideForFileResult(
      layerPath: guide,
      guide: await _showGuide(archId, guide),
    );
  }

  /// `lib/features/{permission}/{feature}/<layer...>/file.dart` から
  /// feature 相対のレイヤーパス(`1_domain/1_entities` 等)を取り出す。
  /// features 外・直下ファイルは null。
  static String? layerPathOf(String filePath) {
    final normalized = filePath.replaceAll('\\', '/');
    final marker = normalized.indexOf('lib/features/');
    if (marker < 0) return null;
    final segments = normalized
        .substring(marker + 'lib/features/'.length)
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    // permission ディレクトリは admin/user/shared のみ。それ以外は direct
    // (feature が features/ 直下)として 1 段だけ飛ばす。
    final skip = segments.isNotEmpty && _permissionDirs.contains(segments.first) ? 2 : 1;
    if (segments.length <= skip + 1) return null; // レイヤー未満(feature直下ファイル等)
    final layerSegments = segments.sublist(skip, segments.length - 1);
    return layerSegments.join('/');
  }

  /// ガイドの layerPath と前方一致し、最も深く一致するものを選ぶ
  /// (`1_domain/1_entities` はファイルが `1_domain/1_entities/sub/` に
  /// あっても当たる。見つからなければレイヤー先頭 1 段で再試行)。
  String? _bestMatch(ArchitectureDefinitionEntity arch, String layerPath) {
    String? best;
    for (final guide in arch.guides) {
      if (layerPath == guide.layerPath ||
          layerPath.startsWith('${guide.layerPath}/')) {
        if (best == null || guide.layerPath.length > best.length) {
          best = guide.layerPath;
        }
      }
    }
    return best;
  }
}
