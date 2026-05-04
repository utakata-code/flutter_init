# Changelog

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
