import 'dart:io';

import 'package:args/command_runner.dart';

import '../../1_domain/1_entities/record/impl_plan_meta.dart';
import '../../1_domain/3_usecases/impl_plan_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata impl — feature 実装計画の管理
class ImplCommand extends Command<int> {
  final CliMessages _msg;

  @override
  String get name => 'impl';
  @override
  String get description => _msg.cmdImplDesc;

  ImplCommand(ImplPlanUsecase usecase, this._msg) {
    addSubcommand(_ImplNewCommand(usecase, _msg));
    addSubcommand(_ImplListCommand(usecase, _msg));
    addSubcommand(_ImplDoneCommand(usecase, _msg));
    addSubcommand(_ImplArchiveCommand(usecase, _msg));
  }

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}

const _bodyTemplate = '''
# 実装計画

## 1. 背景・目的

【背景・目的を記載】

## 2. 現状整理・調査結果

| 項目 | 内容 |
|------|------|
| 【現状のコード】 | 【ファイルパス:行番号と要約】 |
| 【要求の根拠】 | 【出典と、合意済みか当方判断かの区別】 |

## 3. 設計方針(決定事項)

## 4. 変更ファイル一覧

| ファイル | 変更 |
|---------|------|

## 5. 実装ステップ

1. 【ステップ1】
2. `flutter analyze` → `utakata check`

## 6. テスト・検証計画

## 7. 文書更新

## 8. スコープ外
''';

class _ImplNewCommand extends BaseCommand {
  final ImplPlanUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'new';
  @override
  String get description => _msg.cmdImplNewDesc;

  _ImplNewCommand(this._usecase, this._msg) {
    argParser
      ..addOption('backlog', defaultsTo: '')
      ..addOption('agreement') // カンマ区切り
      ..addOption('spec')
      ..addOption('message')
      ..addOption('basis', allowed: ['client_agreed', 'developer_judgment']);
  }

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error('feature 名を指定してください: utakata impl new <feature>');
      return 1;
    }
    final feature = argResults!.rest.first;
    final basisRaw = argResults!['basis'] as String?;

    final id = await _usecase.create(
      Directory.current.path,
      feature: feature,
      backlog: argResults!['backlog'] as String,
      agreements: _splitCsv(argResults!['agreement'] as String?),
      specs: _splitCsv(argResults!['spec'] as String?),
      messages: _splitCsv(argResults!['message'] as String?),
      basis: basisRaw == 'client_agreed'
          ? ImplPlanBasis.clientAgreed
          : basisRaw == 'developer_judgment'
              ? ImplPlanBasis.developerJudgment
              : null,
      now: DateTime.now(),
      bodyTemplate: _bodyTemplate,
    );

    Logger.success(_msg.implNewDone(id, 'doc/impl/${id}_$feature.md'));
    return 0;
  }

  List<String> _splitCsv(String? raw) =>
      raw?.split(',').where((s) => s.isNotEmpty).toList() ?? const [];
}

class _ImplListCommand extends BaseCommand {
  final ImplPlanUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'list';
  @override
  String get description => _msg.cmdImplListDesc;

  _ImplListCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    final plans = await _usecase.list(Directory.current.path);
    if (plans.isEmpty) {
      Logger.warn(_msg.implListEmpty);
      return 0;
    }
    for (final plan in plans) {
      Logger.info('${plan.id}  [${ImplPlanMeta.statusToString(plan.status)}]  ${plan.feature}');
    }
    return 0;
  }
}

class _ImplDoneCommand extends BaseCommand {
  final ImplPlanUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'done';
  @override
  String get description => _msg.cmdImplDoneDesc;

  _ImplDoneCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error('実装計画 ID を指定してください: utakata impl done <ID>');
      return 1;
    }
    final id = argResults!.rest.first;
    await _usecase.markDone(Directory.current.path, id, now: DateTime.now());
    Logger.success(_msg.implDoneDone(id));
    return 0;
  }
}

class _ImplArchiveCommand extends BaseCommand {
  final ImplPlanUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'archive';
  @override
  String get description => _msg.cmdImplArchiveDesc;

  _ImplArchiveCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error('実装計画 ID を指定してください: utakata impl archive <ID>');
      return 1;
    }
    final id = argResults!.rest.first;
    await _usecase.archive(Directory.current.path, id);
    Logger.success(_msg.implArchiveDone(id));
    return 0;
  }
}
