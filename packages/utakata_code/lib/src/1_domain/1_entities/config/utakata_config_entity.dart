/// `utakata.yaml`(プロジェクトのマスター設定。実装計画 S1)のエンティティ群。
///
/// 全フィールドが任意。ファイルが無い・キーが無い場合はすべて既定値で
/// 動作し、既存プロジェクト(utakata.yaml なし)の挙動を一切変えない。
library;

/// リモートナレッジリポジトリへの参照(オプトイン。実装計画 D2)。
///
/// 未指定ならパッケージ同梱テンプレートを使い、ネットワークに依存しない。
final class KnowledgeRepoRef {
  final String url;

  /// タグ/ブランチ名。解決されたコミット SHA は `utakata.lock` に固定される(S3)。
  final String? ref;

  const KnowledgeRepoRef({required this.url, this.ref});

  factory KnowledgeRepoRef.fromMap(Map<String, dynamic> map) =>
      KnowledgeRepoRef(
        url: map['url'] as String,
        ref: map['ref'] as String?,
      );
}

/// 実務ナレッジ Vault への参照。
///
/// アーキテクチャ知識([KnowledgeRepoRef])とは別物で、外部サービスの
/// アカウント取得手順・料金・審査要否など「クライアントへの説明に使う知識」を
/// 蓄積したリポジトリを指す。
///
/// Vault は開発者本人が書き足していく個人資産のため、[path](手元のクローン)を
/// 第一の参照先とし、無い場合のみ [url] からフェッチする。これにより
/// 編集のたびに push → fetch する必要がない。
final class VaultRef {
  /// 手元のクローンへのパス(`~` 展開あり)。指定時はこちらが優先。
  ///
  /// 相対パスは「この設定が書かれたファイルの場所」基準で解決される
  /// (プロジェクトの `utakata.yaml` ならプロジェクトルート、
  /// `~/.utakata/config.yaml` なら `~/.utakata/`。Issue #18)。
  final String? path;

  /// リモート Git URL(プライベートリポジトリ可。認証は git の設定に委ねる)。
  final String? url;

  /// タグ/ブランチ名。
  final String? ref;

  const VaultRef({this.path, this.url, this.ref});

  /// 空文字は「未設定」とみなす(空文字で解決順のフォールバックを
  /// 遮断してしまわないように)。
  bool get isEmpty =>
      (path == null || path!.isEmpty) && (url == null || url!.isEmpty);

  factory VaultRef.fromMap(Map<String, dynamic> map) => VaultRef(
        path: map['path'] as String?,
        url: map['url'] as String?,
        ref: map['ref'] as String?,
      );
}

/// AI エージェント1体の定義(`team.ai_agents` の1要素)。
final class AiAgentDef {
  final String id;
  final String role;

  const AiAgentDef({required this.id, required this.role});

  factory AiAgentDef.fromMap(Map<String, dynamic> map) => AiAgentDef(
        id: (map['id'] ?? '') as String,
        role: (map['role'] ?? '') as String,
      );
}

/// 登場人物と役割(v1.0.0 コンセプト §2-B)。
///
/// AI エージェントに「誰の言うことを聞き、誰に判断を仰ぐべきか」を
/// 機械可読に与えるための定義。
final class TeamDef {
  final String? client;
  final String? developer;
  final List<AiAgentDef> aiAgents;

  const TeamDef({this.client, this.developer, this.aiAgents = const []});

  static const empty = TeamDef();

  bool get isEmpty => client == null && developer == null && aiAgents.isEmpty;

  factory TeamDef.fromMap(Map<String, dynamic> map) {
    final rawAgents = map['ai_agents'];
    return TeamDef(
      client: map['client'] as String?,
      developer: map['developer'] as String?,
      aiAgents: rawAgents is List
          ? rawAgents
              .whereType<Map>()
              .map((m) => AiAgentDef.fromMap(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
    );
  }
}

/// `utakata.yaml` 全体。
final class UtakataConfig {
  static const currentSchema = 1;

  /// 検証で未知キーを検出するための既知トップレベルキー一覧。
  static const knownTopLevelKeys = {
    'schema',
    'project',
    'skills',
    'team',
    'enforcement',
    'records',
    'lang',
    'vault',
  };

  final int schema;

  /// `project.architecture`。指定時は plan.yaml の値より優先される(D6)。
  final String? architecture;

  final KnowledgeRepoRef? knowledgeRepo;

  /// `.claude/skills/` に同期する SKILL の有効リスト(S4 で使用)。
  final List<String> skills;

  final TeamDef team;

  /// 実務ナレッジ Vault への参照(`vault:`)。
  /// 全案件で共通の個人資産のため、`~/.utakata/config.yaml` に書くのが基本で、
  /// プロジェクトの `utakata.yaml` に書けばそちらが優先される。
  final VaultRef? vault;

  /// `enforcement.impl_plan`: 'on' | 'off'
  final String implPlanEnforcement;

  /// `records.git`: 'commit' | 'ignore'
  final String recordsGit;

  final String? lang;

  const UtakataConfig({
    this.schema = currentSchema,
    this.architecture,
    this.knowledgeRepo,
    this.skills = const [],
    this.team = TeamDef.empty,
    this.vault,
    this.implPlanEnforcement = 'on',
    this.recordsGit = 'commit',
    this.lang,
  });

  factory UtakataConfig.fromMap(Map<String, dynamic> map) {
    final project = map['project'];
    String? architecture;
    KnowledgeRepoRef? knowledgeRepo;
    if (project is Map) {
      architecture = project['architecture'] as String?;
      final repo = project['knowledge_repo'];
      if (repo is Map && repo['url'] is String) {
        knowledgeRepo = KnowledgeRepoRef.fromMap(Map<String, dynamic>.from(repo));
      }
    }

    final rawVault = map['vault'];
    final rawSkills = map['skills'];
    final team = map['team'];
    final enforcement = map['enforcement'];
    final records = map['records'];

    return UtakataConfig(
      schema: (map['schema'] as int?) ?? currentSchema,
      architecture: architecture,
      knowledgeRepo: knowledgeRepo,
      skills: rawSkills is List ? rawSkills.map((e) => e.toString()).toList() : const [],
      team: team is Map ? TeamDef.fromMap(Map<String, dynamic>.from(team)) : TeamDef.empty,
      vault: rawVault is Map
          ? VaultRef.fromMap(Map<String, dynamic>.from(rawVault))
          : null,
      implPlanEnforcement: enforcement is Map
          ? (enforcement['impl_plan']?.toString() ?? 'on')
          : 'on',
      recordsGit: records is Map ? (records['git']?.toString() ?? 'commit') : 'commit',
      lang: map['lang'] as String?,
    );
  }
}
