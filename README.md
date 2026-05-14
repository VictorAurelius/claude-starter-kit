# 🤖 Claude Code Starter Kit

<p align="center">
  <strong>Battle-tested skills, rules & workflow templates for Claude Code — extracted from a real 200+ PR project. Governance-first. Bilingual.</strong>
</p>

<p align="center">
  <a href="https://github.com/VictorAurelius/claude-starter-kit/tags"><img src="https://img.shields.io/github/v/tag/VictorAurelius/claude-starter-kit?label=version" alt="Version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/VictorAurelius/claude-starter-kit" alt="License"></a>
  <a href="https://github.com/VictorAurelius/claude-starter-kit/stargazers"><img src="https://img.shields.io/github/stars/VictorAurelius/claude-starter-kit?style=social" alt="Stars"></a>
  <a href="https://github.com/VictorAurelius/claude-starter-kit/commits/main"><img src="https://img.shields.io/github/last-commit/VictorAurelius/claude-starter-kit" alt="Last commit"></a>
  <img src="https://img.shields.io/badge/Made%20with-Claude%20Code-FF6B35" alt="Made with Claude Code">
</p>

<p align="center">
  🇬🇧 English  |  🇻🇳 <a href="README.vi.md">Tiếng Việt</a>
</p>

---

## Why this exists

Most Claude Code starter content is either generic templates from official docs or curated link lists. This kit is different: it's a **drop-in package of governance + skills + workflow** distilled from a working 200+ PR project. Every rule was written because something broke. Every skill ships with its gotchas. Versioned with semver, upgradeable, contributable.

## What's inside

| Layer | Count | What it gives you |
|-------|------:|-------------------|
| **Rules** | 26 | Governance for gap closure, audits, deploy, AWS access, retry budgets, rule changes — each grounded in real incidents |
| **Skills** | 15 | Development methodology (TDD, brainstorming, debugging, code review, quality audit /100, UI review /128) with project-specific gotchas |
| **Scripts** | 5 | `check-ci.sh`, `test-local.sh`, `pre-commit-check.sh`, `render-diagrams.sh`, `capture-screenshots.ts` |
| **Bin tools** | 6 | `init-project.sh`, `upgrade-project.sh`, `install-remote.sh`, `contribute.sh`, `publish.sh`, `test-kit.sh` |
| **Memory seeds** | 4 | Lessons learned (`feedback_*`) ready to auto-load |
| **Templates** | 5+ | `CLAUDE.md`, `README.md`, skill folder scaffold, more |

## Quick start

```bash
# 1. New project — set up from scratch
./bin/init-project.sh /path/to/new-project

# 2. Existing project — absorb best practices without overwriting customizations
./bin/upgrade-project.sh /path/to/project --dry-run    # Preview first
./bin/upgrade-project.sh /path/to/project               # Interactive merge

# 3. Contribute improvements back to the kit
./bin/contribute.sh /path/to/project "Why this matters"
```

Full install guide: [docs/INSTALL.md](docs/INSTALL.md) · First-time setup: [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md)

## How this compares

| Approach | What you get | Gap |
|----------|--------------|-----|
| Anthropic official templates | Generic skill examples | No governance layer, no upgrade path |
| `awesome-claude-code` lists | Curated bookmarks | You still hand-roll every project |
| Hand-rolled `.claude/` per project | Full control | Drifts across projects; no semver; no contribute-back loop |
| **This kit** | **Battle-tested package + governance + upgrade scripts + bilingual docs** | — |

## Who this is for

- **Solo devs** who want governance discipline from day one without inventing rules incident-by-incident
- **Small teams** adopting Claude Code consistently — same skills, same rules, same review standards across projects
- **Existing projects** wanting to absorb tested patterns without rewriting everything

## Star history

[![Star History Chart](https://api.star-history.com/svg?repos=VictorAurelius/claude-starter-kit&type=Date)](https://star-history.com/#VictorAurelius/claude-starter-kit&Date)

## Contributing

Improvements welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the 4-question triage (Generalize / Stable / No project paths / Battle-tested) and the contribute-back workflow.

Be kind: [Code of Conduct](.github/CODE_OF_CONDUCT.md) · Security: [SECURITY.md](.github/SECURITY.md) · License: [MIT](LICENSE)

---

<p align="center">
  Built by <a href="https://github.com/VictorAurelius">@VictorAurelius</a> · Inspired by real-world Claude Code workflows · Star if useful ⭐
</p>
