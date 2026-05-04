import 'dart:io';

/// CLI 出力用のロガー
///
/// コマンド・ユースケースに依存せずどこからでも使えるシンプルなユーティリティ。
abstract final class Logger {
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';
  static const _cyan = '\x1B[36m';
  static const _dim = '\x1B[2m';
  static const _reset = '\x1B[0m';

  static void section(String msg) => stdout.writeln('\n$_cyan$msg$_reset');
  static void success(String msg) => stdout.writeln('$_green✅ $msg$_reset');
  static void warn(String msg) => stdout.writeln('$_yellow⚠️  $msg$_reset');
  static void error(String msg) => stderr.writeln('$_red❌ $msg$_reset');
  static void info(String msg) => stdout.writeln(msg);
  static void step(String msg) => stdout.writeln('  $_dim$msg$_reset');
  static void dim(String msg) => stdout.writeln('$_dim$msg$_reset');
}
