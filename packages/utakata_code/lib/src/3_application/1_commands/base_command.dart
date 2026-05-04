import 'dart:io';

import 'package:args/command_runner.dart';

/// utakata コマンドの基底クラス
///
/// args パッケージの Command を薄くラップする。
/// 実際の処理は execute() に委譲する。
abstract class BaseCommand extends Command<int> {
  @override
  Future<int> run() async {
    try {
      return await execute();
    } on Exception catch (e) {
      stderr.writeln('❌ $e');
      return 1;
    }
  }

  /// コマンドの本体処理。サブクラスで実装する。
  Future<int> execute();
}
