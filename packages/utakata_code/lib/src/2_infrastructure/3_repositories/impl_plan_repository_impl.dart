import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/record/impl_plan_meta.dart';
import '../../1_domain/2_repositories/impl_plan_repository.dart';
import '../../1_domain/services/impl_lane.dart';
import '../1_models/impl_plan_front_matter_model.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';
import '../2_data_sources/1_local/front_matter_data_source.dart';

/// 実装計画をレーン別ディレクトリ(`doc/impl/<lane>/`)で扱う実装。
///
/// v1.6.x までのフラット配置(`doc/impl/*.md`)も読み取れる — 移行前の
/// プロジェクトで `list` が空になるのを避けるため。配置の是正は
/// `utakata impl sync` / `utakata doctor --migrate` が行う。
class ImplPlanRepositoryImpl implements ImplPlanRepository {
  final FilesystemDataSource _fs;
  final FrontMatterDataSource _frontMatter;

  const ImplPlanRepositoryImpl(this._fs, this._frontMatter);

  static const _implDir = 'doc/impl';

  String _fileName(String id, String feature) => '${id}_$feature.md';

  /// 走査対象ディレクトリ(`doc/impl` 直下 + 各レーン)。
  List<String> _searchDirs(String projectDir) => [
        p.join(projectDir, _implDir),
        for (final lane in ImplLane.values)
          p.join(projectDir, _implDir, lane.dirName),
      ];

  /// 見つかった全計画を「プロジェクト相対パス → メタ」で返す。
  Future<Map<String, ImplPlanMeta>> _scan(String projectDir) async {
    final result = <String, ImplPlanMeta>{};
    for (final dir in _searchDirs(projectDir)) {
      for (final entry in _fs.listEntries(dir)) {
        if (!entry.endsWith('.md')) continue;
        final fullPath = p.join(dir, entry);
        final content = await _fs.readFile(fullPath);
        if (content == null) continue;
        final parsed = _frontMatter.parse(content);
        if (parsed.frontMatter.isEmpty) continue;
        final ImplPlanMeta meta;
        try {
          meta = ImplPlanFrontMatterModel.fromMap(parsed.frontMatter);
        } catch (_) {
          continue; // frontmatter が壊れている計画は一覧から外す
        }
        result[p.relative(fullPath, from: projectDir)] = meta;
      }
    }
    return result;
  }

  String _expectedRelativePath(ImplPlanMeta meta) => p.join(
        _implDir,
        ImplLane.ofMeta(meta).dirName,
        _fileName(meta.id, meta.feature),
      );

  @override
  Future<String> nextId(String projectDir) async {
    final all = await _scan(projectDir);
    final pattern = RegExp(r'^PLAN-(\d+)$');
    var maxSeq = 0;
    for (final meta in all.values) {
      final match = pattern.firstMatch(meta.id);
      if (match == null) continue;
      final seq = int.parse(match.group(1)!);
      if (seq > maxSeq) maxSeq = seq;
    }
    return 'PLAN-${(maxSeq + 1).toString().padLeft(4, '0')}';
  }

  @override
  Future<void> create(String projectDir, ImplPlanMeta meta, String body) async {
    final content = _frontMatter.render(ImplPlanFrontMatterModel.toMap(meta), body);
    await _fs.writeFile(
        p.join(projectDir, _expectedRelativePath(meta)), content);
  }

  @override
  Future<List<ImplPlanMeta>> listAll(String projectDir) async {
    final all = (await _scan(projectDir)).values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return all;
  }

  @override
  Future<ImplPlanMeta?> findById(String projectDir, String id) async {
    final all = await _scan(projectDir);
    for (final meta in all.values) {
      if (meta.id == id) return meta;
    }
    return null;
  }

  @override
  Future<String?> update(String projectDir, ImplPlanMeta meta) async {
    final all = await _scan(projectDir);
    String? currentRelative;
    for (final entry in all.entries) {
      if (entry.value.id == meta.id) {
        currentRelative = entry.key;
        break;
      }
    }
    if (currentRelative == null) {
      throw StateError('Implementation plan "${meta.id}" not found');
    }

    final currentPath = p.join(projectDir, currentRelative);
    final content = await _fs.readFile(currentPath);
    if (content == null) {
      throw StateError('Implementation plan "${meta.id}" is unreadable');
    }
    // 本文には触れず frontmatter だけ差し替える
    final parsed = _frontMatter.parse(content);
    final updated =
        _frontMatter.render(ImplPlanFrontMatterModel.toMap(meta), parsed.body);
    await _fs.writeFile(currentPath, updated);

    final expectedRelative = _expectedRelativePath(meta);
    if (expectedRelative == currentRelative) return null;
    await _fs.movePath(currentPath, p.join(projectDir, expectedRelative));
    return expectedRelative;
  }

  @override
  Future<Map<String, ({String actual, String expected})>> detectMisplaced(
      String projectDir) async {
    final all = await _scan(projectDir);
    final result = <String, ({String actual, String expected})>{};
    for (final entry in all.entries) {
      final expected = _expectedRelativePath(entry.value);
      if (entry.key != expected) {
        result[entry.value.id] = (actual: entry.key, expected: expected);
      }
    }
    return result;
  }

  @override
  Future<List<String>> sync(String projectDir, {bool dryRun = false}) async {
    final misplaced = await detectMisplaced(projectDir);
    final moved = <String>[];
    for (final entry in misplaced.entries) {
      if (!dryRun) {
        await _fs.movePath(
          p.join(projectDir, entry.value.actual),
          p.join(projectDir, entry.value.expected),
        );
      }
      moved.add(entry.key);
    }
    moved.sort();
    return moved;
  }
}
