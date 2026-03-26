# Starter Kit Changelog

Quản lý theo Semantic Versioning: `MAJOR.MINOR.PATCH`
- **MAJOR**: Thay đổi breaking (đổi cấu trúc skill, bỏ script)
- **MINOR**: Thêm skill/script/rule mới
- **PATCH**: Fix bug, cải thiện nội dung existing

---

## [1.1.1] — 2026-03-25

### Added
- `.claude-plugin/plugin.json` — Plugin metadata for Claude Code plugin registry
- `.claude-plugin/marketplace.json` — Marketplace registration for discovery
- `install-remote.sh` — Install/upgrade starter-kit from remote git repo
- `EXTRACTION-GUIDE.md` — Step-by-step guide to extract kit to standalone repo

### Changed
- `README.md` — Added Distribution section (3 install methods: plugin, remote script, manual)
- `skills/reference/diagrams.md` — 4 improvements:
  - **MUST** install Graphviz (`sudo apt install graphviz`) — without it PNGs show red error
  - **MUST** use `scripts/render-diagrams.sh` to render (not `java -jar` directly)
  - **MUST** verify rendered PNGs before commit (check for syntax errors, blank images)
  - **MUST** add `*.jar` + `documents/06-diagrams/tools/` to `.gitignore`

## [1.1.0] — 2026-03-25

### Added
- `templates/settings.local.json.template` — Claude Code permissions (bypass prompt)
- `templates/vscode-settings.json.template` — VS Code settings per language (Java, TS, Python, Go)
- `skills/reference/project-structure.md` — Folder structure best practice + anti-patterns + refactor checklist
- `skills/reference/ide-setup.md` — Claude permissions, VS Code config, test runners, MD warnings fix, common IDE warnings guide

- `skills/reference/diagrams.md` — PlantUML/Mermaid guide, tool comparison, minimum diagrams list
- `scripts/render-diagrams.sh` — Auto-render PlantUML + Mermaid, --check mode

### Changed
- `skills/_README-skills-index.md` — Added 3 new reference skills + 1 script

## [1.0.0] — 2026-03-24

### Initial Release
**Source:** Kite Class Platform (200+ PRs, 10+ waves)

#### Skills (9 files)
- core/brainstorming-methodology.md
- core/tdd-enforcement.md
- core/two-stage-code-review.md
- core/systematic-debugging.md
- core/task-breakdown-guide.md
- workflow/development-workflow.md
- quality/quality-audit.md
- reference/business-docs-3-layer.md
- reference/service-docs-standard.md

#### Scripts (3 files)
- check-ci.sh (with --status mode)
- test-local.sh (auto-detect, --quick mode)
- pre-commit-check.sh (extensible framework)

#### Seed Memories (4 files)
- Scripts not ad-hoc: dùng scripts cho mọi operation
- CI before scoring: đợi CI xong mới chấm điểm
- Self-test before push: test local trước push
- Business design first: docs trước code

#### Tools (3 scripts)
- init-project.sh: setup dự án mới
- upgrade-project.sh: import vào dự án đã có
- sync-to-kit.sh: đồng bộ từ dự án gốc

#### Templates (2 files)
- CLAUDE.md.template
- README.md.template
