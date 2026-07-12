/// utakata — 仕様駆動 Flutter 開発を支援する CLI ツール
///
/// このファイルはパッケージの公開エントリポイント。
/// 外部から import する場合はここを参照する。
library;

export 'src/1_domain/1_entities/architecture_definition_entity.dart';
export 'src/1_domain/1_entities/core_module_entity.dart';
export 'src/1_domain/1_entities/feature_spec_entity.dart';
export 'src/1_domain/1_entities/project_spec_entity.dart';
export 'src/1_domain/1_entities/structure/check_report.dart';
export 'src/1_domain/1_entities/structure/structure_snapshot.dart';
export 'src/1_domain/1_entities/plan/plan_intent.dart';
export 'src/1_domain/1_entities/record/record_id.dart';
export 'src/1_domain/1_entities/record/log_entry.dart';
export 'src/1_domain/1_entities/template_file_entity.dart';
export 'src/1_domain/2_repositories/architecture_repository.dart';
export 'src/1_domain/2_repositories/template_repository.dart';
export 'src/1_domain/2_repositories/project_repository.dart';
export 'src/1_domain/2_repositories/plan_repository.dart';
export 'src/1_domain/2_repositories/structure_repository.dart';
export 'src/1_domain/2_repositories/conversation_log_repository.dart';
export 'src/1_domain/1_entities/guide_entity.dart';
export 'src/1_domain/exceptions/domain_exceptions.dart';
