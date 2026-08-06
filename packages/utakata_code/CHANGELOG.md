# Changelog

## 1.4.0

* **feat(templates)** ([#15](https://github.com/utakata-code/utakata/issues/15)): The package now bundles only what commands need at runtime — `arch_definition.yaml` + `skills/` per architecture (44KB, down from 628KB). Reading material (layer guides, principles, dependency notes) is fetched on demand from the official [utakata_arch_lib](https://github.com/utakata-code/utakata_arch_lib) at a version-pinned tag, cached under `~/.utakata/cache/` (one fetch, then silent). Structural commands (`create`/`apply`/`check`/`feature add`) never touch the network; only guide reads do, and a fetch failure degrades with a clear message instead of breaking anything. `utakata arch get` with no `knowledge_repo` configured now pre-warms this cache (useful before going offline).
* **feat(apply)** ([#13](https://github.com/utakata-code/utakata/issues/13)): `apply`/`feature add` no longer write per-directory GUIDE.md files into `lib/features/` — the last hold-out against the reference-only knowledge principle. Guides are read via `guide show` / `guide for <file>` / MCP `guide_get`. Existing GUIDE.md files are left untouched (they may be hand-edited); `utakata doctor` reports how many remain and notes they are safe to delete if unmodified.
* **fix(i18n)**: 18 command/subcommand descriptions (`claude`, `skills`, `vault`, `doc show/list`, `plan expand/add/remove`, `guide for`, `arch get`, `agree correct/reflect`, `log import`) and their flag help texts were hardcoded in Japanese and leaked into English `--help` output; all now go through `CliMessages`. Three stale descriptions that referenced deleted files/commands (`plan` → feature_request.yaml, `diff` → plan_architecture.yaml, `feature` → bulk-generate) were rewritten.

## 1.3.0

* **feat(vault)**: New `vault:` config — a reference to a personal knowledge repo of **client-facing** know-how (how to obtain an Apple Developer account, what Firebase costs, whether a LINE channel needs review). Distinct from `knowledge_repo`, which holds architecture knowledge. `path` (a local clone) takes precedence over `url`, because a vault is something you keep writing yourself and round-tripping through push/fetch on every edit is impractical; `url` supports private repos via your existing git auth.
* **feat(config)**: New global config `~/.utakata/config.yaml`, same schema as a project's `utakata.yaml`. A vault spans all client projects, so it belongs there; a project's `utakata.yaml` still overrides it.
* **feat(vault)**: New `utakata vault list|show|get`, plus MCP tools `vault_list` / `vault_get`. Root-level `README.md`/`CLAUDE.md`/`_*.md` are treated as repo scaffolding and hidden from the listing, while nested `README.md` files (e.g. `Google/GCP/README.md` holding shared prerequisites) are real entries. Reads are confined to the vault root.
* **feat(claude)**: New generated skill `utakata-client-explainer` — writes client-facing explanations from the vault instead of from memory, checks each entry's recorded verification date before quoting prices or review requirements, never writes to the vault, and leaves sending and logging (`log add`, `agree add`) to the human.

## 1.2.0

* **docs**: New `doc/` reference for the two config files — [`doc/plan-yaml.md`](doc/plan-yaml.md) (`doc/specs/plan.yaml`: features, entities, per-layer `layers:` declarations, and how item names map to filenames) and [`doc/utakata-yaml.md`](doc/utakata-yaml.md) (`utakata.yaml`: architecture resolution order, `knowledge_repo`, `skills` sync rules, `team`). Keys that are parsed but not yet wired to behavior (`enforcement.impl_plan`, `records.git`, `lang`, `baseline`) are documented as reserved rather than claimed as working.
* **feat(doc)**: New `utakata doc show <config|plan|index>` and `utakata doc list` — the bundled reference is readable from inside any project, so it always matches the installed version. Also exposed as the MCP `doc_get` tool, and referenced from the generated `utakata-structure` skill and `CLAUDE.md` ("don't guess the YAML — run `utakata doc show plan`").

## 1.1.0

* **feat(plan)** ([#12](https://github.com/utakata-code/utakata/issues/12)): `plan.yaml` features gain an optional `layers:` map, so declaring a feature no longer means every layer is planned. Keyed by architecture layer path (architecture-agnostic):
  * **key omitted** — unchanged behavior: derive the expected files from `entities` (auto-generation stays the baseline)
  * **list of items** — only those files are required, even in layers whose naming is free-form (e.g. `1_domain/3_usecases: [get_todo, save_todo]` requires `get_todo_usecase.dart` / `save_todo_usecase.dart`). An item ending in `.dart` is taken as a literal filename
  * **empty list `[]`** — that layer is not applicable: it is neither required nor generated, and a parent path opts out its whole subtree (e.g. `4_presentation/1_widgets: []`)
* **feat(plan)**: New `utakata plan expand [--dry-run] [--feature <name>]` — materializes the auto-derived per-layer lists into `plan.yaml` (block style, comments preserved) so they can be edited by hand. Layers whose naming is non-deterministic are deliberately left out rather than written as `[]`, since an empty list means "not applicable"; add those with `plan add`. Already-declared layers are never overwritten.
* **feat(plan)**: New `utakata plan add <feature> <layer> <item...>` and `utakata plan remove <feature> <layer> <item>` — format-preserving per-item editing for AI agents and scripts.
* **feat(apply)**: `apply` skips layers declared as not applicable instead of recreating their directories.

## 1.0.2

* **fix(doc)** ([#14](https://github.com/utakata-code/utakata/issues/14)): `utakata doc init` now generates `doc/specs/plan.yaml`. Previously it created an empty `doc/specs/` directory, so `check`/`apply` failed with "plan.yaml not found" immediately after init — the documented quick-start flow did not work. `doc init` is now file-wise idempotent: it fills in whatever is missing (including a deleted `plan.yaml` in an already-initialized project) and never overwrites existing files.
* **fix(arch)** ([#11](https://github.com/utakata-code/utakata/issues/11)): `guide list/show/eject` ignored `project.architecture` in `utakata.yaml` and always used `clean_architecture`, so an MVVM project got Clean Architecture guides. Architecture resolution is now centralized in a single `ArchitectureResolver` (explicit `--arch` → `utakata.yaml` → `plan.yaml` → `clean_architecture`) and applied consistently to `guide list/show/eject`, `feature add --arch`, and the MCP `guide_get` tool (which had the same defect while its sibling `guide_for_file` resolved correctly).

## 1.0.1

* **feat(claude)**: New `utakata claude init [--force]` — adds or repairs the Claude Code integration (`.claude/` skills+agent+settings, `.mcp.json`, `CLAUDE.md`) in an existing project, so it's no longer only available at `create` time. Default mode writes missing files only (existing files, including user-edited skills, are untouched); `--force` regenerates everything including `CLAUDE.md`.
* **fix(skills)**: `doc init`'s commented `skills:` example suggested `utakata-structure`, which is a create-generated generic skill, not an architecture skill — following the example made `skills sync` report not-found. The example now shows a real architecture skill id, and the not-found warning lists the architecture's actually-available skill ids.

## 1.0.0

**First public release.** utakata is now a project orchestrator for client + developer + AI-agent collaboration on Flutter apps: a master config (`utakata.yaml`) with team roles, an intent-level plan (`doc/specs/plan.yaml`), one-pass structural checking, human-write-only client records with agreement tracking, reference-only knowledge synced from [utakata_arch_lib](https://github.com/utakata-code/utakata_arch_lib) (optionally overridden per-project and SHA-pinned via `utakata.lock`), and first-class Claude Code integration (hooks, managed skills, `CLAUDE.md`, and a read-only MCP server). The 0.6.0–0.17.0 entries below are the unreleased development milestones that make up this release.

## 0.17.0

* **feat(log)**: New `utakata log import claude-session [--list|--last|--session <id>] [--full] [-y]` — human-driven import of Claude Code session transcripts into `doc/records/sessions/<date>_<id>.jsonl` (normalized `{ts, role, text, session, seq}` schema) with a Markdown preview under `doc/preview/sessions/`. Defaults keep only user/assistant text (thinking, tool calls, and subagent sidechains excluded; `--full` adds thinking and tool names, never tool results). Secret-looking content (API keys, bearer tokens, private keys, AWS keys, env assignments) is replaced with `[REDACTED]` and counted, and an interactive preview/confirmation guards every import. The AI-side deny rules on `doc/records/**` continue to apply — importing is a human action.

## 0.16.0

* **feat(guide)**: New `utakata guide for <file> [--json]` — deterministically resolves the layer guide for a file path under `lib/features/` (permission and direct layouts, deepest guide wins). Intended as fix-context for lint errors: pass the reported file, get the guide to follow.
* **feat(mcp)**: Two new read-only tools — `guide_for_file` (same resolution over MCP) and `config_get` (returns `utakata.yaml` including `team`, so an agent can learn who decides what without reading files).

## 0.15.0

* **feat(skills)**: New `utakata skills sync [--force]` — syncs the architecture's bundled SKILLs listed under `skills:` in `utakata.yaml` into `.claude/skills/`, with a managed marker (`<!-- utakata:managed from=<arch>/<id> hash=... -->`). Conflict rules: files without the marker (human-created) are never touched, even with `--force`; unmodified managed files are updated in place; human-edited managed files are skipped unless `--force`. Delisted managed skills are reported as removal candidates but never auto-deleted.

## 0.14.0

* **feat(arch)**: New `utakata arch get [--update]` — fetches the opt-in `project.knowledge_repo` declared in `utakata.yaml` (git, depth-1) into `~/.utakata/cache/knowledge/`, materializes it into the bundled-template layout, and pins the resolved commit SHA in `utakata.lock`. Idempotent while the lock and cache are valid; `--update` re-resolves the ref and reports the SHA change.
* **feat(resolution)**: Template/guide/architecture resolution now goes local override → locked remote cache (only when `knowledge_repo` is configured) → bundled templates. Projects without `knowledge_repo` behave exactly as before, fully offline. `arch list` merges bundled and remote-cached architectures (remote wins on id conflict).

## 0.13.0

* **refactor(templates)**: Bundled templates are now synced from [utakata_arch_lib](https://github.com/utakata-code/utakata_arch_lib) via `tool/sync_arch_lib.dart` (single source of truth). New bundle layout: `architectures/<id>/{arch_definition.yaml, principles/, layers/, dependencies/, skills/}` — the legacy `AI/` and `.agent/` trees are gone.
* **refactor(create)**: Generated projects no longer receive a copy of the knowledge tree (`AI/`). Knowledge is reference-only: `utakata guide show/eject` and the MCP `guide_get` tool resolve it from the bundle (or, later, a fetched knowledge repo). Projects now consist of the Flutter app + `doc/` + `utakata.yaml` + `.claude/` + `CLAUDE.md` only.
* **chore(templates)**: `.tmpl` files are abolished. `feature add`/`apply` scaffold directories and dynamically generated GUIDE.md from `arch_definition.yaml`; local `.tmpl` overrides in a project's `AI/architecture/features/` still work. The last bundled script (`build_native_ios.sh`) is no longer shipped.

## 0.12.0

* **feat(config)**: `utakata.yaml` is now the project's master config (`schema: 1`), parsed by every command. New optional sections: `project.knowledge_repo` (opt-in remote knowledge repo, used from 0.14.0), `skills` (list synced by the upcoming `skills sync`), and `team` (client/developer/ai_agents roles).
* **feat(config)**: `project.architecture` in `utakata.yaml` now takes precedence over `doc/specs/plan.yaml`; a stderr warning is printed when both are explicitly set and disagree.
* **feat(claude)**: `utakata create` now also generates a project-level `CLAUDE.md` — with a "who decides what" team-roles section when `team:` is defined — pointing the agent at `doc/summary.md`, `doc/specs/plan.yaml`, and the read-only `doc/records/`. An existing `CLAUDE.md` is never overwritten.
* **feat(doctor)**: `utakata doctor` validates `utakata.yaml` (unknown top-level keys, unsupported future `schema`).
* **feat(doc)**: `utakata doc init` writes the new master-config template with commented `team:`/`skills:`/`knowledge_repo:` examples.

## 0.11.0

* **feat(mcp)**: New `utakata mcp` — stateless stdio JSON-RPC 2.0 MCP server (hand-rolled, no external SDK dependency). Exposes 6 read-only tools: `structure_get`, `check_run`, `plan_get`, `log_query`, `agreements_query`, `guide_get`. No write tools are exposed (AI stays read-only for records; see 0.8.0).
* **chore**: Removed the deprecated `scan`, `validate`, `feature init`, `core` commands and their aliases. `diff` remains as a permanent alias for `check` (kept for compatibility with existing implementation-plan documents that reference "utakata diff").
* **chore(templates)**: Stopped bundling `.agent/` and the deprecated `AI/scripts/*.sh` (superseded by CLI commands since 0.5.x) in generated projects; `AI/scripts/build/build_native_ios.sh` is kept as it has no CLI equivalent.

## 0.10.0

* **feat(guide)**: New `utakata guide list/show/eject` — browse an architecture's layer guides and copy one locally to start customizing (single-file copy with an origin comment; no hash/manifest tracking).
* **feat(arch)**: `arch create` renamed to `arch eject`; `arch create` kept as a deprecated alias.
* **feat(claude)**: `utakata create` now also generates `.mcp.json` and `.claude/` (settings.json with SessionStart/PostToolUse/Stop hooks and deny rules for `doc/records/**`, two skills, one agent).
* **feat(feature)**: New `feature add <name> --template <id>` — applies a feature preset (permission + entities) from a `manifest.yaml`, resolved from the project or `~/.utakata/feature_templates/`. No preset content (auth/payment/etc.) ships yet — the mechanism only.

## 0.9.0

* **feat(agree)**: New `agree add/status/correct/reflect/list` — append-only agreement tracking (`doc/records/agreements.jsonl`). Corrections create a new entry and mark the original `superseded` rather than rewriting it.
* **feat(impl)**: New `impl new/list/done/archive` — feature implementation plan lifecycle (`doc/impl/PLAN-NNNN_{feature}.md`, frontmatter-only machine state, free-form Markdown body).
* **feat(summary)**: New `utakata summary` — regenerates the `<!-- utakata:begin agreements -->` marker section of `doc/summary.md` from the agreement ledger (title/items/status/amount/sources, and a total for agreed client amounts), leaving hand-written sections untouched.

## 0.8.0

* **feat(log)**: New `utakata log add/show/render` — structured client conversation log (`doc/records/log/YYYY-MM.jsonl`, append-only, human-write-only). `log render` regenerates a per-day Markdown preview with ID anchors.
* **feat(doc)**: New `utakata doc init` — creates the `doc/` workspace (specs/records/preview/impl/knowledge/archive) + `utakata.yaml` ahead of `create`, for the pre-contract phase.
* **feat(doctor)**: New `utakata doctor [--migrate]` — diagnoses the project and migrates the legacy `AI/`-based layout (and a real project's ad-hoc `doc/` layout) to the new one. Dry-run by default with a confirmation prompt.

## 0.7.0

* **refactor(check)**: New canonical structure model (`StructurePath`/`StructureNode`/`ExpectedStructure`/`CheckReport`) replaces the separate `diff`/`validate` scans. `NameRuleMatcher` resolves naming rules by path-segment suffix instead of substring `.contains()`, fixing a real bug where a parent directory's naming rule leaked into its own `exceptions/` subdirectory. Directories where a naming rule can't produce a deterministic filename (e.g. `3_usecases/`) now allow any file matching the rule's regex instead of always flagging it as extra.
* **feat(plan)**: New intent-level `doc/specs/plan.yaml` (schema: 1, supports multiple `entities` per feature) replaces the generated `plan_architecture.yaml`. Falls back read-only to the legacy `AI/specs/feature_request.yaml` if `plan.yaml` doesn't exist yet.
* **feat(check)**: `check` now supports `--json` and `--file <path>`.
* **feat(apply)**: New `apply [--scope all|feature|core] [--dry-run]` consolidates `feature init` + `core` on the same expected-structure model `check` uses.
* **feat(plan)**: New `plan adopt` detects features present in `lib/features/` but missing from `plan.yaml` and appends them (format-preserving, via `package:yaml_edit`) after confirmation.
* **chore**: `scan`, `diff`, `validate`, `feature init`, `core` become deprecated aliases delegating to `check`/`apply` (still functional, print a warning).

## 0.6.0

* **fix**: Removed all silent `catch (_)` blocks in favor of typed exception handling; `getAll()` now warns to stderr on broken architecture definitions instead of silently skipping them.
* **fix**: `YamlDataSource.parse()` now throws on malformed YAML instead of returning `null` (previously conflated "missing" and "malformed").
* **perf**: `flutter` executable resolution is now lazy (on first use) instead of at startup, so commands that don't need `flutter` (`plan`, `check`, `status --brief`, ...) no longer fail when it's not on `PATH`.
* **fix(status)**: `flutter analyze` is now scoped to `lib/` and `test/` (previously the whole project, including noise from `build/`).
* **refactor**: Unified four divergent, disagreeing `_toSnakeCase`/`_toPascalCase`/`_toCamelCase` implementations into a single `CaseConverter` service.
* **chore**: `lib/src/version.g.dart` is now generated from `pubspec.yaml` (`tool/generate_version.dart`) instead of hardcoded in `command_runner.dart`.
* **chore**: Removed the unused `io` package dependency and four exception classes that were never thrown.

## 0.5.8

* **fix(diff)**: Flattened `direct` permission group in `planFeatures` to align with the actual physical file structure in `lib/features/` which does not nest direct features under a `direct` folder.

## 0.5.7

* **fix(version)**: Fixed hardcoded version display in `utakata --version` — now correctly shows the current version
* **feat(status)**: `utakata status` now also generates `AI/snapshots/preview/project_status.md` Markdown preview
* **docs**: Added English `README.md`, renamed original to `README_ja.md`

## 0.5.6

* **feat(status)**: `utakata status` now also generates `AI/snapshots/preview/project_status.md` — a human-readable Markdown preview of the project status with ✅/❌ icons, tables, and feature count

## 0.5.5

* **feat(core)**: New `utakata core` command — generates Core directory structure dynamically from `arch_definition.yaml` `core_modules` (replaces hardcoded `generate_core.sh`)
* **feat(core)**: `--arch` option to specify architecture (auto-detects from `feature_request.yaml` if omitted)
* **feat(status)**: `utakata status` now scans the project and writes real-time data to `AI/snapshots/project_status.yaml` — tracks `project.name/version`, `flutter`, `core` modules, `entry_points`, `documents`, and `features.count`
* **refactor(status)**: Core modules in `project_status.yaml` are now dynamically generated from `arch_definition.yaml` instead of hardcoded
* **chore(template)**: Removed unused legacy files `actual_architecture.yaml`, `change_history.yaml` and their previews from both `clean_architecture` and `mvvm` templates

## 0.5.4

* **fix(diff)**: Fixed root key mismatch between `plan_architecture.yaml` (has `features:` root) and `scanFeaturesStructure` (returns contents directly) — `utakata diff` / `utakata check` were falsely reporting `features` as Missing and permission folders as Extra
* **fix(validate)**: Applied the same root key extraction fix to `utakata validate` directory structure comparison

## 0.5.3

* **feat(template/mvvm)**: Expanded MVVM (3-layer) architecture template to match `clean_architecture` completeness — added **GUIDE.md** for all 8 layer directories (`1_model/{entities,repositories,services,exceptions}`, `2_viewmodel/{states,notifiers}`, `3_view/{widgets,screens}`)
* **feat(template/mvvm)**: Added full architecture guides (`guides/README.md`, `arch_summary.md`, `directory_structure_and_naming_rules.md`, `common/collaboration.md`, `dependencies/core_stack.yaml` + `.md`)
* **feat(template/mvvm)**: Added Core layer guides (`core/core_architecture.md`, `routing/`, `theme/`, `di/`, `api/`) with MVVM-specific DI guidance
* **feat(template/mvvm)**: Added `entry_point_guide.md` for `main.dart` / `app.dart` setup
* **feat(template/mvvm)**: Added `AI/specs/` templates (`feature_request.yaml`, `structure_plan.md`, `application_specification.md`) matching clean_architecture format
* **feat(template/mvvm)**: Copied `AI/scripts/`, `AI/snapshots/`, `AI/logs/` from clean_architecture
* **feat(template/mvvm)**: Added `.agent/` directory with rules, skills, workflows — all content adapted for MVVM (3-layer Model→ViewModel→View ordering, DI in `core/di/`, Service instead of UseCase, Screen instead of Page)
* **refactor(template/mvvm)**: Enriched `arch_definition.yaml` guides section with `apply_to`, `detail_content_path`, `do_list`, `dont_list`, `allowed_imports`, `forbidden_imports` for all 9 layer guides

## 0.5.2

* **feat(verify)**: Switched verification commands (`utakata diff`, `utakata check`, `utakata validate`, `utakata status`) to use **real-time directory scanning** instead of reading saved snapshot files. They now scan disk changes dynamically and auto-update `current_structure.yaml` in the background (no longer requiring manual `utakata scan` before diff/check).
* **refactor(plan)**: Reverted plan architecture structure back to nested **`features.{permission}.{featureName}`** format to completely align with physical folder structure, resolving false validation errors when permission folders are present.

## 0.5.1

* **fix(plan)**: Corrected `feature_request.yaml` template file in clean_architecture. Changed `features` default from `[]` (List) to `{}` (Map) and updated the commented example to Map format to align with `utakata plan` parser expectations (was failing with `planMissingFeaturesKey` exception).
* **feat(feature)**: Skip placeholder `.dart` files generation during `utakata feature add` and `utakata feature init`. Now only architecture directory structure and `GUIDE.md` files are generated, avoiding template boilerplates.

## 0.5.0

* **feat(multi-arch)**: `utakata plan` now dynamically generates architecture plans from `arch_definition.yaml` — no longer hardcoded to Clean Architecture
* **feat(multi-arch)**: Added `architecture` field to `feature_request.yaml` (`project.architecture` for project default, per-feature override also supported)
* **feat(template)**: Added **MVVM (3-layer)** as a built-in architecture template (`1_model` / `2_viewmodel` / `3_view`)
* **feat(diff)**: `utakata diff` now compares file names (`__files__`) when present in `plan_architecture.yaml`, enabling file-level progress tracking
* **feat(validate)**: `utakata validate` auto-detects `architectureId` from `feature_request.yaml` (`--arch` flag still available for override)
* **fix(validate)**: Exclude `.freezed.dart` / `.g.dart` generated files from naming rule validation
* **fix(validate)**: Skip `exceptions/` subdirectories from parent naming rule matching (was causing false positives)
* **fix(validate)**: Skip `__files__` key in directory structure comparison (was reporting 67+ false Extra violations)
* **fix(diff)**: Smart `__files__` comparison — only compare file names when plan explicitly defines them; ignore extra files not in plan
* **refactor(plan)**: Flat output format (`features.{name}`) instead of permission-grouped (`features.{perm}.{name}`)
* **refactor(init)**: `feature init` reads `permission` and `architectureId` from `feature_request.yaml` instead of plan structure
* **fix(naming)**: Relaxed `1_local` data source pattern from `_local_data_source.dart` to `_data_source.dart` (directory already implies locality)
* **fix(naming)**: `{feature}` placeholder in `arch_definition.yaml` `description` for application/presentation layer files (state, providers, notifiers, pages)

## 0.4.0

* **feat(template)**: Restructured `AI/` directory — introduced `AI/architecture/` to consolidate all architecture-specific resources (guides, features, core, arch_definition.yaml)
* **feat(template)**: Unified GUIDE.md and `.tmpl` templates — each layer directory now contains both the implementation guide and code template side by side
* **feat(template)**: Moved `arch_definition.yaml` and `features/` into `AI/architecture/` for cleaner separation of architecture-dependent vs generic resources
* **feat(create)**: Use `flutter create --empty` for clean project generation without boilerplate comments
* **refactor(template)**: Flattened `guides/architectures/clean_architecture/` → `architecture/guides/` to eliminate redundant nesting
* **chore**: Cleared legacy `change_history.yaml` template data

## 0.3.5

* **fix**: Added missing `.agent/` and `AI/` template files to `lib/src/templates/architectures/clean_architecture/` so they correctly generate in new projects.
* **fix**: Fixed the success message of `utakata create` command.

## 0.3.4

* **fix**: Fixed `ArchitectureNotFoundException` when running from a global pub activation. Switched to `Isolate.resolvePackageUri` for robust template path resolution instead of relying on `Platform.script` which varies between Dart versions.

## 0.3.3

* **feat(ux)**: Replaced the CLI brand header with a high-quality 3D ASCII art logo (ANSI Shadow font) for better cross-terminal rendering without distortions.

## 0.3.2

* **fix**: Resolve correct package template path when installed via `dart pub global activate` (was failing with `ArchitectureNotFoundException` due to `snapshots/` directory in `Platform.script`)

## 0.3.1


* **feat(ux)**: Display `utakata code` brand header (ASCII art, bright cyan) on startup when no command is specified

## 0.3.0


* **breaking**: Rebranded from `utakata` (v0.2.0) to the `utakata` package under the **utakata code** brand
* **feat**: Architecture-agnostic design — no longer hardcoded to Clean Architecture; architecture is defined by `arch_definition.yaml`
* **feat(validate)**: New `utakata validate` command — detects naming rule violations and directory structure violations based on `arch_definition.yaml`
* **feat(validate)**: Naming rules defined per-layer in `arch_definition.yaml` (`naming_rules:` section)
* **feat**: `arch_definition.yaml` now supports `guides_path:` field — directs users to the correct documentation on violation
* **feat(create)**: Generated projects now include `.agent/` and `AI/guides/architectures/` with architecture-specific guides
* **feat(i18n)**: Full internationalization — all CLI messages support English and Japanese via `MessagesResolver`
* **refactor**: Monorepo structure — CLI moved to `packages/utakata_code/` under the `utakata` repository
* **docs**: README rewritten in English; `README_ja.md` added for Japanese documentation

## 0.2.0

* **refactor**: Extract common YAML utilities (`YamlUtils`) — eliminates duplicated `_toYaml` / `_yamlToMd` logic across `snapshot` and `plan` commands
* **refactor**: Extract `StringUtils.toPascalCase()` — removes duplicate implementations in `generate` and `feature` commands
* **refactor**: Add `ProjectPaths` constants class — centralizes all hardcoded path strings (`AI/specs/`, `AI/snapshots/`, `lib/features/`) in one place
* **refactor**: Introduce `BaseCommand` base class — unifies error handling and blank-line output across all commands
* **fix(status)**: Replace fragile self-process re-execution (`Platform.script`) with direct `DiffCommand.checkDiff()` API call
* **refactor(feature)**: Split `FeatureGenerator` (393 lines) into per-layer generators (`DomainLayerGenerator`, `InfrastructureLayerGenerator`, `ApplicationLayerGenerator`, `PresentationLayerGenerator`)
* **refactor**: Replace `uri.pathSegments` path extraction with `p.basename()` for safety and consistency
* **rename**: `snapshot` → `scan` — clearer intent for scanning the current directory structure
* **rename**: `generate` → `sync` — better describes propagating Entity changes to each layer
* **rename**: `validate` → `check` — shorter and more intuitive

## 0.1.4

* **feat**: Add `utakata feature init` subcommand — bulk-generates all features defined in `AI/specs/plan_architecture.yaml` at once
* **feat**: Support `--dry-run` flag for `feature init` to preview targets without writing files

## 0.1.3

* **fix(windows)**: Add `runInShell: true` to all `Process.run` / `Process.start` calls to support Windows where `flutter` is `flutter.bat`

## 0.1.2

* **fix**: Replace LICENSE file with the full GNU GPL v3 text for proper pub.dev recognition
* **fix**: Change pubspec.yaml description to English to comply with pub.dev scoring
* **docs**: Rewrite README.md in English; add README_ja.md for Japanese documentation
* **feat**: Add `example/main.dart` for pub.dev example score

## 0.1.1

* **fix**: Change `feature_request.yaml` template from List format to Map format (fixes parse error in `plan` command)
* **feat**: Add optional Core layer configuration items as Map-format templates (all commented out by default)

## 0.1.0

* **feat**: Migrate all major features to a Dart-based CLI (`utakata`)
* **feat(create)**: Initialize Flutter projects with incremental dependency setup and Core package scaffolding
* **feat(feature add)**: Generate 4-layer directory structure and files based on Permission / Entity / Feature configuration
* **feat(generate)**: Auto-regenerate Domain / Infrastructure layer code from Freezed (v3) Entity field changes
* **feat(plan & snapshot & diff)**: Define ideal architecture from `feature_request.yaml` and detect/verify diff against the actual project structure
* **feat(validate & status)**: Add directory structure health checks and project analysis reporting
* **feat(AI Tooling)**: Output workflow and guideline templates enabling AI agents to develop without architectural drift
