import '../1_entities/config/knowledge_lock.dart';
import '../1_entities/config/utakata_config_entity.dart';

/// フェッチ結果。
class KnowledgeFetchResult {
  final KnowledgeLock lock;

  /// 更新前の SHA(初回フェッチ・SHA 不変時は null)。
  final String? previousSha;

  /// ネットワークフェッチが実際に走ったか(キャッシュ再利用時は false)。
  final bool refetched;

  const KnowledgeFetchResult({
    required this.lock,
    this.previousSha,
    required this.refetched,
  });
}

/// リモートナレッジリポジトリ(utakata_arch_lib 互換構造)の取得・キャッシュ管理。
///
/// オプトイン機能(実装計画 D2): `utakata.yaml` の `project.knowledge_repo` が
/// 指定された時だけ使われる。取得結果は `utakata.lock` で SHA 固定される。
abstract interface class KnowledgeRepository {
  Future<KnowledgeLock?> readLock(String projectDir);

  /// 現在の lock に対応する変換済みキャッシュ(`architectures/` 形式)の
  /// ルートを返す。lock が無い・キャッシュが無い場合は null。
  Future<String?> materializedRoot(String projectDir);

  /// フェッチする。lock 済み+キャッシュ有効なら何もしない(冪等)。
  /// [update] が true なら ref を再解決し、lock を更新する。
  Future<KnowledgeFetchResult> fetch(
    String projectDir,
    KnowledgeRepoRef repoRef, {
    bool update = false,
  });
}
