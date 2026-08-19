import 'dart:io';

import 'package:test/test.dart';
import 'package:utakata/src/1_domain/1_entities/config/utakata_config_entity.dart';
import 'package:utakata/src/1_domain/1_entities/record/impl_plan_meta.dart';
import 'package:utakata/src/1_domain/3_usecases/impl_plan_usecase.dart';
import 'package:utakata/src/1_domain/services/impl_lane.dart';
import 'package:utakata/src/1_domain/services/impl_plan_gate.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/filesystem_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/front_matter_data_source.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/yaml_data_source.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/impl_plan_repository_impl.dart';

/// v1.7.0: impl の2軸ライフサイクルとレーン(ディレクトリ)導出。
void main() {
  late Directory dir;
  late ImplPlanRepositoryImpl repo;
  late ImplPlanUsecase usecase;
  final now = DateTime(2026, 8, 11);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('utakata_impl_');
    repo = const ImplPlanRepositoryImpl(
        FilesystemDataSource(), FrontMatterDataSource(YamlDataSource()));
    usecase = ImplPlanUsecase(repo: repo);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<String> newPlan(String feature) => usecase.create(
        dir.path,
        feature: feature,
        now: now,
        bodyTemplate: '# 実装計画\n',
      );

  bool existsIn(ImplLane lane, String fileName) =>
      File('${dir.path}/doc/impl/${lane.dirName}/$fileName').existsSync();

  group('レーン導出', () {
    test('実装が終わるまでは実装側のレーン', () {
      expect(ImplLane.of(ImplPlanStatus.todo, ImplTestStatus.todo),
          ImplLane.todo);
      expect(ImplLane.of(ImplPlanStatus.inProgress, ImplTestStatus.todo),
          ImplLane.inProgress);
      expect(ImplLane.of(ImplPlanStatus.review, ImplTestStatus.todo),
          ImplLane.review);
    });

    test('実装完了後はテスト側のレーン', () {
      expect(ImplLane.of(ImplPlanStatus.done, ImplTestStatus.todo),
          ImplLane.testTodo);
      expect(ImplLane.of(ImplPlanStatus.done, ImplTestStatus.inProgress),
          ImplLane.testInProgress);
      expect(ImplLane.of(ImplPlanStatus.done, ImplTestStatus.review),
          ImplLane.testReview);
    });

    test('両方完了(またはテスト不要)なら done', () {
      expect(ImplLane.of(ImplPlanStatus.done, ImplTestStatus.done),
          ImplLane.done);
      expect(ImplLane.of(ImplPlanStatus.done, ImplTestStatus.notRequired),
          ImplLane.done);
    });

    test('archived はテスト状態に関係なく archive', () {
      expect(ImplLane.of(ImplPlanStatus.archived, ImplTestStatus.inProgress),
          ImplLane.archive);
    });
  });

  group('遷移とファイル移動', () {
    test('new は 1_todo に置かれる', () async {
      final id = await newPlan('login');
      expect(existsIn(ImplLane.todo, '${id}_login.md'), isTrue);
    });

    test('状態を変えるとレーンを移動する', () async {
      final id = await newPlan('login');

      await usecase.setStatus(dir.path, id, ImplPlanStatus.inProgress, now: now);
      expect(existsIn(ImplLane.inProgress, '${id}_login.md'), isTrue);
      expect(existsIn(ImplLane.todo, '${id}_login.md'), isFalse);

      await usecase.setStatus(dir.path, id, ImplPlanStatus.done, now: now);
      expect(existsIn(ImplLane.testTodo, '${id}_login.md'), isTrue);

      await usecase.setTest(dir.path, id, ImplTestStatus.done);
      expect(existsIn(ImplLane.done, '${id}_login.md'), isTrue);
    });

    test('逆行できる(テストが落ちて実装へ戻る)', () async {
      final id = await newPlan('login');
      await usecase.setStatus(dir.path, id, ImplPlanStatus.done, now: now);
      await usecase.setTest(dir.path, id, ImplTestStatus.inProgress);

      await usecase.setStatus(dir.path, id, ImplPlanStatus.inProgress, now: now);
      expect(existsIn(ImplLane.inProgress, '${id}_login.md'), isTrue);
    });

    test('実装が done でないとテストを進められない', () async {
      final id = await newPlan('login');
      expect(() => usecase.setTest(dir.path, id, ImplTestStatus.inProgress),
          throwsArgumentError);
    });

    test('テスト不要は実装完了前でも宣言できる', () async {
      final id = await newPlan('login');
      final result = await usecase
          .setTest(dir.path, id, ImplTestStatus.notRequired, skipReason: '設定変更のみ');
      expect(result.after.test, ImplTestStatus.notRequired);
      expect(result.after.testSkipReason, '設定変更のみ');
    });

    test('存在しない ID は ArgumentError', () {
      expect(
          () => usecase.setStatus(dir.path, 'PLAN-9999', ImplPlanStatus.done,
              now: now),
          throwsArgumentError);
    });
  });

  group('ID 採番', () {
    test('archive 済みの ID を再利用しない(v1.6.x の欠陥)', () async {
      await newPlan('login');
      final second = await newPlan('payment');
      await usecase.archive(dir.path, second, now: now);

      final third = await newPlan('search');
      expect(third, 'PLAN-0003');
    });
  });

  group('sync', () {
    test('手で動かしたファイルを frontmatter に合わせて戻す', () async {
      final id = await newPlan('login');
      await usecase.setStatus(dir.path, id, ImplPlanStatus.review, now: now);

      // 人が手で 1_todo に戻してしまった状況
      final from = File('${dir.path}/doc/impl/3_review/${id}_login.md');
      final to = Directory('${dir.path}/doc/impl/1_todo')
        ..createSync(recursive: true);
      from.renameSync('${to.path}/${id}_login.md');

      final misplaced = await usecase.detectMisplaced(dir.path);
      expect(misplaced.keys, [id]);

      final movedDry = await usecase.sync(dir.path, dryRun: true);
      expect(movedDry, [id]);
      expect(existsIn(ImplLane.review, '${id}_login.md'), isFalse,
          reason: 'dry-run では動かさない');

      await usecase.sync(dir.path);
      expect(existsIn(ImplLane.review, '${id}_login.md'), isTrue);
    });
  });

  group('後方互換', () {
    test('v1.6.x のフラット配置・draft・verification を読める', () async {
      final legacy = File('${dir.path}/doc/impl/PLAN-0007_legacy.md')
        ..createSync(recursive: true);
      legacy.writeAsStringSync('''---
id: "PLAN-0007"
feature: "legacy"
status: "draft"
created: "2026-07-01"
verification:
  static: "done"
  on_device: "done"
---
# 実装計画
''');

      final plans = await usecase.list(dir.path);
      expect(plans.single.status, ImplPlanStatus.todo, reason: 'draft → todo');
      expect(plans.single.test, ImplTestStatus.done,
          reason: 'verification が両方 done ならテスト完了');

      // status が todo である以上、検証が済んでいてもレーンは 1_todo
      await usecase.sync(dir.path);
      expect(existsIn(ImplLane.todo, 'PLAN-0007_legacy.md'), isTrue);
    });

    test('採番は旧配置の計画も含めて最大 + 1', () async {
      File('${dir.path}/doc/impl/PLAN-0009_legacy.md')
        ..createSync(recursive: true)
        ..writeAsStringSync('''---
id: "PLAN-0009"
feature: "legacy"
status: "todo"
created: "2026-07-01"
---
''');
      expect(await newPlan('fresh'), 'PLAN-0010');
    });
  });

  group('ImplPlanGate', () {
    test('archived 以外の計画があれば「計画あり」', () {
      final plans = [
        ImplPlanMeta(
            id: 'PLAN-0001',
            feature: 'todo',
            status: ImplPlanStatus.done,
            created: DateTime(2026)),
        ImplPlanMeta(
            id: 'PLAN-0002',
            feature: 'memo',
            status: ImplPlanStatus.archived,
            created: DateTime(2026)),
      ];
      expect(ImplPlanGate.featuresWithPlan(plans), {'todo'});
    });

    test('enforced が false なら何も止めない', () {
      expect(
          ImplPlanGate.blocked(
              enforced: false, featureNames: ['a', 'b'], withPlan: const {}),
          isEmpty);
    });

    test('既定は off(CLI を上げただけでは止まらない)', () {
      expect(const UtakataConfig().implPlanEnforcement, 'off');
      expect(UtakataConfig.fromMap(const {}).implPlanEnforcement, 'off');
      expect(
          UtakataConfig.fromMap(const {
            'enforcement': {'impl_plan': 'on'}
          }).implPlanEnforcement,
          'on');
    });

    test('enforced なら計画の無い feature だけ止める', () {
      expect(
          ImplPlanGate.blocked(
              enforced: true, featureNames: ['a', 'b'], withPlan: {'a'}),
          ['b']);
    });
  });
}
