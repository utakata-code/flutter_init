import 'dart:io';

import '../../1_domain/messages/cli_messages.dart';
import '../4_server/mcp_server.dart';
import 'base_command.dart';

/// utakata mcp — MCP サーバーを起動する(stdio・読み取り専用)
class McpCommand extends BaseCommand {
  final McpServer _server;
  final CliMessages _msg;

  @override
  String get name => 'mcp';

  @override
  String get description => _msg.cmdMcpDesc;

  McpCommand(this._server, this._msg);

  @override
  Future<int> execute() async {
    await _server.serve(Directory.current.path);
    return 0;
  }
}
