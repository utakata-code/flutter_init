import '../1_entities/config/utakata_config_entity.dart';

/// `utakata.yaml`(プロジェクトのマスター設定)の読み取り。
///
/// 書き込みは `doc init` の初期生成のみで、以降は人間が編集するファイル
/// のため、このリポジトリは読み取り専用インターフェースとする。
abstract interface class ConfigRepository {
  /// `utakata.yaml` を読む。存在しなければ null。
  Future<UtakataConfig?> read(String projectDir);

  /// `~/.utakata/config.yaml`(全案件共通の個人設定)を読む。
  /// 存在しなければ null。プロジェクトの `utakata.yaml` と同じスキーマだが、
  /// 意味を持つのは案件横断の項目(`vault` 等)のみ。
  Future<UtakataConfig?> readGlobal();

  /// スキーマ検証(未知トップレベルキー・非対応 schema)の問題一覧を返す。
  /// ファイルが無ければ空リスト(存在しないこと自体は doctor 側で扱う)。
  Future<List<String>> validate(String projectDir);
}
