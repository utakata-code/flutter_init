import 'package:test/test.dart';
import 'package:utakata/src/1_domain/1_entities/dependency_stack_entity.dart';
import 'package:utakata/src/1_domain/1_entities/architecture_definition_entity.dart';
import 'package:utakata/src/1_domain/1_entities/imports/import_audit_report.dart';
import 'package:utakata/src/1_domain/2_repositories/architecture_repository.dart';
import 'package:utakata/src/1_domain/2_repositories/config_repository.dart';
import 'package:utakata/src/1_domain/1_entities/config/utakata_config_entity.dart';
import 'package:utakata/src/1_domain/3_usecases/architecture_resolver.dart';
import 'package:utakata/src/1_domain/3_usecases/audit_imports_usecase.dart';
import 'package:utakata/src/1_domain/services/import_auditor.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/filesystem_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_data_source.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/architecture_repository_impl.dart';

/// Issue #20: `utakata imports` — import 健全性の決定論的監査。
void main() {
  const rules = ImportRuleSet(
    excludePatterns: ['**.g.dart', '**.freezed.dart'],
    internalRules: [
      InternalImportRule(
        dirPattern: '1_domain/1_entities',
        allow: ['1_domain/exceptions'],
      ),
      InternalImportRule(
        dirPattern: '2_infrastructure/2_data_sources/1_local',
        allow: ['2_infrastructure/1_models'],
      ),
      InternalImportRule(
        dirPattern: '2_infrastructure/2_data_sources/1_local/exceptions',
        allow: [],
      ),
      InternalImportRule(
        dirPattern: '3_application/2_providers',
        allow: ['1_domain', '2_infrastructure', '3_application'],
      ),
    ],
    externalRules: [
      ExternalImportRule(
        dirPattern: '1_domain',
        deny: ['flutter', '*riverpod*', 'dio', 'dart:io'],
      ),
      ExternalImportRule(
        dirPattern: '1_domain/1_entities',
        deny: ['drift'],
      ),
    ],
  );

  const knownScopes = {
    '1_domain',
    '2_infrastructure',
    '3_application',
    '4_presentation',
  };

  ImportAuditReport auditOne(String path, List<String> imports) =>
      ImportAuditor.audit(
        rules: rules,
        selfPackage: 'myapp',
        files: [DartSourceFile(path: path, imports: imports)],
        knownScopes: knownScopes,
      );

  const entityPath =
      'lib/features/user/todo/1_domain/1_entities/todo_entity.dart';

  group('外部依存(ブラックリスト)', () {
    test('deny に一致するパッケージは違反', () {
      final report =
          auditOne(entityPath, ['package:flutter/material.dart']);
      expect(report.violations, hasLength(1));
      expect(report.violations.single.kind, ImportViolationKind.external);
      expect(report.violations.single.importUri, 'package:flutter/material.dart');
    });

    test('glob(*riverpod*)が flutter_riverpod に一致する', () {
      final report = auditOne(
          entityPath, ['package:flutter_riverpod/flutter_riverpod.dart']);
      expect(report.violations, hasLength(1));
    });

    test('deny に無いパッケージは許可', () {
      final report = auditOne(entityPath,
          ['package:freezed_annotation/freezed_annotation.dart']);
      expect(report.violations, isEmpty);
    });

    test('dart: URI も deny 指定できる', () {
      final report = auditOne(entityPath, ['dart:io']);
      expect(report.violations, hasLength(1));
    });

    test('deny されていない dart: は許可', () {
      final report = auditOne(entityPath, ['dart:core', 'dart:async']);
      expect(report.violations, isEmpty);
    });

    test('複数ルールが重なって適用される(層全体 + サブディレクトリ)', () {
      final report = auditOne(entityPath,
          ['package:drift/drift.dart', 'package:dio/dio.dart']);
      expect(report.violations, hasLength(2));
    });

    test('層の外のファイル(main.dart)には外部ルールが適用されない', () {
      final report = auditOne('lib/main.dart', ['package:flutter/material.dart']);
      expect(report.violations, isEmpty);
    });
  });

  group('内部依存(ホワイトリスト)', () {
    test('自層への相対 import は常に許可', () {
      final report = auditOne(entityPath, ['tag_entity.dart', './base/mixin.dart']);
      expect(report.violations, isEmpty);
    });

    test('allow に含まれる層への import は許可', () {
      final report =
          auditOne(entityPath, ['../exceptions/todo_exceptions.dart']);
      expect(report.violations, isEmpty);
    });

    test('allow に無い層への相対 import は違反', () {
      final report = auditOne(entityPath,
          ['../../2_infrastructure/1_models/todo_model.dart']);
      expect(report.violations, hasLength(1));
      expect(report.violations.single.kind, ImportViolationKind.internal);
    });

    test('package:<self>/ 形式の内部 import も検証される', () {
      final report = auditOne(entityPath, [
        'package:myapp/features/user/todo/2_infrastructure/1_models/todo_model.dart',
      ]);
      expect(report.violations, hasLength(1));
    });

    test('層に属さないパス(core/)への import は監査対象外', () {
      final report =
          auditOne(entityPath, ['package:myapp/core/logger/logger.dart']);
      expect(report.violations, isEmpty);
    });

    test('広い allow(層名)は配下すべてを許可する', () {
      final report = auditOne(
        'lib/features/user/todo/3_application/2_providers/todo_providers.dart',
        [
          '../../1_domain/3_usecases/get_todo_usecase.dart',
          '../../2_infrastructure/3_repositories/todo_repository_impl.dart',
        ],
      );
      expect(report.violations, isEmpty);
    });

    test('最も具体的な(セグメント数最長の)ルールが選ばれる', () {
      // exceptions/ には専用ルール(allow: [])があり、親ルールの
      // allow(1_models)は適用されない
      final report = auditOne(
        'lib/features/user/todo/2_infrastructure/2_data_sources/1_local/exceptions/db_local_exceptions.dart',
        ['../../../1_models/todo_model.dart'],
      );
      expect(report.violations, hasLength(1));
    });

    test('ルールの無い層のファイルは内部監査されない', () {
      final report = auditOne(
        'lib/features/user/todo/4_presentation/2_pages/todo_page.dart',
        ['../../2_infrastructure/1_models/todo_model.dart'],
      );
      expect(report.violations, isEmpty);
    });
  });

  group('ディレクティブ抽出(字句走査)', () {
    test('コメント・文字列内の import は拾わない', () {
      const source = '''
// import 'package:line_comment/a.dart';
/* import 'package:block_comment/a.dart'; */
/* ネスト /* import 'package:nested/a.dart'; */ まだコメント */
const s = \'\'\'
import 'package:multiline_string/a.dart';
\'\'\';
import 'package:real/real.dart';
export 'src/real_export.dart';
''';
      expect(ImportAuditor.extractDirectives(source),
          ['package:real/real.dart', 'src/real_export.dart']);
    });

    test('条件付き import は全分岐の URI を返す', () {
      const source = '''
import 'stub.dart'
    if (dart.library.io) 'package:dio/dio.dart'
    if (dart.library.html) 'web.dart';
''';
      expect(ImportAuditor.extractDirectives(source),
          ['stub.dart', 'package:dio/dio.dart', 'web.dart']);
    });

    test('行頭以外の import 語や通常コードの文字列は拾わない', () {
      const source = '''
import 'a.dart';
void main() {
  final x = foo.import('not_a_directive.dart');
  print('import "fake.dart"');
}
''';
      expect(ImportAuditor.extractDirectives(source), ['a.dart']);
    });
  });

  group('監査スコープ(lib/features/ 配下のみ)', () {
    test('lib/core/ 配下に層名と同名のディレクトリがあっても監査されない', () {
      final report = auditOne(
        'lib/core/1_domain/shared.dart',
        ['package:flutter/material.dart'],
      );
      expect(report.violations, isEmpty);
    });

    test('lib/core/ の層名ディレクトリへの import は違反にならない', () {
      final report =
          auditOne(entityPath, ['package:myapp/core/1_domain/shared.dart']);
      expect(report.violations, isEmpty);
    });
  });

  group('層間依存グラフ(v2)', () {
    const graphRules = ImportRuleSet(
      layerGraph: {
        '1_domain': [],
        '2_infrastructure': ['1_domain'],
        '3_application': ['1_domain', '2_infrastructure'],
        '4_presentation': ['1_domain', '3_application'],
      },
      internalRules: [
        // 細則はグラフより優先される
        InternalImportRule(
          dirPattern: '3_application/1_states',
          allow: ['1_domain/1_entities'],
        ),
      ],
    );
    const layerNames = [
      '1_domain',
      '2_infrastructure',
      '3_application',
      '4_presentation',
    ];

    ImportAuditReport auditGraph(String path, List<String> imports) =>
        ImportAuditor.audit(
          rules: graphRules,
          selfPackage: 'myapp',
          files: [DartSourceFile(path: path, imports: imports)],
          knownScopes: layerNames.toSet(),
          layerNames: layerNames,
        );

    test('グラフのエッジにある層への import は許可', () {
      final report = auditGraph(
        'lib/features/user/todo/4_presentation/2_pages/todo_page.dart',
        [
          '../../3_application/3_notifiers/todo_notifier.dart',
          '../../1_domain/1_entities/todo_entity.dart',
          '../1_widgets/3_organisms/todo_organism.dart', // 自層
        ],
      );
      expect(report.violations, isEmpty);
    });

    test('グラフのエッジに無い層への import は違反', () {
      final report = auditGraph(
        'lib/features/user/todo/4_presentation/2_pages/todo_page.dart',
        ['../../2_infrastructure/3_repositories/todo_repository_impl.dart'],
      );
      expect(report.violations, hasLength(1));
      expect(report.violations.single.rulePattern, '4_presentation');
      expect(report.violations.single.target, '2_infrastructure');
    });

    test('dirs 細則があるディレクトリではグラフより細則が優先される', () {
      // グラフ上 3_application → 1_domain は許可だが、states の細則は
      // 1_domain/1_entities のみ許可
      final report = auditGraph(
        'lib/features/user/todo/3_application/1_states/todo_state.dart',
        ['../../1_domain/3_usecases/get_todo_usecase.dart'],
      );
      expect(report.violations, hasLength(1));
    });
  });

  group('配置宣言(v2)', () {
    const placements = [
      PackagePlacement(
        package: 'dio',
        layers: ['2_infrastructure/2_data_sources/2_remote'],
      ),
      PackagePlacement(package: 'sqlite3_flutter_libs', layers: []),
      PackagePlacement(package: 'freezed_annotation'), // 制約なし
    ];

    ImportAuditReport auditPlacement(String path, List<String> imports) =>
        ImportAuditor.audit(
          rules: const ImportRuleSet(layerGraph: {'1_domain': []}),
          selfPackage: 'myapp',
          files: [DartSourceFile(path: path, imports: imports)],
          knownScopes: knownScopes,
          placements: placements,
          layerNames: const ['1_domain', '2_infrastructure'],
        );

    test('宣言された層でのパッケージ import は許可', () {
      final report = auditPlacement(
        'lib/features/user/todo/2_infrastructure/2_data_sources/2_remote/todo_remote_data_source.dart',
        ['package:dio/dio.dart'],
      );
      expect(report.violations, isEmpty);
    });

    test('宣言外の層でのパッケージ import は違反(placement)', () {
      final report = auditPlacement(entityPath, ['package:dio/dio.dart']);
      expect(report.violations, hasLength(1));
      expect(report.violations.single.kind, ImportViolationKind.placement);
      expect(report.violations.single.ruleDetail,
          ['2_infrastructure/2_data_sources/2_remote']);
    });

    test('layers: [] はどの層でも import 不可(ビルド時のみの依存)', () {
      final report =
          auditPlacement(entityPath, ['package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart']);
      expect(report.violations, hasLength(1));
      expect(report.violations.single.kind, ImportViolationKind.placement);
    });

    test('layers 未指定・宣言外のパッケージは制約なし', () {
      final report = auditPlacement(entityPath, [
        'package:freezed_annotation/freezed_annotation.dart',
        'package:undeclared_pkg/undeclared_pkg.dart',
      ]);
      expect(report.violations, isEmpty);
    });
  });

  group('exclude', () {
    test('生成ファイルは監査から除外される', () {
      final report = auditOne(
        'lib/features/user/todo/1_domain/1_entities/todo_entity.g.dart',
        ['package:flutter/material.dart'],
      );
      expect(report.violations, isEmpty);
      expect(report.excludedFileCount, 1);
      expect(report.auditedFileCount, 0);
    });
  });

  group('AuditImportsUsecase', () {
    test('lib/ を走査し、クォートされた pubspec name も self package として解決する', () async {
      final files = <String, String>{
        '/proj/pubspec.yaml': 'name: "myapp"\nversion: 1.0.0\n',
        '/proj/lib/features/user/todo/1_domain/1_entities/todo_entity.dart': '''
import 'package:flutter/material.dart';
import 'package:myapp/features/user/todo/2_infrastructure/1_models/todo_model.dart';
// import 'package:dio/dio.dart'; ← コメントは無視される
''',
      };
      final usecase = AuditImportsUsecase(
        archResolver: ArchitectureResolver(
          configRepo: _NoConfigRepo(),
          planRepo: null,
        ),
        archRepo: _FixedArchRepo(const ArchitectureDefinitionEntity(
          id: 'clean_architecture',
          displayName: 'Clean',
          layers: [
            LayerDefinitionEntity(name: '1_domain', dirs: ['1_entities']),
            LayerDefinitionEntity(name: '2_infrastructure', dirs: ['1_models']),
          ],
          importRules: rules,
        )),
        listFilesWithSuffix: (dir, suffix) => [
          'features/user/todo/1_domain/1_entities/todo_entity.dart',
        ],
        readFile: (path) async => files[path],
      );

      final result = await usecase.execute('/proj');

      expect(result.hasRules, isTrue);
      final violations = result.report!.violations;
      expect(violations, hasLength(2));
      expect(violations.map((v) => v.kind).toSet(),
          {ImportViolationKind.internal, ImportViolationKind.external});
    });

    test('import_rules が無いアーキテクチャでは監査しない', () async {
      final usecase = AuditImportsUsecase(
        archResolver: ArchitectureResolver(
          configRepo: _NoConfigRepo(),
          planRepo: null,
        ),
        archRepo: _FixedArchRepo(const ArchitectureDefinitionEntity(
          id: 'custom',
          displayName: 'Custom',
          layers: [],
        )),
        listFilesWithSuffix: (dir, suffix) => const [],
        readFile: (path) async => null,
      );

      final result = await usecase.execute('/proj');
      expect(result.hasRules, isFalse);
      expect(result.report, isNull);
    });
  });

  group('同梱アーキテクチャ定義', () {
    test('clean_architecture と mvvm の import_rules(v2)がパースできる', () async {
      final repo = ArchitectureRepositoryImpl(
          const FilesystemDataSource(), const YamlDataSource());
      for (final id in ['clean_architecture', 'mvvm']) {
        final arch = await repo.getById(id);
        final importRules = arch.importRules;
        expect(importRules, isNotNull, reason: '$id has import_rules');
        // v2: 層間依存グラフ + 細則。外部依存は deny ではなく配置宣言
        expect(importRules!.layerGraph, isNotEmpty);
        expect(importRules.internalRules, isNotEmpty);
        expect(importRules.externalRules, isEmpty,
            reason: '$id: v2 では deny を使わない(配置宣言へ移行済み)');
        expect(importRules.excludePatterns, contains('**.g.dart'));
        // 層グラフの全エントリが実在の層を指している
        final layerNames = {for (final l in arch.layers) l.name};
        for (final entry in importRules.layerGraph.entries) {
          expect(layerNames, contains(entry.key));
          for (final target in entry.value) {
            expect(layerNames, contains(target),
                reason: '$id: ${entry.key} → $target が未知の層');
          }
        }
        // 配置宣言が読める
        final stack = await repo.getDependencyStack(id);
        expect(stack.placements, isNotEmpty);
      }
    });
  });
}

class _NoConfigRepo implements ConfigRepository {
  @override
  Future<UtakataConfig?> read(String projectDir) async => null;

  @override
  Future<UtakataConfig?> readGlobal() async => null;

  @override
  Future<List<String>> validate(String projectDir) async => const [];
}

class _FixedArchRepo implements ArchitectureRepository {
  @override
  Future<DependencyStack> getDependencyStack(String architectureId) async =>
      DependencyStack.empty;

  final ArchitectureDefinitionEntity arch;
  _FixedArchRepo(this.arch);

  @override
  Future<ArchitectureDefinitionEntity> getById(String architectureId) async =>
      arch;

  @override
  Future<List<ArchitectureDefinitionEntity>> getAll() async => [arch];

  @override
  Future<String> getRawDefinition(String architectureId) =>
      throw UnimplementedError();
}
