# Claude Code Starter Kit

**Version:** 1.0.0 (xem CHANGELOG.md)

Bộ skills, scripts, templates rút ra từ kinh nghiệm phát triển dự án thực tế (~200+ PRs, 10+ waves). Được quản lý như internal package với versioning và review process.

## Dùng khi nào?

- Bắt đầu dự án mới → workflow chuẩn từ ngày đầu
- Dự án đã có → tiếp nhận best practices không overwrite customizations
- Dự án phát hiện cải tiến → đóng góp ngược vào kit cho các dự án khác

## 3 Scenarios

### 1. Dự án MỚI

```bash
./init-project.sh /path/to/new-project
```

### 2. Dự án ĐÃ CÓ skills/workflows

```bash
./upgrade-project.sh /path/to/project --dry-run    # Preview
./upgrade-project.sh /path/to/project               # Interactive (keep/use/merge per file)
./upgrade-project.sh /path/to/project --scripts     # Chỉ scripts
./upgrade-project.sh /path/to/project --skills      # Chỉ skills
./upgrade-project.sh /path/to/project --memory      # Chỉ memories
```

Version tracking tự động — skip nếu đã trên latest version.

### 3. Đóng góp cải tiến từ dự án → kit

```bash
# Bước 1: Tạo proposal (KHÔNG tự động apply)
./contribute.sh /path/to/project "Cải thiện TDD skill sau incident X"

# Bước 2: Review proposal
./contribute.sh --list
cat .proposals/<id>.proposal

# Bước 3: Nếu approved → apply + bump version
./contribute.sh --apply <proposal-id>

# Bước 4: Update CHANGELOG.md + commit
```

## Quy trình đóng góp (Governance)

```
Dự án A phát hiện cải tiến
        ↓
  contribute.sh → tạo proposal
        ↓
  Review checklist:
    ✅ Generic (không project-specific)?
    ✅ Cải thiện chất lượng (không chỉ preference)?
    ✅ Backward compatible?
    ✅ CHANGELOG entry?
        ↓
  --apply → bump MINOR version
        ↓
  Kit v1.1.0 released
        ↓
  Dự án B, C: upgrade-project.sh
        ↓
  Nhận cải tiến, giữ customizations
```

## Cấu trúc

```
starter-kit/
├── VERSION                ← Semantic versioning (1.1.1)
├── CHANGELOG.md           ← Lịch sử thay đổi
├── README.md              ← File này
├── EXTRACTION-GUIDE.md    ← Hướng dẫn extract thành repo riêng
├── init-project.sh        ← Setup dự án mới
├── upgrade-project.sh     ← Import vào dự án đã có (version-aware)
├── install-remote.sh      ← Install/upgrade từ remote git repo
├── contribute.sh          ← Đề xuất cải tiến (proposal → review → apply)
├── .claude-plugin/
│   ├── plugin.json        ← Plugin metadata (name, version, skills)
│   └── marketplace.json   ← Marketplace registration
├── skills/
│   ├── core/              ← Brainstorm, TDD, Review, Debug, Breakdown
│   ├── workflow/          ← Git, PR, CI process
│   ├── quality/           ← Audit framework 100 điểm
│   └── reference/         ← Business docs 3-layer, service docs
├── scripts/
│   ├── check-ci.sh        ← CI monitoring (--status mode)
│   ├── test-local.sh      ← Local test runner (auto-detect, --quick)
│   └── pre-commit-check.sh ← Pre-commit checks (extensible)
├── templates/
│   ├── CLAUDE.md.template
│   └── README.md.template
├── memory/                ← Seed memories (lessons learned)
└── .proposals/            ← Pending contribution proposals
```

## Versioning

| Type | Khi nào | Ví dụ |
|------|---------|-------|
| MAJOR (x.0.0) | Breaking changes (đổi cấu trúc skill, bỏ script) | 2.0.0 |
| MINOR (1.x.0) | Thêm skill/script/rule mới | 1.1.0 |
| PATCH (1.0.x) | Fix bug, cải thiện nội dung | 1.0.1 |

Mỗi dự án track installed version tại `.claude/.starter-kit-version`.

## Distribution

Starter-kit có thể cài đặt qua 3 cách:

### 1. Plugin (recommended — future)
```bash
# Sau khi kit được extract thành repo riêng:
/plugin install claude-starter-kit
```

### 2. Remote script
```bash
# Clone và cài từ GitHub
git clone https://github.com/VictorAurelius/claude-starter-kit.git /tmp/kit
bash /tmp/kit/install-remote.sh /path/to/project

# Hoặc one-liner:
curl -sSL https://raw.githubusercontent.com/VictorAurelius/claude-starter-kit/main/install-remote.sh | bash -s /path/to/project
```

### 3. Manual copy (legacy)
```bash
cp -r starter-kit/ /path/to/project/.claude/starter-kit/
bash /path/to/project/.claude/starter-kit/init-project.sh /path/to/project
```

Xem chi tiết extraction tại [EXTRACTION-GUIDE.md](EXTRACTION-GUIDE.md).

## Lessons Learned (seed memories)

| Rule | Nguồn gốc |
|------|-----------|
| Scripts not ad-hoc | Vi phạm 4+ lần → mỗi lần fix skill + memory |
| CI phải complete trước scoring | Kết luận sai → mất credibility |
| Test local trước push | 5s local vs 9min CI wait |
| Business docs trước code | 188 PRs → 22 gaps → 39 PRs fix |
