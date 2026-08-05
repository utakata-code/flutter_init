import 'package:test/test.dart';
import 'package:utakata/src/1_domain/1_entities/architecture_definition_entity.dart';
import 'package:utakata/src/1_domain/1_entities/plan/plan_intent.dart';
import 'package:utakata/src/1_domain/1_entities/structure/structure_node.dart';
import 'package:utakata/src/1_domain/1_entities/structure/structure_snapshot.dart';
import 'package:utakata/src/1_domain/services/expected_structure_builder.dart';
import 'package:utakata/src/1_domain/services/structure_checker.dart';

/// Issue #12: plan.yaml の `layers` 宣言による層単位の増減。
void main() {
  const arch = ArchitectureDefinitionEntity(
    id: 'clean_architecture',
    displayName: 'Clean Architecture',
    layers: [
      LayerDefinitionEntity(name: '1_domain', dirs: ['1_entities', '3_usecases']),
      LayerDefinitionEntity(
          name: '2_infrastructure', dirs: ['2_data_sources/1_local', '2_data_sources/2_remote']),
    ],
    namingRules: [
      NamingRuleEntity(
        dirPattern: '1_domain/1_entities',
        filePattern: r'^.+_entity\.dart$',
        description: '{name}_entity.dart',
      ),
      NamingRuleEntity(
        dirPattern: '1_domain/3_usecases',
        filePattern: r'^.+_usecase\.dart$',
        description: '{verb}_{name}_usecase.dart',
      ),
      NamingRuleEntity(
        dirPattern: '2_infrastructure/2_data_sources/1_local',
        filePattern: r'^.+_data_source\.dart$',
        description: '{name}_data_source.dart',
      ),
      NamingRuleEntity(
        dirPattern: '2_infrastructure/2_data_sources/2_remote',
        filePattern: r'^.+_remote_data_source\.dart$',
        description: '{name}_remote_data_source.dart',
      ),
    ],
    guides: [],
    dependencies: {},
    devDependencies: {},
    coreModules: [],
  );

  /// feature ディレクトリだけが空で存在する実構造(ファイルは未実装)。
  StructureSnapshot snapshotWithEmptyDirs() => StructureSnapshot(
        root: StructureDirNode({
          'user': StructureDirNode({
            'todo': StructureDirNode({
              '1_domain': StructureDirNode({
                '1_entities': StructureDirNode.empty,
                '3_usecases': StructureDirNode.empty,
              }),
              '2_infrastructure': StructureDirNode({
                '2_data_sources': StructureDirNode({
                  '1_local': StructureDirNode.empty,
                  '2_remote': StructureDirNode.empty,
                }),
              }),
            }),
          }),
        }),
        scannedAt: DateTime(2026, 1, 1),
      );

  List<String> missingFor(PlanFeatureIntent feature, {StructureSnapshot? snapshot}) {
    final plan = PlanIntent(
      defaultArchitectureId: 'clean_architecture',
      features: [feature],
    );
    final expected =
        ExpectedStructureBuilder.build(plan, {'clean_architecture': arch});
    return StructureChecker.check(expected, snapshot ?? snapshotWithEmptyDirs())
        .missingPaths;
  }

  test('宣言なし: 従来どおり entities から全層を導出する(後方互換)', () {
    final missing = missingFor(
      const PlanFeatureIntent(name: 'todo', permission: 'user', entities: ['todo']),
    );
    // {verb} を含む usecases は非決定的なので要求されない
    expect(missing, [
      'user/todo/1_domain/1_entities/todo_entity.dart',
      'user/todo/2_infrastructure/2_data_sources/1_local/todo_data_source.dart',
      'user/todo/2_infrastructure/2_data_sources/2_remote/todo_remote_data_source.dart',
    ]);
  });

  test('空リスト宣言: その層は不要になり missing から消える', () {
    final missing = missingFor(
      const PlanFeatureIntent(
        name: 'todo',
        permission: 'user',
        entities: ['todo'],
        layers: {'2_infrastructure/2_data_sources/2_remote': []},
      ),
    );
    expect(missing, isNot(contains(
        'user/todo/2_infrastructure/2_data_sources/2_remote/todo_remote_data_source.dart')));
    expect(missing, hasLength(2));
  });

  test('親パスの空リスト宣言は配下すべてに波及する', () {
    final missing = missingFor(
      const PlanFeatureIntent(
        name: 'todo',
        permission: 'user',
        entities: ['todo'],
        layers: {'2_infrastructure': []},
      ),
    );
    expect(missing, ['user/todo/1_domain/1_entities/todo_entity.dart']);
  });

  test('空リスト宣言した層はディレクトリが存在しなくても missing にならない', () {
    final snapshot = StructureSnapshot(
      root: StructureDirNode({
        'user': StructureDirNode({
          'todo': StructureDirNode({
            '1_domain': StructureDirNode({
              '1_entities': StructureDirNode.empty,
              '3_usecases': StructureDirNode.empty,
            }),
            // 2_infrastructure ごと存在しない
          }),
        }),
      }),
      scannedAt: DateTime(2026, 1, 1),
    );
    final missing = missingFor(
      const PlanFeatureIntent(
        name: 'todo',
        permission: 'user',
        entities: ['todo'],
        layers: {'2_infrastructure': []},
      ),
      snapshot: snapshot,
    );
    expect(missing, ['user/todo/1_domain/1_entities/todo_entity.dart']);
  });

  test('明示リスト: 非決定的な層({verb})でも項目を必須にできる', () {
    final missing = missingFor(
      const PlanFeatureIntent(
        name: 'todo',
        permission: 'user',
        entities: ['todo'],
        layers: {
          '1_domain/3_usecases': ['get_todo', 'save_todo'],
        },
      ),
    );
    expect(missing, containsAll([
      'user/todo/1_domain/3_usecases/get_todo_usecase.dart',
      'user/todo/1_domain/3_usecases/save_todo_usecase.dart',
    ]));
  });

  test('明示リストは entities からの導出より優先される', () {
    final missing = missingFor(
      const PlanFeatureIntent(
        name: 'todo',
        permission: 'user',
        entities: ['todo', 'tag'], // 宣言が無ければ2ファイル要求されるはず
        layers: {
          '1_domain/1_entities': ['tag'], // tag だけに絞る
        },
      ),
    );
    expect(missing, contains('user/todo/1_domain/1_entities/tag_entity.dart'));
    expect(missing,
        isNot(contains('user/todo/1_domain/1_entities/todo_entity.dart')));
  });

  test('項目名に .dart を含めればファイル名としてそのまま扱う(逃げ道)', () {
    final missing = missingFor(
      const PlanFeatureIntent(
        name: 'todo',
        permission: 'user',
        layers: {
          '1_domain/1_entities': ['legacy_thing.dart'],
        },
      ),
    );
    expect(missing, contains('user/todo/1_domain/1_entities/legacy_thing.dart'));
  });

  test('PlanFeatureIntent の layers は toMap/fromMap を往復できる', () {
    const original = PlanFeatureIntent(
      name: 'todo',
      permission: 'user',
      entities: ['todo'],
      layers: {
        '1_domain/3_usecases': ['get_todo'],
        '2_infrastructure/2_data_sources/2_remote': [],
      },
    );
    final restored = PlanFeatureIntent.fromMap(original.toMap());
    expect(restored.layers, original.layers);
    expect(restored.isOptedOut('2_infrastructure/2_data_sources/2_remote'), isTrue);
    expect(restored.declarationFor('1_domain/3_usecases'), ['get_todo']);
  });
}
