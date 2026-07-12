import '../1_entities/record/agreement.dart';
import '../2_repositories/agreement_repository.dart';

/// `utakata summary` — 案件整理サマリーのマーカー区間を再生成する。
///
/// マーカー外の手書き部分は変更しない(仕様書 §7.3)。
class RenderSummaryUsecase {
  final AgreementRepository _agreementRepo;
  final Future<String?> Function(String path) _readFile;
  final Future<void> Function(String path, String content) _writeFile;
  final String Function(String document, String markerName, String newContent) _replaceSection;
  final String Function(List<Agreement> agreements) _renderAgreements;

  const RenderSummaryUsecase({
    required AgreementRepository agreementRepo,
    required Future<String?> Function(String path) readFile,
    required Future<void> Function(String path, String content) writeFile,
    required String Function(String document, String markerName, String newContent) replaceSection,
    required String Function(List<Agreement> agreements) renderAgreements,
  })  : _agreementRepo = agreementRepo,
        _readFile = readFile,
        _writeFile = writeFile,
        _replaceSection = replaceSection,
        _renderAgreements = renderAgreements;

  static const _path = 'doc/summary.md';

  Future<void> execute(String projectDir) async {
    final path = '$projectDir/$_path';
    final existing = await _readFile(path) ?? '# 案件整理サマリー\n';
    final agreements = await _agreementRepo.listAll(projectDir);
    final section = _renderAgreements(agreements);
    final updated = _replaceSection(existing, 'agreements', section);
    await _writeFile(path, updated);
  }
}
