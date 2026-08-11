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

    test('dry-run のプレビュー ID は実行時と同じ連番になる', () async {
      final source = [
        jsonEncode({
          'direction': 'inbound',
          'at': '2026-08-10T09:00:00',
          'body': '一件目',
        }),
        jsonEncode({
          'direction': 'outbound',
          'at': '2026-08-10T10:00:00',
          'body': '二件目',
        }),
      ].join('\n');

      final preview = await import.execute(dir.path,
          content: source,
          format: 'jsonl',
          now: now,
          recordedBy: 'haruma',
          dryRun: true);
      final actual = await import.execute(dir.path,
          content: source, format: 'jsonl', now: now, recordedBy: 'haruma');

      expect(preview.map((r) => r.record.id).toList(),
          ['MSGR-20260810-001', 'MSGR-20260810-002']);
      expect(preview.map((r) => r.record.id).toList(),
          actual.map((r) => r.record.id).toList());
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

  group('レビュー指摘の回帰(1.6.0)', () {
    test('日時のない md は同一本文でも別メッセージとして残る', () async {
      const source = '''
## [inbound] 山田様
承知しました。

## [outbound]
ではこちらで進めます。

## [inbound] 山田様
承知しました。
''';
      final results = await import.execute(dir.path,
          content: source,
          format: 'md',
          now: now,
          recordedBy: 'haruma',
          sourceKey: 'thread.md');

      expect(results.where((r) => !r.skipped).length, 3);
      expect((await repo.readAll(dir.path)).length, 3);
    });

    test('日時のない md でも同じソースの再取り込みは増えない', () async {
      const source = '## [inbound] 山田様\n承知しました。\n';
      await import.execute(dir.path,
          content: source,
          format: 'md',
          now: now,
          recordedBy: 'haruma',
          sourceKey: 'thread.md');
      final again = await import.execute(dir.path,
          content: source,
          format: 'md',
          now: now,
          recordedBy: 'haruma',
          sourceKey: 'thread.md');

      expect(again.single.skipped, isTrue);
      expect((await repo.readAll(dir.path)).length, 1);
    });

    test('external_id が別なら同一本文・同一日時でも両方残る', () async {
      final source = [
        jsonEncode({
          'direction': 'inbound',
          'at': '2026-08-11T10:24:00',
          'body': '了解です',
          'external_id': 'm1',
        }),
        jsonEncode({
          'direction': 'inbound',
          'at': '2026-08-11T10:24:00',
          'body': '了解です',
          'external_id': 'm2',
        }),
      ].join('\n');

      final results = await import.execute(dir.path,
          content: source, format: 'jsonl', now: now, recordedBy: 'haruma');
      expect(results.where((r) => !r.skipped).length, 2);
    });

    test('欠番があっても既存 ID を再発行しない', () async {
      final file = File('${dir.path}/doc/records/messages/2026-08.jsonl')
        ..createSync(recursive: true);
      file.writeAsStringSync([
        jsonEncode({
          'id': 'MSGR-20260811-001',
          'direction': 'inbound',
          'at': '2026-08-11T10:00:00',
          'body': 'A',
          'recorded_at': '2026-08-11T10:00:00',
          'recorded_by': 'haruma',
        }),
        jsonEncode({
          'id': 'MSGR-20260811-003',
          'direction': 'inbound',
          'at': '2026-08-11T12:00:00',
          'body': 'C',
          'recorded_at': '2026-08-11T12:00:00',
          'recorded_by': 'haruma',
        }),
      ].join('\n'));

      final saved =
          await add(direction: 'inbound', body: 'D', at: '2026-08-11 13:00');
      expect(saved.id, 'MSGR-20260811-004');
    });

    test('link は破損行と未知フィールドを保持する', () async {
      final file = File('${dir.path}/doc/records/messages/2026-08.jsonl')
        ..createSync(recursive: true);
      final valid = jsonEncode({
        'id': 'MSGR-20260811-001',
        'direction': 'inbound',
        'at': '2026-08-11T10:00:00',
        'body': 'A',
        'custom_note': '独自メモ',
        'recorded_at': '2026-08-11T10:00:00',
        'recorded_by': 'haruma',
      });
      file.writeAsStringSync('$valid\n{"id": "broken", oops\n');

      expect(await repo.link(dir.path, 'MSGR-20260811-001', logRef: 'MSG-1'),
          isTrue);

      final lines = file.readAsLinesSync().where((l) => l.trim().isNotEmpty);
      expect(lines.length, 2, reason: '破損行が消えてはいけない');
      final updated =
          jsonDecode(lines.first) as Map<String, dynamic>;
      expect(updated['log_ref'], 'MSG-1');
      expect(updated['custom_note'], '独自メモ', reason: '未知フィールドを消さない');
      expect(lines.last, contains('oops'));
    });

    test('スキーマ不正な行があっても読み出しは落ちない', () async {
      final file = File('${dir.path}/doc/records/messages/2026-08.jsonl')
        ..createSync(recursive: true);
      file.writeAsStringSync([
        jsonEncode({'id': 123, 'direction': 'inbound', 'body': 'A'}),
        jsonEncode({
          'id': 'MSGR-20260811-001',
          'direction': 'inbound',
          'at': '2026-08-11T10:00:00',
          'body': 'ok',
          'recorded_at': '2026-08-11T10:00:00',
          'recorded_by': 'haruma',
        }),
      ].join('\n'));

      final all = await repo.readAll(dir.path);
      expect(all.map((r) => r.body).toList(), ['ok']);
    });

    test('オフセット付きの日時はローカル日付で採番・保存される', () async {
      final saved = await add(
          direction: 'inbound', body: 'A', at: '2026-08-11T08:24:00+09:00');
      final local = DateTime.parse('2026-08-11T08:24:00+09:00').toLocal();
      final expectedDay =
          '${local.year}${local.month.toString().padLeft(2, '0')}'
          '${local.day.toString().padLeft(2, '0')}';
      expect(saved.id, 'MSGR-$expectedDay-001');
      expect(saved.at.isUtc, isFalse);
    });

    test('コードブロック内の見出し風の行では分割しない', () {
      const source = '''
## [inbound] 2026-08-11 10:00 山田様
以下の形式で送ってください。

```md
## [outbound] これは例です
```

以上です。
''';
      final drafts = ImportMessagesUsecase.parseMarkdown(source);
      expect(drafts.length, 1);
      expect(drafts.single.body, contains('以上です。'));
    });

    test('改行構造だけが違う本文は別レコードとして扱う', () async {
      final a = await add(
          direction: 'inbound', body: 'A\nB', at: '2026-08-11 10:00');
      final b = await add(
          direction: 'inbound', body: 'A B', at: '2026-08-11 10:00');
      expect(a.dedupeKey == b.dedupeKey, isFalse);
    });

    test('壊れた行を含む JSONL は該当行だけ飛ばして続行する', () {
      const source = '{"direction":"inbound","body":"ok","at":"2026-08-11T10:00:00"}\n'
          'not json\n'
          '{"direction":"sideways","body":"bad"}\n';
      final drafts = ImportMessagesUsecase.parseJsonl(source);
      expect(drafts.length, 1);
      expect(drafts.single.body, 'ok');
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
