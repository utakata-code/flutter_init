# Changelog

## 0.5.3

* **feat(template/mvvm)**: Expanded MVVM (3-layer) architecture template to match `clean_architecture` completeness — added **GUIDE.md** for all 8 layer directories (`1_model/{entities,repositories,services,exceptions}`, `2_viewmodel/{states,notifiers}`, `3_view/{widgets,screens}`)
* **feat(template/mvvm)**: Added full architecture guides (`guides/README.md`, `arch_summary.md`, `directory_structure_and_naming_rules.md`, `common/collaboration.md`, `dependencies/core_stack.yaml` + `.md`)
* **feat(template/mvvm)**: Added Core layer guides (`core/core_architecture.md`, `routing/`, `theme/`, `di/`, `api/`) with MVVM-specific DI guidance
* **feat(template/mvvm)**: Added `entry_point_guide.md` for `main.dart` / `app.dart` setup
* **feat(template/mvvm)**: Added `AI/specs/` templates (`feature_request.yaml`, `structure_plan.md`, `application_specification.md`) matching clean_architecture format
* **feat(template/mvvm)**: Copied `AI/scripts/`, `AI/snapshots/`, `AI/logs/` from clean_architecture
* **feat(template/mvvm)**: Added `.agent/` directory with rules, skills, workflows — all content adapted for MVVM (3-layer Model→ViewModel→View ordering, DI in `core/di/`, Service instead of UseCase, Screen instead of Page)
* **refactor(template/mvvm)**: Enriched `arch_definition.yaml` guides section with `apply_to`, `detail_content_path`, `do_list`, `dont_list`, `allowed_imports`, `forbidden_imports` for all 9 layer guides



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
