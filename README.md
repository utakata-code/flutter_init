# utakata — by utakata code

> **Spec-driven development for client + developer + AI-agent collaboration on Flutter apps**

[![pub.dev](https://img.shields.io/pub/v/utakata.svg)](https://pub.dev/packages/utakata)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

**utakata code** develops this toolkit for Flutter app development.

[日本語版 README はこちら](README_ja.md)

---

## About This Repository

This is the monorepo for the **utakata CLI** (pub.dev: [`utakata`](https://pub.dev/packages/utakata)) — a project orchestrator that lets a client, a developer, and AI agents work on one Flutter project safely:

- **Master config (`utakata.yaml`)** — architecture, team roles (who decides what), AI skills, and an optional remote knowledge repo pinned by commit SHA (`utakata.lock`)
- **Intent-level plan (`doc/specs/plan.yaml`)** + one-pass structural checking (`check` / `apply`)
- **Human-write-only client records** — conversation log, agreement ledger, per-feature implementation plans; AI agents read them but can never write (enforced by host-level deny rules)
- **Reference-only knowledge** — guides live in [utakata_arch_lib](https://github.com/utakata-code/utakata_arch_lib), bundled at release and never copied into your project
- **Claude Code native** — `.mcp.json`, hooks, managed skills, `CLAUDE.md`, and a read-only MCP server (8 tools)

Full command reference: [packages/utakata_code/README.md](packages/utakata_code/README.md)

### Evolution

| Version | Description |
|---|---|
| `flutter_init` | Flutter new-project template (.agent/ + AI/) for human–AI co-development |
| `utakata` v0.2–0.3 | Template logic extracted into a Dart CLI, monorepo integration, architecture-agnostic |
| `utakata` v0.4–0.5 | Multi-architecture support (Clean Architecture / MVVM), dynamic GUIDE generation |
| `utakata` **v1.0.0** (current) | Project orchestrator: master config, canonical structure model, client records, knowledge externalization, Claude Code integration |

---

## Repository Structure

```
utakata/
├── AI/                    # This repo's own working documents
│   ├── specs/             # Design docs (application spec, structure plan, implementation plan)
│   └── logs/              # Development conversation log
├── packages/
│   └── utakata_code/      # The CLI tool (pub.dev: utakata)
├── v1.0.0.md              # v1.0.0 concept document
├── v1.0.0_review.md       # Pre-implementation review (with dated addenda)
└── v1.0.0_result.md       # Post-implementation retrospective
```

Related repository: [utakata_arch_lib](https://github.com/utakata-code/utakata_arch_lib) — the architecture knowledge library (Clean Architecture / MVVM / `_starter` kit for user-defined architectures). Its content is synced into the CLI's bundled templates at release time; projects may override it via `utakata.yaml` → `knowledge_repo`.

---

## Quick Start

```bash
dart pub global activate utakata

utakata doc init                       # doc/ workspace + utakata.yaml (pre-contract phase)
utakata create my_app --org com.example
utakata apply --scope feature          # scaffold whatever plan.yaml declares
utakata check                          # missing / extra / naming violations in one pass
```

Details: [packages/utakata_code/README.md](packages/utakata_code/README.md) · [pub.dev/packages/utakata](https://pub.dev/packages/utakata)

---

## License

Dual license: [GNU GPL v3](LICENSE) for personal / open-source use; commercial use requires a separate license — contact [@code_utakata](https://x.com/code_utakata).

© [utakata code](https://github.com/utakata-code)
