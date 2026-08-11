import 'dart:convert';
import 'dart:io';

import '../../1_domain/1_entities/structure/check_report.dart';
import '../../1_domain/3_usecases/check_usecase.dart';
import '../../1_domain/2_repositories/config_repository.dart';
import '../../1_domain/3_usecases/architecture_resolver.dart';
import '../../1_domain/3_usecases/guide_for_file_usecase.dart';
import '../../1_domain/1_entities/record/message_record.dart';
import '../../1_domain/2_repositories/message_repository.dart';
import '../../1_domain/2_repositories/vault_repository.dart';
import '../../1_domain/3_usecases/show_doc_usecase.dart';
import '../../1_domain/3_usecases/guide_usecase.dart';
import '../../1_domain/3_usecases/list_agreements_usecase.dart';
import '../../1_domain/3_usecases/query_log_usecase.dart';
import '../../1_domain/2_repositories/plan_repository.dart';

/// `utakata mcp` — stdio 上の最小 JSON-RPC 2.0 MCP サーバー(仕様書 §11.3)。
///
/// ステートレス: ツール呼び出しごとに毎回スキャン・読み込みを行い、
/// キャッシュや常駐状態を一切持たない(P1/P2)。公開ツールは全て
/// 読み取り専用(P8: 記録は人間、AI は読み取り専用)。
///
/// `package:dart_mcp` 等の外部 SDK には依存せず、プロトコルの
/// 必要最小部分(initialize / tools/list / tools/call)のみを自前実装する。
class McpServer {
  final CheckUsecase _checkUsecase;
  final PlanRepository _planRepo;
  final QueryLogUsecase _queryLogUsecase;
  final ListAgreementsUsecase _listAgreementsUsecase;
  final GuideUsecase _guideUsecase;

  final GuideForFileUsecase? _guideForFileUsecase;
  final ConfigRepository? _configRepo;
  final ArchitectureResolver? _archResolver;
  final ShowDocUsecase? _showDocUsecase;
  final VaultRepository? _vaultRepo;
  final MessageRepository? _messageRepo;

  McpServer({
    required CheckUsecase checkUsecase,
    required PlanRepository planRepo,
    required QueryLogUsecase queryLogUsecase,
    required ListAgreementsUsecase listAgreementsUsecase,
    required GuideUsecase guideUsecase,
    GuideForFileUsecase? guideForFileUsecase,
    ConfigRepository? configRepo,
    ArchitectureResolver? archResolver,
    ShowDocUsecase? showDocUsecase,
    VaultRepository? vaultRepo,
    MessageRepository? messageRepo,
  })  : _checkUsecase = checkUsecase,
        _planRepo = planRepo,
        _queryLogUsecase = queryLogUsecase,
        _listAgreementsUsecase = listAgreementsUsecase,
        _guideUsecase = guideUsecase,
        _guideForFileUsecase = guideForFileUsecase,
        _configRepo = configRepo,
        _archResolver = archResolver,
        _showDocUsecase = showDocUsecase,
        _vaultRepo = vaultRepo,
        _messageRepo = messageRepo;

  static const _protocolVersion = '2024-11-05';

