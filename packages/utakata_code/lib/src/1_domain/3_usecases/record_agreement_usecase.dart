import '../1_entities/record/agreement.dart';
import '../2_repositories/agreement_repository.dart';

/// `utakata agree add/status/correct/reflect` — 合意の記録・状態遷移・
/// 反映記録を行うユースケース(すべて追記イベントとして表現。仕様書 §7.2)。
class RecordAgreementUsecase {
  final AgreementRepository _repo;

  const RecordAgreementUsecase({required AgreementRepository repo}) : _repo = repo;

  Future<String> add(
    String projectDir, {
    required String title,
    required String kindRaw,
    double? amountValue,
    String? amountCurrency,
    String? paymentTerms,
    List<String> items = const [],
    List<String> sources = const [],
    String? backlog,
    required DateTime now,
    required String recordedBy,
  }) async {
    final id = await _repo.nextId(projectDir);
    await _repo.appendEvent(
      projectDir,
      AgreementEvent(
        type: AgreementEventType.add,
        id: id,
        recordedAt: now,
        recordedBy: recordedBy,
        title: title,
        kind: AgreementEvent.kindFromString(kindRaw),
        status: AgreementStatus.proposed,
        amountValue: amountValue,
        amountCurrency: amountCurrency,
        paymentTerms: paymentTerms,
        items: items,
        sources: sources,
        backlog: backlog,
      ),
    );
    return id;
  }

  Future<void> updateStatus(
    String projectDir,
    String id,
    String statusRaw, {
    required DateTime now,
    required String recordedBy,
  }) async {
    await _repo.appendEvent(
      projectDir,
      AgreementEvent(
        type: AgreementEventType.statusChange,
        id: id,
        recordedAt: now,
        recordedBy: recordedBy,
        status: AgreementEvent.statusFromString(statusRaw),
        statusOn: now,
      ),
    );
  }

  Future<String> correct(
    String projectDir,
    String correctsId, {
    required String title,
    required String kindRaw,
    List<String> items = const [],
    required DateTime now,
    required String recordedBy,
  }) async {
    // 訂正は新しい ID で記録し、元エントリは superseded にする
    final newId = await _repo.nextId(projectDir);
    await _repo.appendEvent(
      projectDir,
      AgreementEvent(
        type: AgreementEventType.add,
        id: newId,
        recordedAt: now,
        recordedBy: recordedBy,
        title: title,
        kind: AgreementEvent.kindFromString(kindRaw),
        status: AgreementStatus.agreed,
        items: items,
        correctsId: correctsId,
      ),
    );
    await _repo.appendEvent(
      projectDir,
      AgreementEvent(
        type: AgreementEventType.statusChange,
        id: correctsId,
        recordedAt: now,
        recordedBy: recordedBy,
        status: AgreementStatus.superseded,
      ),
    );
    return newId;
  }

  Future<void> reflect(
    String projectDir,
    String id, {
    String? planId,
    String? spec,
    required DateTime now,
    required String recordedBy,
  }) async {
    await _repo.appendEvent(
      projectDir,
      AgreementEvent(
        type: AgreementEventType.reflect,
        id: id,
        recordedAt: now,
        recordedBy: recordedBy,
        reflectedInPlanId: planId,
        reflectedInSpec: spec,
      ),
    );
  }
}
