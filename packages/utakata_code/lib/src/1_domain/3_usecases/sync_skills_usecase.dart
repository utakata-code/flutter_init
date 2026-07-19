import '../1_entities/config/utakata_config_entity.dart';
import '../2_repositories/config_repository.dart';
import '../2_repositories/plan_repository.dart';
import '../services/content_hash.dart';

/// 同期結果(表示用)。
class SyncSkillsResult {
  final List<String> synced;
  final List<String> skippedUnmanaged;
  final List<String> skippedModified;
  final List<String> notFound;
  final List<String> removalCandidates;

  const SyncSkillsResult({
    this.synced = const [],
    this.skippedUnmanaged = const [],
    this.skippedModified = const [],
    this.notFound = const [],
    this.removalCandidates = const [],
  });
}

/// `utakata skills sync` — アーキテクチャ同梱 SKILL を `.claude/skills/` へ
/// managed マーカー方式で同期する(実装計画 S4 / D4)。
///
/// 競合規則:
///   - マーカーの無い既存ファイルは**絶対に**上書きしない(--force でも)
///   - マーカー有り+本文ハッシュ一致(未編集の managed) → 更新する
///   - マーカー有り+ハッシュ不一致(人間が編集済み) → スキップ。--force でのみ上書き
class SyncSkillsUsecase {
  static final _markerPattern =
      RegExp(r'<!-- utakata:managed from=([^ ]+) hash=([0-9a-f]+) -->\n?');

  final ConfigRepository _configRepo;
  final PlanRepository? _planRepo;
  final Future<String> Function(String relativePath) _resolveTemplatePath;
  final Future<String?> Function(String path) _readFile;
  final Future<void> Function(String path, String content) _writeFile;
  final Future<void> Function(String path) _ensureDir;
  final bool Function(String path) _dirExists;
  final List<String> Function(String dirPath) _listEntries;

  const SyncSkillsUsecase({
    required ConfigRepository configRepo,
    PlanRepository? planRepo,
    required Future<String> Function(String relativePath) resolveTemplatePath,
    required Future<String?> Function(String path) readFile,
    required Future<void> Function(String path, String content) writeFile,
    required Future<void> Function(String path) ensureDir,
    required bool Function(String path) dirExists,
    required List<String> Function(String dirPath) listEntries,
  })  : _configRepo = configRepo,
        _planRepo = planRepo,
        _resolveTemplatePath = resolveTemplatePath,
        _readFile = readFile,
        _writeFile = writeFile,
        _ensureDir = ensureDir,
        _dirExists = dirExists,
        _listEntries = listEntries;

  Future<SyncSkillsResult> execute(String projectDir, {bool force = false}) async {
    final config = await _configRepo.read(projectDir) ?? const UtakataConfig();
    final archId = config.architecture ??
        (await _planRepo?.read(projectDir))?.defaultArchitectureId ??
        'clean_architecture';

    final synced = <String>[];
    final skippedUnmanaged = <String>[];
    final skippedModified = <String>[];
    final notFound = <String>[];

    final skillsRoot = await _resolveTemplatePath('architectures/$archId/skills');

    for (final skillId in config.skills) {
      final sourceDir = '$skillsRoot/$skillId';
      if (!_dirExists(sourceDir)) {
        notFound.add(skillId);
        continue;
      }
      for (final fileName in _listEntries(sourceDir)) {
        final sourceContent = await _readFile('$sourceDir/$fileName');
        if (sourceContent == null) continue; // サブディレクトリ等はスキップ

        final targetPath = '$projectDir/.claude/skills/$skillId/$fileName';
        final label = '$skillId/$fileName';
        final marker = '<!-- utakata:managed from=$archId/$skillId '
            'hash=${ContentHash.fnv1a(sourceContent)} -->\n';

        final existing = await _readFile(targetPath);
        if (existing != null) {
          final match = _markerPattern.firstMatch(existing);
          if (match == null) {
            // 人間が作ったファイル: --force でも触らない(D4)
            skippedUnmanaged.add(label);
            continue;
          }
          final body = existing.replaceFirst(_markerPattern, '');
          final unmodified = ContentHash.fnv1a(body) == match.group(2);
          if (!unmodified && !force) {
            skippedModified.add(label);
            continue;
          }
        }

        await _ensureDir('$projectDir/.claude/skills/$skillId');
        await _writeFile(targetPath, marker + sourceContent);
        synced.add(label);
      }
    }

    return SyncSkillsResult(
      synced: synced,
      skippedUnmanaged: skippedUnmanaged,
      skippedModified: skippedModified,
      notFound: notFound,
      removalCandidates: await _findRemovalCandidates(projectDir, config, archId),
    );
  }

  /// skills リストから外されたが .claude/skills/ に残っている managed スキルを
  /// 削除候補として列挙する(自動削除はしない)。
  Future<List<String>> _findRemovalCandidates(
      String projectDir, UtakataConfig config, String archId) async {
    final skillsDir = '$projectDir/.claude/skills';
    if (!_dirExists(skillsDir)) return const [];
    final candidates = <String>[];
    for (final entry in _listEntries(skillsDir)) {
      if (config.skills.contains(entry)) continue;
      if (!_dirExists('$skillsDir/$entry')) continue;
      // ディレクトリ内に「このアーキテクチャ由来の managed マーカー」があるか
      for (final fileName in _listEntries('$skillsDir/$entry')) {
        final content = await _readFile('$skillsDir/$entry/$fileName');
        if (content != null &&
            content.contains('<!-- utakata:managed from=$archId/$entry ')) {
          candidates.add(entry);
          break;
        }
      }
    }
    return candidates;
  }
}
