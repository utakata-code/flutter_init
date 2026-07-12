import 'dart:convert';
import 'dart:io';

import '../../1_domain/1_entities/structure/check_report.dart';
import '../../1_domain/3_usecases/check_usecase.dart';
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

  McpServer({
    required CheckUsecase checkUsecase,
    required PlanRepository planRepo,
    required QueryLogUsecase queryLogUsecase,
    required ListAgreementsUsecase listAgreementsUsecase,
    required GuideUsecase guideUsecase,
  })  : _checkUsecase = checkUsecase,
        _planRepo = planRepo,
        _queryLogUsecase = queryLogUsecase,
        _listAgreementsUsecase = listAgreementsUsecase,
        _guideUsecase = guideUsecase;

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
  ];

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
        return _result(id, {'tools': _tools});
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
        'guide_get' => await _guideUsecase.show(
            (args['architecture_id'] as String?) ?? 'clean_architecture',
            args['layer_path'] as String,
          ),
        _ => null,
      };

      if (toolName == null || !_tools.any((t) => t['name'] == toolName)) {
        return _error(id, -32602, 'Unknown tool: $toolName');
      }

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
    }
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
