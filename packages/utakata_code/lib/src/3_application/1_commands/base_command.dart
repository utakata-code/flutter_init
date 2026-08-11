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
    } on ArgumentError catch (e) {
      // 入力値の検証失敗(未来日時・不正な direction 等)は利用者のミスであり、
      // スタックトレースではなくメッセージだけを見せる。
      // ArgumentError は Exception ではなく Error なので個別に捕捉する。
      stderr.writeln('❌ ${e.message ?? e}');
      return 64; // EX_USAGE
    }
  }

  /// コマンドの本体処理。サブクラスで実装する。
  Future<int> execute();
}
