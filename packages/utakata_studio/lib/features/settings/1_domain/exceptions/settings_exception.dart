/// 設定関連の例外
class SettingsException implements Exception {
  final String message;
  const SettingsException(this.message);

  @override
  String toString() => 'SettingsException: $message';
}
