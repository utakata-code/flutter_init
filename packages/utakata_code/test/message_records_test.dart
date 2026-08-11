import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:utakata/src/1_domain/1_entities/record/message_record.dart';
import 'package:utakata/src/1_domain/3_usecases/import_messages_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/record_message_usecase.dart';
import 'package:utakata/src/1_domain/3_usecases/render_messages_usecase.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/jsonl_data_source.dart';
import 'package:utakata/src/2_infrastructure/3_repositories/message_repository_impl.dart';
import 'package:utakata/src/3_application/3_presenters/message_preview_presenter.dart';

/// v1.6.0: `utakata message` — 送受信原文の記録(log の要約とは別系統)。
void main() {
  late Directory dir;
  late MessageRepositoryImpl repo;
  late RecordMessageUsecase record;
  late ImportMessagesUsecase import;

  final now = DateTime(2026, 8, 11, 15, 0);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('utakata_messages_');
    repo = const MessageRepositoryImpl(JsonlDataSource());
    record = RecordMessageUsecase(repo: repo);
    import = ImportMessagesUsecase(repo: repo);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<MessageRecord> add({
    required String direction,
    required String body,
    String? at,
    String? channel,
    String? externalId,
  }) =>
      record.execute(
        dir.path,
        body: body,
        directionRaw: direction,
        atRaw: at,
        now: now,
        recordedBy: 'haruma',
        channel: channel,
        externalId: externalId,
      );

  group('add', () {
    test('月別 JSONL に原文を無加工で追記する', () async {
      final saved = await add(
        direction: 'inbound',
        body: 'お世話になります。\n見積もりの件ですが……',
        at: '2026-08-11 10:24',
        channel: 'coconala',
      );

      expect(saved.id, 'MSGR-20260811-001');
      final file = File('${dir.path}/doc/records/messages/2026-08.jsonl');
      expect(file.existsSync(), isTrue);

      final row = jsonDecode(file.readAsLinesSync().single)
          as Map<String, dynamic>;
      expect(row['direction'], 'inbound');
      expect(row['channel'], 'coconala');
      // 原文は改行含めそのまま(マスクや整形をしない)
      expect(row['body'], 'お世話になります。\n見積もりの件ですが……');
      expect(row['recorded_by'], 'haruma');
    });

    test('ID は日付ごとの連番', () async {
      await add(direction: 'inbound', body: 'A', at: '2026-08-11 10:00');
      final second =
          await add(direction: 'outbound', body: 'B', at: '2026-08-11 11:00');
      expect(second.id, 'MSGR-20260811-002');
    });

    test('日時未指定なら概算フラグが立つ', () async {
      final saved = await add(direction: 'inbound', body: 'A');
      expect(saved.atApprox, isTrue);
    });

    test('未来日時は拒否する', () {
      expect(
        () => add(direction: 'inbound', body: 'A', at: '2027-01-01 00:00'),
        throwsArgumentError,
      );
    });

    test('空本文は拒否する', () {
      expect(() => add(direction: 'inbound', body: '   '), throwsArgumentError);
    });

    test('不正な direction は拒否する', () {
      expect(() => add(direction: 'sideways', body: 'A'), throwsArgumentError);
    });
  });

  group('query / list', () {
    setUp(() async {
      await add(
          direction: 'inbound',
          body: '受信1',
          at: '2026-08-11 10:00',
          channel: 'coconala');
      await add(
          direction: 'outbound',
          body: '送信1',
          at: '2026-08-11 11:00',
          channel: 'mail');
      await add(
          direction: 'inbound',
          body: '受信2(7月)',
          at: '2026-07-20 09:00',
          channel: 'coconala');
    });

    test('direction / channel / month で絞り込める', () async {
      expect(
          (await repo.query(dir.path, direction: MessageDirection.inbound))
              .length,
          2);
      expect((await repo.query(dir.path, channel: 'mail')).length, 1);
      expect((await repo.query(dir.path, month: '2026-07')).length, 1);
    });

    test('readAll は月をまたいで時系列に並ぶ', () async {
      final all = await repo.readAll(dir.path);
      expect(all.map((r) => r.body).toList(), ['受信2(7月)', '受信1', '送信1']);
    });
  });

  group('import', () {
    test('jsonl を取り込み、再取り込みは external_id で重複排除する', () async {
      final source = [
        jsonEncode({
          'direction': 'inbound',
          'at': '2026-08-10T09:00:00',
          'body': '一件目',
          'external_id': 'coconala:1',
        }),
        jsonEncode({
          'direction': 'outbound',
          'at': '2026-08-10T10:00:00',
          'body': '二件目',
          'external_id': 'coconala:2',
        }),
      ].join('\n');

      final first = await import.execute(dir.path,
          content: source, format: 'jsonl', now: now, recordedBy: 'haruma');
      expect(first.where((r) => !r.skipped).length, 2);

      final second = await import.execute(dir.path,
          content: source, format: 'jsonl', now: now, recordedBy: 'haruma');
      expect(second.every((r) => r.skipped), isTrue);
      expect((await repo.readAll(dir.path)).length, 2);
    });

    test('external_id が無くても本文と日時で重複排除する', () async {
      final source = jsonEncode({
        'direction': 'inbound',
        'at': '2026-08-10T09:00:00',
        'body': '同じ本文',
      });

      await import.execute(dir.path,
          content: source, format: 'jsonl', now: now, recordedBy: 'haruma');
      final again = await import.execute(dir.path,
          content: source, format: 'jsonl', now: now, recordedBy: 'haruma');

      expect(again.single.skipped, isTrue);
      expect((await repo.readAll(dir.path)).length, 1);
    });

    test('同一ファイル内の重複も1件にまとめる', () async {
      final line = jsonEncode({
        'direction': 'inbound',
        'at': '2026-08-10T09:00:00',
        'body': '重複',
      });
      final results = await import.execute(dir.path,
          content: '$line\n$line',
          format: 'jsonl',
          now: now,
          recordedBy: 'haruma');

      expect(results.where((r) => !r.skipped).length, 1);
      expect((await repo.readAll(dir.path)).length, 1);
    });

    test('dry-run では書き込まない', () async {
      final source = jsonEncode({
        'direction': 'inbound',
        'at': '2026-08-10T09:00:00',
        'body': '確認だけ',
      });
      final results = await import.execute(dir.path,
          content: source,
          format: 'jsonl',
          now: now,
          recordedBy: 'haruma',
          dryRun: true);

      expect(results.single.skipped, isFalse);
      expect(await repo.readAll(dir.path), isEmpty);
    });

    test('markdown の見出しで区切って取り込む', () async {
      const source = '''
## [inbound] 2026-08-11 10:24 山田様
お世話になります。
見積もりの件ですが……

## [outbound] 2026-08-11 12:00
ご連絡ありがとうございます。
''';
      final results = await import.execute(dir.path,
          content: source,
          format: 'md',
          now: now,
          recordedBy: 'haruma',
          defaultChannel: 'coconala');

      expect(results.length, 2);
      final saved = await repo.readAll(dir.path);
      expect(saved.first.direction, MessageDirection.inbound);
      expect(saved.first.from, '山田様');
      expect(saved.first.channel, 'coconala');
      expect(saved.first.body, contains('見積もりの件'));
      expect(saved.last.direction, MessageDirection.outbound);
    });

    test('未知の format はエラー', () {
      expect(
        () => import.execute(dir.path,
            content: '', format: 'csv', now: now, recordedBy: 'haruma'),
        throwsArgumentError,
      );
    });
  });

  group('link', () {
    test('本文を変えずに参照だけ付けられる', () async {
      final saved = await add(
          direction: 'inbound', body: '原文はそのまま', at: '2026-08-11 10:00');

      final ok = await repo.link(dir.path, saved.id,
          logRef: 'MSG-20260811-001', agreementRef: 'AGR-003');
      expect(ok, isTrue);

      final after = (await repo.readAll(dir.path)).single;
      expect(after.logRef, 'MSG-20260811-001');
      expect(after.agreementRef, 'AGR-003');
      expect(after.body, '原文はそのまま');
    });

    test('存在しない ID なら false', () async {
      await add(direction: 'inbound', body: 'A', at: '2026-08-11 10:00');
      expect(await repo.link(dir.path, 'MSGR-19990101-001', logRef: 'X'),
          isFalse);
    });
  });

  group('render', () {
    test('月別プレビューを doc/preview/messages/ に書く', () async {
      await add(
          direction: 'inbound',
          body: '受信本文',
          at: '2026-08-11 10:00',
          channel: 'coconala');
      await add(
          direction: 'outbound', body: '送信本文', at: '2026-08-11 11:00');

      final usecase = RenderMessagesUsecase(
        repo: repo,
        renderMonth: MessagePreviewPresenter.renderMonth,
        writeFile: (path, content) async {
          final file = File(path);
          await file.parent.create(recursive: true);
          await file.writeAsString(content);
        },
      );

      final months = await usecase.execute(dir.path);
      expect(months, ['2026-08']);

      final preview =
          File('${dir.path}/doc/preview/messages/2026-08.md').readAsStringSync();
      expect(preview, contains('自動生成'));
      expect(preview, contains('受信本文'));
      expect(preview, contains('送信本文'));
      expect(preview, contains('受信 1 / 送信 1'));
    });
  });
}