  static final _tools = [
    {
      'name': 'structure_get',
      'description': '現在の plan.yaml の意図と対応するアーキテクチャ定義を返す(読み取り専用)',
      'inputSchema': {'type': 'object', 'properties': {}},
    },
    {
      'name': 'check_run',
      'description': '構造差分+命名違反を検出する(utakata check 相当)',
      'inputSchema': {'type': 'object', 'properties': {}},
    },
    {
      'name': 'plan_get',
      'description': 'plan.yaml の内容を返す',
      'inputSchema': {'type': 'object', 'properties': {}},
    },
    {
      'name': 'log_query',
      'description': 'お客様会話ログを検索する(書き込みツールは提供しない)',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'thread': {'type': 'string'},
          'tag': {'type': 'string'},
          'date': {'type': 'string'},
        },
      },
    },
    {
      'name': 'agreements_query',
      'description': '合意の一覧を返す',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'unreflected_only': {'type': 'boolean'},
        },
      },
    },
    {
      'name': 'guide_get',
      'description': '指定レイヤーのガイド内容を返す',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'architecture_id': {'type': 'string'},
          'layer_path': {'type': 'string'},
        },
        'required': ['layer_path'],
      },
    },
    {
      'name': 'guide_for_file',
      'description': 'ファイルパスから該当レイヤーのガイドを決定論的に解決する(lint エラー修正時のコンテキスト供給用)',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'file_path': {'type': 'string', 'description': 'lib/features/ 配下のファイルパス'},
        },
        'required': ['file_path'],
      },
    },
    {
      'name': 'config_get',
      'description': 'utakata.yaml(マスター設定)の内容を返す。team(誰の決定に従うか)を含む',
      'inputSchema': {'type': 'object', 'properties': {}},
    },
    {
      'name': 'doc_get',
      'description': '設定ファイル(utakata.yaml / plan.yaml)の書き方リファレンスを取得する',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'topic': {
            'type': 'string',
            'description': 'config = utakata.yaml / plan = doc/specs/plan.yaml '
                '/ imports = import_rules / records = doc/records の扱い',
            'enum': ShowDocUsecase.topics.keys.toList(),
          },
        },
        'required': ['topic'],
      },
    },
    {
      'name': 'vault_list',
      'description':
          'クライアント説明用の実務ナレッジ Vault(外部サービスのアカウント取得手順・料金・審査要否など)のエントリ一覧',
      'inputSchema': {'type': 'object', 'properties': {}},
    },
    {
      'name': 'vault_get',
      'description':
          'Vault のエントリ本文を取得する。クライアント向け説明文を書く前に、必ずここで一次情報と検証日時を確認する',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'entry_id': {
            'type': 'string',
            'description': 'vault_list が返す id(例: Google/GCP/Firebase)',
          },
        },
        'required': ['entry_id'],
      },
    },
  ];

  /// 送受信原文の参照ツール(v1.6.0)。
  ///
  /// 原文は既定で AI に見せない。`utakata.yaml` の
  /// `records.agent_read.messages: true` のときだけ tools/list に載せる
  /// (公開しなければ呼べない = 最も確実な保護)。
  static final _messageTool = {
    'name': 'message_query',
    'description': 'クライアントとの送受信原文を検索する(読み取り専用)',
    'inputSchema': {
      'type': 'object',
      'properties': {
        'direction': {'type': 'string', 'description': 'inbound | outbound'},
        'channel': {'type': 'string'},
        'thread': {'type': 'string'},
        'month': {'type': 'string', 'description': 'YYYY-MM'},
        'id': {'type': 'string'},
      },
    },
  };

  /// このプロジェクトで公開するツール一覧(設定で増減する)。
  ///
  /// utakata.yaml が壊れていてもサーバーを落とさない — 既定(原文は非公開)に
  /// 倒して既存ツールだけを返す。
  Future<List<Map<String, dynamic>>> _visibleTools(String projectDir) async {
    var allowMessages = false;
    try {
      final config = await _configRepo?.read(projectDir);
      allowMessages =
          (config?.agentCanReadMessages ?? false) && _messageRepo != null;
    } catch (_) {
      allowMessages = false;
    }
    return [..._tools, if (allowMessages) _messageTool];
  }

  /// stdin から1行ずつ JSON-RPC リクエストを読み、stdout に応答を書く。
  /// stdin が閉じたら(EOF)終了する(プロセス残留を作らない)。
  Future<void> serve(String projectDir) async {
    final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in lines) {
      if (line.trim().isEmpty) continue;
      Map<String, dynamic> request;
      try {
        request = jsonDecode(line) as Map<String, dynamic>;
      } on FormatException {
        continue;
      }
      final response = await _handle(request, projectDir);
      if (response != null) {
        stdout.writeln(jsonEncode(response));
      }
    }
  }

  Future<Map<String, dynamic>?> _handle(
    Map<String, dynamic> request,
    String projectDir,
  ) async {
    final method = request['method'] as String?;
    final id = request['id'];

    // notification(id なし)は応答不要
    if (id == null) return null;

    switch (method) {
      case 'initialize':
        return _result(id, {
          'protocolVersion': _protocolVersion,
          'serverInfo': {'name': 'utakata', 'version': '1'},
          'capabilities': {'tools': {}},
        });
      case 'tools/list':
        return _result(id, {'tools': await _visibleTools(projectDir)});
      case 'tools/call':
        return _callTool(id, request, projectDir);
      default:
        return _error(id, -32601, 'Method not found: $method');
    }
  }

  Future<Map<String, dynamic>> _callTool(
    dynamic id,
    Map<String, dynamic> request,
    String projectDir,
  ) async {
    final params = request['params'] as Map<String, dynamic>? ?? {};
    final toolName = params['name'] as String?;
    final args = params['arguments'] as Map<String, dynamic>? ?? {};

    try {
      // 可視性の判定は**実行前**に行う。非公開ツール(設定でオフの
      // message_query 等)は一切データに触れずに拒否する。
      final visible = await _visibleTools(projectDir);
      if (toolName == null || !visible.any((t) => t['name'] == toolName)) {
        return _error(id, -32602, 'Unknown tool: $toolName');
      }

      final Object? payload = switch (toolName) {
        'structure_get' => (await _planRepo.read(projectDir))?.toMap(),
        'check_run' => _checkReportToMap(await _checkUsecase.execute(projectDir)),
        'plan_get' => (await _planRepo.read(projectDir))?.toMap(),
        'log_query' => (await _queryLogUsecase.execute(
            projectDir,
            thread: args['thread'] as String?,
            tag: args['tag'] as String?,
            date: args['date'] != null ? DateTime.parse(args['date'] as String) : null,
          ))
            .map((e) => {'id': e.id, 'at': e.at.toIso8601String(), 'body': e.body})
            .toList(),
        'agreements_query' => (await _listAgreementsUsecase.execute(
            projectDir,
            unreflectedOnly: (args['unreflected_only'] as bool?) ?? false,
          ))
            .map((a) => {'id': a.id, 'title': a.title, 'status': a.status.name})
            .toList(),
        // architecture_id 未指定なら utakata.yaml / plan.yaml から解決する(Issue #11)
        'guide_get' => await _guideUsecase.show(
            await _resolveArchId(projectDir, args['architecture_id'] as String?),
            args['layer_path'] as String,
          ),
        'guide_for_file' => await _guideForFileUsecase
            ?.execute(projectDir, args['file_path'] as String)
            .then((r) => r == null
                ? null
                : {'layer_path': r.layerPath, 'guide': r.guide}),
        'config_get' => await _configRepo?.read(projectDir).then((c) => c == null
            ? null
            : {
                'schema': c.schema,
                'architecture': c.architecture,
                'skills': c.skills,
                'team': {
                  'client': c.team.client,
                  'developer': c.team.developer,
                  'ai_agents': [
                    for (final a in c.team.aiAgents) {'id': a.id, 'role': a.role}
                  ],
                },
              }),
        'doc_get' => await _showDocUsecase?.execute(args['topic'] as String),
        'vault_list' => (await _vaultRepo?.list(projectDir))
            ?.map((e) => {'id': e.id, 'title': e.title})
            .toList(),
        'vault_get' =>
          await _vaultRepo?.read(projectDir, args['entry_id'] as String),
        'message_query' => await _queryMessages(projectDir, args),
        _ => null,
      };

      return _result(id, {
        'content': [
          {'type': 'text', 'text': jsonEncode(payload)}
        ],
      });
    } on Exception catch (e) {
      return _result(id, {
        'isError': true,
        'content': [
          {'type': 'text', 'text': e.toString()}
        ],
      });
    } on ArgumentError catch (e) {
      // 引数の検証失敗(不正な direction 等)。ArgumentError は Exception では
      // ないため個別に捕捉しないとサーバーごと落ちる。
      return _result(id, {
        'isError': true,
        'content': [
          {'type': 'text', 'text': (e.message ?? e).toString()}
        ],
      });
    }
  }

  /// `message_query` の実体。公開されている場合のみ到達する。
  Future<List<Map<String, dynamic>>?> _queryMessages(
    String projectDir,
    Map<String, dynamic> args,
  ) async {
    final repo = _messageRepo;
    if (repo == null) return null;
    final directionRaw = args['direction'] as String?;
    final records = await repo.query(
      projectDir,
      direction: directionRaw != null
          ? MessageRecord.directionFromString(directionRaw)
          : null,
      channel: args['channel'] as String?,
      thread: args['thread'] as String?,
      month: args['month'] as String?,
      id: args['id'] as String?,
    );
    return records
        .map((r) => {
              'id': r.id,
              'direction': MessageRecord.directionToString(r.direction),
              'at': r.at.toIso8601String(),
              if (r.channel != null) 'channel': r.channel,
              if (r.from != null) 'from': r.from,
              if (r.to != null) 'to': r.to,
              if (r.subject != null) 'subject': r.subject,
              'body': r.body,
              if (r.thread != null) 'thread': r.thread,
              if (r.logRef != null) 'log_ref': r.logRef,
              if (r.agreementRef != null) 'agreement_ref': r.agreementRef,
            })
        .toList();
  }

  Future<String> _resolveArchId(String projectDir, String? explicit) async {
    final resolver = _archResolver;
    if (resolver == null) {
      return explicit ?? ArchitectureResolver.fallbackArchitectureId;
    }
    return resolver.resolve(projectDir, explicit: explicit);
  }

  Map<String, dynamic> _checkReportToMap(CheckReport report) => {
        'clean': report.isClean,
        'missing': report.missingPaths,
        'extra': report.extraPaths,
        'namingViolations': report.namingViolations
            .map((v) => {'file': v.filePath, 'expected': v.expectedPattern})
            .toList(),
      };

  Map<String, dynamic> _result(dynamic id, Map<String, dynamic> result) =>
      {'jsonrpc': '2.0', 'id': id, 'result': result};

  Map<String, dynamic> _error(dynamic id, int code, String message) =>
      {'jsonrpc': '2.0', 'id': id, 'error': {'code': code, 'message': message}};
}
