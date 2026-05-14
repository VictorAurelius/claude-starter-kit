# 🤖 Claude Code Starter Kit (Tiếng Việt)

<p align="center">
  🇻🇳 Tiếng Việt  |  🇬🇧 <a href="README.md">English</a>
</p>

---

**Version:** 2.4.1 (xem CHANGELOG.md)

Bộ skills, scripts, templates rút ra từ kinh nghiệm phát triển dự án thực tế (~200+ PRs, 10+ waves). Được quản lý như internal package với versioning và review process.

## Dùng khi nào?

- Bắt đầu dự án mới → workflow chuẩn từ ngày đầu
- Dự án đã có → tiếp nhận best practices không overwrite customizations
- Dự án phát hiện cải tiến → đóng góp ngược vào kit cho các dự án khác

## 3 Scenarios

### 1. Dự án MỚI

```bash
./bin/init-project.sh /path/to/new-project
```

### 2. Dự án ĐÃ CÓ skills/workflows

```bash
./bin/upgrade-project.sh /path/to/project --dry-run    # Preview
./bin/upgrade-project.sh /path/to/project               # Interactive
./bin/upgrade-project.sh /path/to/project --scripts     # Chỉ scripts
```

### 3. Đóng góp cải tiến từ dự án → kit

```bash
./bin/contribute.sh /path/to/project "Cải thiện TDD skill sau incident X"
./bin/contribute.sh --list
./bin/contribute.sh --apply <proposal-id>
```

Xem chi tiết: [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)

## Cấu trúc

```
starter-kit/
├── README.md              ← English (canonical)
├── README.vi.md           ← Tiếng Việt (file này)
├── LICENSE                ← MIT
├── VERSION                ← Semantic versioning
├── CHANGELOG.md           ← Lịch sử thay đổi
├── kit-manifest.yml       ← File classification for upgrades
│
├── bin/                   ← Kit management scripts
│   ├── init-project.sh        ← Setup dự án mới
│   ├── upgrade-project.sh     ← Import vào dự án đã có
│   ├── install-remote.sh      ← Install từ remote repo
│   ├── contribute.sh          ← Đề xuất cải tiến
│   ├── publish.sh             ← Publish new version
│   └── test-kit.sh            ← Test kit functionality
│
├── docs/                  ← Kit documentation
│   ├── INSTALL.md             ← Installation guide
│   ├── GETTING-STARTED.md     ← First-time setup guide
│   ├── CONTRIBUTING.md        ← Contribution governance
│   ├── EXTRACTION-GUIDE.md    ← Extract kit to standalone repo
│   └── assets/banner.svg      ← Social preview banner
│
├── rules/                 ← Conventions & standards (26 rules)
│   ├── skill-conventions.md   ← How to write skills (Anthropic best practices)
│   ├── rule-change-process.md ← ADR-like governance cho rule changes
│   ├── gap-done-discipline.md ← Định nghĩa "DONE" cho gap
│   ├── audit-to-gap-pipeline.md
│   ├── release-deploy-standard.md
│   └── ... (21 rules khác về meta-governance, deploy, AWS, retry)
│
├── skills/                ← Development methodology (gotchas, không generic)
│   ├── core/              ← Project-specific gotchas templates
│   ├── workflow/          ← Git, PR, CI process
│   ├── quality/           ← Audit framework 100 điểm
│   └── reference/         ← Business docs, UI templates, diagrams
│
├── scripts/               ← Reusable project automation
│   ├── check-ci.sh        ← CI monitoring
│   ├── test-local.sh      ← Local test runner
│   ├── pre-commit-check.sh
│   ├── render-diagrams.sh
│   └── capture-screenshots.ts
│
├── templates/             ← Ready-to-use templates
│   ├── CLAUDE.md.template
│   ├── README.md.template
│   ├── skill-folder/      ← Template cho new skills
│   └── *.template
│
├── examples/              ← Minimal example projects (mới v2.4.1)
│   ├── minimal-project/   ← Chỉ CLAUDE.md + kit pointer
│   └── with-governance/   ← Full governance stack demo
│
├── memory/                ← Seed memories (lessons learned)
├── .github/               ← Issue templates, PR template, CoC, Security
└── .claude-plugin/        ← Plugin registry metadata
```

## Versioning

| Type | Khi nào | Ví dụ |
|------|---------|-------|
| MAJOR (x.0.0) | Breaking changes (đổi cấu trúc, bỏ file) | 2.0.0 |
| MINOR (1.x.0) | Thêm skill/script/rule mới | 1.5.0 |
| PATCH (1.0.x) | Fix bug, cải thiện nội dung | 1.5.1 |

Xem [rules/skill-conventions.md](rules/skill-conventions.md) cho version management checklist.

## Triết lý

> Mỗi rule được viết vì có incident thật xảy ra. Mỗi skill ship kèm gotchas của nó. Không phải template chung chung — đây là kit thật từ dự án thật.

## Đóng góp

Welcome contributions! Xem [CONTRIBUTING.md](CONTRIBUTING.md) (root) hoặc [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) (chi tiết) — bao gồm 4-question triage (Generalize / Stable / No project paths / Battle-tested) và workflow contribute-back.

- [Code of Conduct](.github/CODE_OF_CONDUCT.md)
- [Security policy](.github/SECURITY.md)
- [License: MIT](LICENSE)

---

**Lưu ý:** Phiên bản chính thức (canonical) là [README.md](README.md) (English). File này dịch nguyên trạng theo v2.3.0 + v2.4.0 changes, cập nhật lại cấu trúc cho v2.4.1.

<p align="center">
  Built by <a href="https://github.com/VictorAurelius">@VictorAurelius</a> · Cảm hứng từ real-world Claude Code workflows · Star nếu hữu ích ⭐
</p>
