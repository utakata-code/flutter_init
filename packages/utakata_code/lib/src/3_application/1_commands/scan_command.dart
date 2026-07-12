import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata scan — [廃止] no-op
///
/// スナップショット方式(current_structure.yaml)を廃止し、`check`/`apply`
/// が毎回その場で実構造をスキャンするようになったため、本コマンドは
/// 何もしない(仕様書 §3/§14)。v1.1 で削除予定。
class ScanCommand extends BaseCommand {
  final CliMessages _msg;

  @override
  String get name => 'scan';

  @override
  String get description => _msg.cmdScanDesc;

  ScanCommand(this._msg);

  @override
  Future<int> execute() async {
    Logger.warn(_msg.deprecatedAlias('scan', 'check'));
    return 0;
  }
}
