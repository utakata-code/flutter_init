/// 記録の `recorded_by`(誰が記録したか)を解決する純関数サービス(v1.6.0)。
///
/// `records.agent_write: append` では AI エージェントも CLI 経由で記録を
/// 追記できる。人間の記録と混ざると後から区別できなくなるため、
/// エージェント側は `UTAKATA_ACTOR=agent:claude` を指定して実行する。
///
/// 解決順:
///   1. `UTAKATA_ACTOR`(明示。エージェント実行時に設定する)
///   2. `USER` / `USERNAME`(通常の人間の実行)
///   3. `unknown`
abstract final class ActorResolver {
  static const _actorEnv = 'UTAKATA_ACTOR';

  static String resolve(Map<String, String> environment) {
    final explicit = environment[_actorEnv];
    if (explicit != null && explicit.trim().isNotEmpty) return explicit.trim();
    return environment['USER'] ?? environment['USERNAME'] ?? 'unknown';
  }

  /// エージェントによる記録か(`agent:` プレフィックス)。
  static bool isAgent(String actor) => actor.startsWith('agent:');
}
