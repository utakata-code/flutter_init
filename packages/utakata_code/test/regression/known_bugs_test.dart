// 既知バグの回帰テスト(v0.6.0)。
//
// AI/specs/current_state_and_issues.md §3.3 に記録された保留バグのうち、
// 実際に現行コードで再現するものを固定する。
import 'package:test/test.dart';
import 'package:utakata/src/1_domain/2_repositories/architecture_repository.dart';
import 'package:utakata/src/1_domain/2_repositories/project_repository.dart';
import 'package:utakata/src/1_domain/3_usecases/diff_architecture_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/validate_usecase.dart';
import 'package:utakata/src/1_domain/1_entities/architecture_definition_entity.dart';
import 'package:utakata/src/1_domain/messages/ja_messages.dart';

/// テスト専用の in-memory ProjectRepository フェイク
class _FakeProjectRepository implements ProjectRepository {
  Map<String, dynamic>? plan;
  Map<String, dynamic> currentStructure;

  _FakeProjectRepository({this.plan, required this.currentStructure});

  @override
  Future<Map<String, dynamic>> readFeatureRequest(String projectDir) async =>
      throw UnimplementedError();

  @override
  Future<void> writePlanArchitecture(
          String projectDir, Map<String, dynamic> plan) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> readPlanArchitecture(String projectDir) async =>
      plan;

  @override
  Future<Map<String, dynamic>?> readCurrentStructure(String projectDir) async =>
      currentStructure;

  @override
  Future<void> writeCurrentStructure(
      String projectDir, Map<String, dynamic> structure) async {}

  @override
  Future<Map<String, dynamic>> scanFeaturesStructure(String projectDir) async =>
      currentStructure;

  @override
  Future<void> writeProjectStatus(
      String projectDir, Map<String, dynamic> status) async {}

  @override
  Future<void> writeProjectStatusMarkdown(
      String projectDir, String markdown) async {}
}

class _FakeArchitectureRepository implements ArchitectureRepository {
  final ArchitectureDefinitionEntity definition;
  _FakeArchitectureRepository(this.definition);

  @override
  Future<ArchitectureDefinitionEntity> getById(String architectureId) async =>
      definition;

  @override
  Future<List<ArchitectureDefinitionEntity>> getAll() async => [definition];

  @override
  Future<String> getRawDefinition(String architectureId) async => '';
}

void main() {
  final msg = JaMessages();

  group('既知バグ回帰: validate は direct パーミッションを補償しない', () {
    // plan_architecture_usecase が生成する plan は
    // {'features': {'direct': {featureName: {...layers}}}} という形で
    // direct フィーチャーをネストする。一方 diff_architecture_usecase は
    // 比較前に 'direct' キーをトップレベルへフラット展開して物理構造
    // (lib/features/{featureName}/...、権限フォルダを挟まない)に合わせる。
    // validate_usecase はこのフラット展開を行わないため、direct フィーチャーが
    // 完全に一致していても「missing: direct」「extra: {featureName}」を
    // 誤検知する。
    test('diff は direct を正しくフラット展開し差分なしと判定する', () async {
      final plan = {
        'features': {
          'direct': {
            'auth': {
              '1_domain': {'1_entities': <String, dynamic>{}},
            },
          },
        },
      };
      final current = {
        'auth': {
          '1_domain': {'1_entities': <String, dynamic>{}},
        },
      };
      final repo = _FakeProjectRepository(plan: plan, currentStructure: current);
      final usecase = DiffArchitectureUsecase(projectRepo: repo, msg: msg);

      final diff = await usecase.execute('/tmp/fake');

      expect(diff.isClean, isTrue,
          reason: 'diff は direct を展開して current と一致させるはず');
    });

    test(
        '[既知バグ] validate は direct を展開しないため一致していても誤検知する',
        () async {
      final plan = {
        'features': {
          'direct': {
            'auth': {
              '1_domain': {'1_entities': <String, dynamic>{}},
            },
          },
        },
      };
      final current = {
        'auth': {
          '1_domain': {'1_entities': <String, dynamic>{}},
        },
      };
      final repo = _FakeProjectRepository(plan: plan, currentStructure: current);
      final usecase = ValidateUsecase(
        archRepo: _FakeArchitectureRepository(const ArchitectureDefinitionEntity(
          id: 'clean_architecture',
          displayName: 'Clean Architecture',
          layers: [],
          namingRules: [],
          guides: [],
          dependencies: {},
          devDependencies: {},
          coreModules: [],
        )),
        projectRepo: repo,
        listDartFilesRecursive: (_) => const [],
      );

      final result = await usecase.execute('/tmp/fake');

      // 現状の(バグのある)挙動を固定する回帰ケース。
      // 本来は plan と current が完全一致しているため missing/extra は
      // 空であるべきだが、direct の補償展開がないため誤検知が発生する。
      expect(result.missingDirs, contains('direct'));
      expect(result.extraDirs, contains('auth'));
    });
  });

  group(
      '既知バグ回帰: diff は __files__ 未宣言ディレクトリの実ファイルを常に extra 判定する',
      () {
    // plan_architecture_usecase は _resolveFileName が null を返す場合
    // (description に {verb} や "|" を含む、例: usecases/ の複数ファイル)
    // __files__ キー自体を生成しない(空の Map になる)。
    // このとき diff/validate の _collectMissing は「plan 側に __files__ が
    // なければ actualList を空とみなす」ため、実際に存在するファイルが
    // 全て extra として誤検知される。本来は「plan がファイル名を指定して
    // いないディレクトリでは、規則に合う任意のファイルを許可する」のが
    // 正しい挙動のはず(v0.7 の allowRules 設計で解消予定)。
    test('[既知バグ] 命名が非決定的なディレクトリの実ファイルは extra 誤検知される',
        () async {
      final plan = {
        'features': {
          'user': {
            'memo': {
              '1_domain': {
                '3_usecases': <String, dynamic>{}, // ファイル名は非決定的なので空
              },
            },
          },
        },
      };
      final current = {
        'user': {
          'memo': {
            '1_domain': {
              '3_usecases': {
                '__files__': ['create_memo_usecase.dart', 'delete_memo_usecase.dart'],
              },
            },
          },
        },
      };
      final repo = _FakeProjectRepository(plan: plan, currentStructure: current);
      final usecase = DiffArchitectureUsecase(projectRepo: repo, msg: msg);

      final diff = await usecase.execute('/tmp/fake');

      // 現状の(バグのある)挙動を固定する回帰ケース。
      // 本来この2ファイルは正当な実装ファイルであり extra ではない。
      expect(
        diff.extraPaths,
        containsAll([
          'user/memo/1_domain/3_usecases/create_memo_usecase.dart',
          'user/memo/1_domain/3_usecases/delete_memo_usecase.dart',
        ]),
      );
    });
  });
}
