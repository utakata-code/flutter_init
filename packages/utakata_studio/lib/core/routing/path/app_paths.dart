/// 画面パスの定数定義
///
/// すべての画面パスとルート名をここに集約する。
/// UI / フィーチャー側はこの定数を参照して遷移を実行する。
class AppPaths {
  AppPaths._();

  // ── メイン ──
  static const home = '/';
  static const homeRouteName = 'home';

  // ── 設定 ──
  static const settings = '/settings';
  static const settingsRouteName = 'settings';
}
