import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/record/impl_plan_meta.dart';
import '../../1_domain/2_repositories/impl_plan_repository.dart';
import '../1_models/impl_plan_front_matter_model.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';
import '../2_data_sources/1_local/front_matter_data_source.dart';

class ImplPlanRepositoryImpl implements ImplPlanRepository {
  final FilesystemDataSource _fs;
  final FrontMatterDataSource _frontMatter;

  const ImplPlanRepositoryImpl(this._fs, this._frontMatter);

  static const _implDir = 'doc/impl';

  String _fileName(String id, String feature) => '${id}_$feature.md';

  Future<Map<String, String>> _indexByFile(String projectDir) async {
    // fileName -> full content, only under doc/impl/ (not archive/)
    final dir = p.join(projectDir, _implDir);
    final result = <String, String>{};
    for (final entry in _fs.listEntries(dir)) {
      if (!entry.endsWith('.md')) continue;
      final content = await _fs.readFile(p.join(dir, entry));
      if (content != null) result[entry] = content;
    }
    return result;
  }

  @override
  Future<String> nextId(String projectDir) async {
    final all = await listAll(projectDir);
    final pattern = RegExp(r'^PLAN-(\d+)$');
    var maxSeq = 0;
    for (final meta in all) {
      final match = pattern.firstMatch(meta.id);
      if (match != null) {
        final seq = int.parse(match.group(1)!);
        if (seq > maxSeq) maxSeq = seq;
      }
    }
    return 'PLAN-${(maxSeq + 1).toString().padLeft(4, '0')}';
  }

  @override
  Future<void> create(String projectDir, ImplPlanMeta meta, String body) async {
    final content = _frontMatter.render(ImplPlanFrontMatterModel.toMap(meta), body);
    final path = p.join(projectDir, _implDir, _fileName(meta.id, meta.feature));
    await _fs.writeFile(path, content);
  }

  @override
  Future<List<ImplPlanMeta>> listAll(String projectDir) async {
    final index = await _indexByFile(projectDir);
    final result = <ImplPlanMeta>[];
    for (final content in index.values) {
      final parsed = _frontMatter.parse(content);
      if (parsed.frontMatter.isEmpty) continue;
      result.add(ImplPlanFrontMatterModel.fromMap(parsed.frontMatter));
    }
    result.sort((a, b) => a.id.compareTo(b.id));
    return result;
  }

  @override
  Future<ImplPlanMeta?> findById(String projectDir, String id) async {
    final all = await listAll(projectDir);
    try {
      return all.firstWhere((m) => m.id == id);
    } on StateError {
      return null;
    }
  }

  Future<String?> _findFileNameById(String projectDir, String id) async {
    final index = await _indexByFile(projectDir);
    for (final entry in index.entries) {
      final parsed = _frontMatter.parse(entry.value);
      if (parsed.frontMatter['id'] == id) return entry.key;
    }
    return null;
  }

  @override
  Future<void> updateStatus(
    String projectDir,
    String id,
    ImplPlanStatus status, {
    DateTime? completedOn,
  }) async {
    final fileName = await _findFileNameById(projectDir, id);
    if (fileName == null) {
      throw StateError('Implementation plan "$id" not found');
    }
    final path = p.join(projectDir, _implDir, fileName);
    final content = await _fs.readFile(path);
    if (content == null) return;

    final parsed = _frontMatter.parse(content);
    final meta = ImplPlanFrontMatterModel.fromMap(parsed.frontMatter)
        .copyWith(status: status, completedOn: completedOn);
    final updated = _frontMatter.render(ImplPlanFrontMatterModel.toMap(meta), parsed.body);
    await _fs.writeFile(path, updated);
  }

  @override
  Future<void> archive(String projectDir, String id) async {
    final fileName = await _findFileNameById(projectDir, id);
    if (fileName == null) {
      throw StateError('Implementation plan "$id" not found');
    }
    await _fs.movePath(
      p.join(projectDir, _implDir, fileName),
      p.join(projectDir, _implDir, 'archive', fileName),
    );
  }
}
