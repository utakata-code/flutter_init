import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/record/agreement.dart';
import '../../1_domain/2_repositories/agreement_repository.dart';
import '../1_models/agreement_event_model.dart';
import '../2_data_sources/1_local/jsonl_data_source.dart';

class AgreementRepositoryImpl implements AgreementRepository {
  final JsonlDataSource _jsonl;

  const AgreementRepositoryImpl(this._jsonl);

  static const _path = 'doc/records/agreements.jsonl';

  String _fullPath(String projectDir) => p.join(projectDir, _path);

  Future<List<AgreementEvent>> _readAllEvents(String projectDir) async {
    final records = await _jsonl.readAll(_fullPath(projectDir));
    return records.map(AgreementEventModel.fromMap).toList();
  }

  @override
  Future<void> appendEvent(String projectDir, AgreementEvent event) async {
    await _jsonl.append(_fullPath(projectDir), AgreementEventModel.toMap(event));
  }

  @override
  Future<String> nextId(String projectDir) async {
    final events = await _readAllEvents(projectDir);
    final pattern = RegExp(r'^AGR-(\d+)$');
    var maxSeq = 0;
    for (final event in events) {
      final match = pattern.firstMatch(event.id);
      if (match != null) {
        final seq = int.parse(match.group(1)!);
        if (seq > maxSeq) maxSeq = seq;
      }
    }
    return 'AGR-${(maxSeq + 1).toString().padLeft(4, '0')}';
  }

  @override
  Future<List<Agreement>> listAll(String projectDir) async {
    final events = await _readAllEvents(projectDir);
    final byId = <String, List<AgreementEvent>>{};
    for (final event in events) {
      byId.putIfAbsent(event.id, () => []).add(event);
    }
    final result = byId.values.map(Agreement.foldFrom).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return result;
  }

  @override
  Future<Agreement?> findById(String projectDir, String id) async {
    final all = await listAll(projectDir);
    try {
      return all.firstWhere((a) => a.id == id);
    } on StateError {
      return null;
    }
  }
}
