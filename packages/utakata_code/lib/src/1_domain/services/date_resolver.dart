/// 日時文字列の解決を行う純関数サービス。
///
/// `--at "6/30 17:41"` のような年省略入力を、基準日時から見て
/// 「今日以前で最も近い日付」に補完する(仕様書 §7.1)。
/// 現在時刻への暗黙依存を避けるため、基準日時 [now] は呼び出し元
/// (usecase)が明示的に注入する。
abstract final class DateResolver {
  static final _monthDayTime = RegExp(
    r'^(\d{1,2})/(\d{1,2})(?:\s+(\d{1,2}):(\d{2}))?$',
  );

  /// [raw] が ISO 8601 ならそのまま解析し、`M/d[ H:mm]` 形式なら
  /// [now] を基準に年を補完する。
  static DateTime resolve(String raw, DateTime now) {
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    final match = _monthDayTime.firstMatch(raw.trim());
    if (match == null) {
      throw FormatException('Unrecognized date format: "$raw"');
    }

    final month = int.parse(match.group(1)!);
    final day = int.parse(match.group(2)!);
    final hour = match.group(3) != null ? int.parse(match.group(3)!) : 0;
    final minute = match.group(4) != null ? int.parse(match.group(4)!) : 0;

    var candidate = DateTime(now.year, month, day, hour, minute);
    if (candidate.isAfter(now)) {
      candidate = DateTime(now.year - 1, month, day, hour, minute);
    }
    return candidate;
  }
}
