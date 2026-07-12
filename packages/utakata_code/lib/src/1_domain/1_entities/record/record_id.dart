/// 会話ログ・合意・実装計画の ID 値オブジェクト(仕様書 §7.4)。
///
/// 接頭辞が種別ごとに一意なため、裸 ID 1トークンで相互参照できる。
/// 採番はカウンタファイルを持たず「既存 ID の max+1」(単独運用前提)。
sealed class RecordId {
  final String value;
  const RecordId(this.value);

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is RecordId && other.runtimeType == runtimeType && other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

final class MsgId extends RecordId {
  const MsgId(super.value);

  static final _pattern = RegExp(r'^MSG-(\d{8})-(\d{3})$');

  static bool matches(String raw) => _pattern.hasMatch(raw);

  /// [date]: yyyyMMdd、[seq]: その日の連番(1始まり)
  factory MsgId.forDate(DateTime date, int seq) {
    final ymd = '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
    return MsgId('MSG-$ymd-${seq.toString().padLeft(3, '0')}');
  }
}

final class AgrId extends RecordId {
  const AgrId(super.value);

  static final _pattern = RegExp(r'^AGR-(\d{4,})$');

  static bool matches(String raw) => _pattern.hasMatch(raw);

  factory AgrId.forSeq(int seq) => AgrId('AGR-${seq.toString().padLeft(4, '0')}');
}

final class PlanId extends RecordId {
  const PlanId(super.value);

  static final _pattern = RegExp(r'^PLAN-(\d{4,})$');

  static bool matches(String raw) => _pattern.hasMatch(raw);

  factory PlanId.forSeq(int seq) => PlanId('PLAN-${seq.toString().padLeft(4, '0')}');
}
