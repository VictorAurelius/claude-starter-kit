---
name: thesis
description: "Use khi user nói 'làm khóa luận', 'thesis V1', 'audit thesis', 'thesis ready to defense?', 'render thesis docx', hoặc trước khi ship academic deliverable. Workflow: planning → draft chapters → 3-agent outside-in audit → fix → assemble DOCX. Backed by thesis-content-standard.md rubric /100."
user-invocable: true
---

# Thesis — Vietnamese-University Bachelor/Engineer/Master Khóa Luận Workflow

Skill này hướng dẫn workflow ship academic deliverable (khóa luận tốt nghiệp) cho dự án phần mềm thực tế, chấm theo rubric `.claude/rules/thesis-content-standard.md` /100 (9 categories).

## Khi nào dùng

- Bạn dùng dự án thực tế (production code, 200+ commits) làm thesis topic
- Cần ship `thesis-v1.docx` cho academic submission (cử nhân / kỹ sư / thạc sĩ)
- Đại học VN: convention UTC/HUST/UET/HCMUT/BKHN (rule là opinionated cho VN scope)
- Universities khác: skill workflow vẫn áp dụng, rule §C1 cần adapt page-size + heading numbering

## Output

- 4-6 chapter MDs trong `documents/<thesis-dir>/` đạt rubric ≥75/100 C+
- `thesis-v1.docx` assembled từ chapter MDs (python-docx pipeline OR pandoc)
- 3 outside-in audit reports trong `documents/<your-audits-dir>/persona-review/`
- Bibliography IEEE format ≥30 entries (cử nhân) / ≥50 (kỹ sư) / ≥80 (thạc sĩ)

## Setup for your project

### 1. Create thesis directory structure

```bash
mkdir -p documents/<thesis-dir>/{chapters,references,figures,audits}
cp .claude/skills/document-generation/thesis/templates/thesis-info.md.template \
   documents/<thesis-dir>/thesis-info.md
cp .claude/skills/document-generation/thesis/templates/chapter-mapping.md.template \
   documents/<thesis-dir>/chapter-mapping.md
cp .claude/skills/document-generation/thesis/templates/bibliography.md.template \
   documents/<thesis-dir>/references/bibliography.md
```

### 2. Fill thesis-info.md

Update with your details:
- Student name, MSSV, lớp, khóa
- GVHD (advisor) name + title
- GVPB (reviewer) name + title (nếu đã được assign)
- School + faculty + department
- Thesis level (cử nhân / kỹ sư / thạc sĩ)
- Target page count per rule §4 cap
- Submission deadline + defense window

### 3. Customize rule per school

Edit `.claude/rules/thesis-content-standard.md` §C1 if your school's spec differs from VN baseline:
- Page size (default A4)
- Margins (default T=2.5 B=2.5 L=3.0 R=2.0 cm)
- Heading sizes (default TNR 13/14/16/18pt body/H3/H2/H1)
- Numbering convention (default `CHƯƠNG N.` / `N.M` / `N.M.P`)
- Bibliography style (default IEEE)

## Workflow

### Phase 1 — Planning (1-2 sessions)

**Goal:** chapter outline + bibliography seed + outside-in pre-audit

#### Step 1.1: Draft chapter outline

Create `documents/<thesis-dir>/chapter-mapping.md` per template. VN cử nhân CNTT typical:

1. **Chương 1 — Tổng quan** (background + scope + literature)
2. **Chương 2 — Cơ sở lý thuyết + Phân tích yêu cầu** (theory + business analysis)
3. **Chương 3 — Thiết kế hệ thống** (architecture + diagrams)
4. **Chương 4 — Triển khai và Kết quả** (implementation + KPI)
5. **KẾT LUẬN VÀ KIẾN NGHỊ** (conclusion + future work + đóng góp khoa học)

NOT: ghép Phân tích + Thiết kế vào 1 chương (anti-pattern per rule §C2).

#### Step 1.2: Outside-in pre-audit (recommended)

Run 3-agent simulation BEFORE writing chapters:

```bash
# Spawn 3 parallel agents simulating thesis committee
# Agent 1: GVHD (advisor) — focuses on academic content + methodology
# Agent 2: GVPB (reviewer) — focuses on legal/compliance + presentation
# Agent 3: Defense committee — focuses on examiner-question failure modes
```

Use prompts from `reference/outside-in-audit-prompts.md`. Findings inform chapter structure BEFORE 1000+ lines written.

#### Step 1.3: Bibliography seed

Pre-populate `references/bibliography.md` với:
- Your department's giáo trình (1-2 refs minimum — per rule §C3)
- VN law refs nếu scope touches data/privacy (PDPL 2023, Decree 13/53/2022, Thông tư 78/2021)
- Peer-reviewed papers (≥30% per rule §C3)
- Vendor docs OK but weight thấp

### Phase 2 — Draft (3-5 sessions)

**Goal:** chapter content MDs đạt baseline rubric ≥60/100 (C grade ok at this stage)

#### Step 2.1: Write chapters in Vietnamese

PHẢI follow rule §S3 (Vietnamese narrative strict):
- Headings 100% tiếng Việt (NOT "Domain capabilities" → "Năng lực miền")
- Body prose-style (NOT listing pattern ≥5 items single sentence)
- English technical token natural (`JWT`, `OIDC`, `SaaS`) với parenthetical define lần đầu

#### Step 2.2: Cite as you write

Per rule §S4 — every numeric/factual claim needs `[N, tr.NNN]`:
- Direct quote `"..."` → page-num mandatory
- Specific stat ("80% trung tâm chuyển khoản") → page-num mandatory
- Vendor scale ("MISA EMIS 30,000 trường") → cite vendor URL + access date

#### Step 2.3: Measurement methodology block

Per rule §S5 — every performance claim needs:
- Tool (Lighthouse / JMeter / `wc -l`)
- N (sample size)
- Date (YYYY-MM-DD HH:MM TZ)
- Env (endpoint / network condition / hardware)

#### Step 2.4: Define acronyms at first use

Per rule §S7 — `GVCN (giáo viên chủ nhiệm)`, `OIDC (OpenID Connect, giao thức xác thực mở)`, `DPO (Data Protection Officer, cán bộ bảo vệ dữ liệu)`.

### Phase 3 — Outside-in audit (1-2 sessions)

**Goal:** surface 30-80 findings inside-out review misses

#### Step 3.1: Spawn 3 parallel audit agents

```
Agent 1 (Persona Simulation):
  Role-play GVHD reading thesis V1 cover-to-cover
  Output: 10-15 findings (academic depth, methodology rigor, contribution clarity)

Agent 2 (UTC Benchmark / Your-school Benchmark):
  Compare against known-good DOCX sample from your school's archive
  Output: 10-15 findings (format compliance, convention match)

Agent 3 (Failure-mode Matrix):
  Defense committee chất vấn simulation — top 10 fail modes
  Output: 10-15 findings (examiner-question vulnerabilities)
```

Combine → typical 30-50 findings beyond inside-out review.

#### Step 3.2: Apply rubric scoring

Score each chapter MD per rule §2 9-category rubric:

| Category | Self-score | Target | Gap |
|---|---|---|---|
| C1 Format | /15 | ≥13 PASS | |
| C2 Content + page count | /15 | ≥13 PASS | |
| C3 Bibliography | /15 | ≥13 PASS | |
| C4 Academic tone | /15 | ≥12 PASS | |
| C5 Project-internal scrub | /10 | ≥8 PASS | |
| C6 Draft-marker scrub | /5 | ≥4 PASS | |
| C7 Diagram + figure | /10 | ≥8 PASS | |
| C8 Examiner readiness | /10 | ≥8 PASS | |
| C9 Compliance + legal | /5 | ≥4 PASS | |
| **Total** | **/100** | **≥75 C+** | |

#### Step 3.3: Prioritize fixes

- **Hard-FAIL items first** (C5 "Claude" mentions / C9 "vi phạm" admissions — auto category FAIL)
- **Page count over cap** (C2 — bachelor >90 trang auto-FAIL)
- **Diagram rendering** (C7 — Mermaid → PNG pipeline if not yet wired)
- **Then incremental polish** (C4 tone + C6 draft markers)

### Phase 4 — Fix sweep (2-3 sessions)

**Goal:** apply audit findings retroactively to chapter MDs

Use rule §3 banned-patterns table as grep targets:

```bash
# C5 — project-internal references
grep -rn "Claude\|Wave [0-9]\|Phase [0-9]\|GAP-[0-9]\|\.claude/" \
  documents/<thesis-dir>/chapters/*.md

# C6 — draft markers
grep -rn "## TL;DR\|TODO\|FIXME\|\[placeholder\]\|\[stub\]" \
  documents/<thesis-dir>/chapters/*.md

# C4 — emoji + slang
grep -rnP "[\x{1F300}-\x{1F9FF}]|✅|❌|⚠️|🎉|🚀|📅|🆘" \
  documents/<thesis-dir>/chapters/*.md

# C4 — banned word "đối thủ"
grep -rn "đối thủ" documents/<thesis-dir>/chapters/*.md
```

Each pattern → replace per rule §3 table.

### Phase 5 — Assemble DOCX (1 session)

**Goal:** chapter MDs → final `thesis-v1.docx`

#### Option A — Python-docx pipeline (recommended for fine control)

Use template at `templates/thesis-assemble.py.template`:

```bash
python3 .claude/skills/document-generation/thesis/templates/thesis-assemble.py.template \
  --chapters documents/<thesis-dir>/chapters/ \
  --bibliography documents/<thesis-dir>/references/bibliography.md \
  --info documents/<thesis-dir>/thesis-info.md \
  --output documents/<thesis-dir>/thesis-v1.docx
```

Customize template for:
- School logo path
- Cover page layout (bìa cứng + bìa phụ)
- Heading style mapping (H1→Heading 1 TNR 18pt, H2→Heading 2 TNR 16pt, etc.)
- Mermaid → PNG conversion via headless browser (mermaid-cli)
- Bibliography IEEE rendering với hanging indent

#### Option B — Pandoc pipeline (faster setup, less control)

```bash
pandoc \
  --from gfm \
  --to docx \
  --reference-doc=.claude/skills/document-generation/thesis/templates/thesis-reference.docx.template \
  --metadata-file documents/<thesis-dir>/thesis-info.md \
  --filter pandoc-mermaid \
  --citeproc \
  --bibliography documents/<thesis-dir>/references/bibliography.bib \
  --csl ieee.csl \
  -o documents/<thesis-dir>/thesis-v1.docx \
  documents/<thesis-dir>/chapters/*.md
```

Requires: `pandoc`, `pandoc-mermaid` (Mermaid filter), CSL file (IEEE style từ https://www.zotero.org/styles).

#### Pre-ship verification

```bash
# Verify A4 page size + margins
python3 -c "
from docx import Document
d = Document('documents/<thesis-dir>/thesis-v1.docx')
s = d.sections[0]
assert s.page_width.cm == 21.0, f'Page width {s.page_width.cm} != 21.0'
assert s.page_height.cm == 29.7, f'Page height {s.page_height.cm} != 29.7'
print('A4 page size OK')
"

# Verify zero Mermaid code blocks leaked (means rendered as PNG)
unzip -p documents/<thesis-dir>/thesis-v1.docx word/document.xml | grep -c '```mermaid' && echo 'FAIL: Mermaid leaked' || echo 'Mermaid → PNG OK'

# Page count
libreoffice --headless --convert-to pdf documents/<thesis-dir>/thesis-v1.docx --outdir /tmp/
pdfinfo /tmp/thesis-v1.pdf | grep Pages
```

### Phase 6 — Defense prep (1-2 sessions)

**Goal:** committee Q&A drill

#### Step 6.1: Anticipate top 10 questions

From outside-in failure-mode audit (Phase 3 Agent 3). Common categories:
- Methodology rigor ("Vì sao chọn approach X thay vì Y?")
- Compliance ("PDPL DPO khi nào engage?")
- Empirical evidence ("KPI 92/100 Lighthouse — measure thế nào?")
- Scope ("Vì sao không include Z?")
- Contribution ("Đóng góp khoa học cụ thể là gì?")

#### Step 6.2: Slide deck (10-15 slides max)

Structure:
1. Title + student info
2. Bối cảnh + motivation (1-2 slides)
3. Phương pháp luận (1 slide)
4. Kiến trúc + design highlights (3-4 slides)
5. Kết quả + KPI (2-3 slides)
6. Đóng góp khoa học (1 slide — explicit per rule §C2)
7. Hạn chế + Hướng phát triển (1 slide)
8. Q&A + cảm ơn

#### Step 6.3: Print kit

- Thesis hard-cover binding (gáy in "HỌ TÊN - LỚP - NĂM" per rule §C1)
- Slide handout 3-up
- Backup USB với DOCX + PDF + supporting figures

## Gotchas (from real shipping)

### Page count creep

Bachelor cap = 90 trang auto-FAIL. Real ship often 110+ trang draft → forced trim. **Mitigation:** target 70 trang draft, leave 20-trang headroom for polish bloat.

### Mermaid rendering

GitHub native render Mermaid in markdown, BUT python-docx pipeline strips code blocks to text by default. **Mitigation:** pre-render Mermaid → PNG via `mmdc` (mermaid-cli) headless browser BEFORE chapter MD ingestion. Inject `![Hình X.Y](mermaid-output/figure-N.png)` image refs.

### Bibliography drift

Body cites `[15]` but bibliography numbering shifts when you add new ref → broken cite. **Mitigation:** use BibTeX + CSL with pandoc (Option B above) for auto-numbering. OR maintain bibliography append-only (new refs ALWAYS appended at end, never reorder).

### Project-internal language leakage

You say "Claude" / "Wave 5" / "GAP-123" naturally in conversation — they leak into thesis body. **Mitigation:** grep §3 banned patterns EVERY session before commit. Rule §7.4 detector script catches.

### Compliance phrasing

Easy trap: "Phase 1 BETA vi phạm Decree 53 nhưng acceptable" — committee will catch. **Mitigation:** rewrite mềm "Phase BETA invite-only chưa kích hoạt ngưỡng Decree 53 §26 (1M user threshold); roadmap migrate sang AWS Hanoi Local Zone OR VN cloud trong giai đoạn GA".

### Diagram source attribution

VN spec §2.4 mandates `*Nguồn:*` attribution per figure. Easy to miss for self-built diagrams. **Mitigation:** auto-inject `*Nguồn: tác giả tự xây dựng*` for any Mermaid block in chapter MD; manual override for derived figures.

## Anti-patterns

| ❌ Don't | ✅ Do |
|---|---|
| Skip outside-in audit "vì tôi tự biết thesis của mình" | 3-agent simulation surfaces 30-80 findings inside-out misses |
| Write thesis in English then translate to Vietnamese | Write Vietnamese first; English natural for technical tokens only |
| Use `## TL;DR` sections "vì hiện đại" | Strip — academic TÓM TẮT is separate page format |
| Mention "Claude" / "Wave 12" / "GAP-637" in body | Strip — bibliography vendor ref `[N] Anthropic Claude API` only acceptable |
| Cite internal `documents/04-quality/audits/*.md` as bibliography ref | Bibliography refs ONLY từ public sources (papers / standards / official docs) |
| Render Mermaid as code text in DOCX | Pre-render → PNG via mermaid-cli |
| 110-page bachelor thesis "vì nhiều content" | Trim to ≤70 trang — verbose thesis = committee bias against |
| Skip page-num cite for direct quotes | `[15, tr.314]` mandatory cho direct quote |
| Use single-child sub-heading (`2.1.1` without `2.1.2`) | Merge content lên parent OR add sibling |
| Have `## 4.0 Giới thiệu chương` + `## Tóm tắt chương 4` | Drop — fold content into §4.1 + KẾT LUẬN |

## Related rules + skills

- **`.claude/rules/thesis-content-standard.md`** — 9-category rubric /100 (companion governance)
- **`.claude/rules/dev-readable-doc-language.md`** — Vietnamese narrative + English identifier
- **`.claude/rules/output-review-mandate.md`** §3 — adds row "Thesis report / academic deliverable"
- **`.claude/rules/meta-gap-priority.md`** §3 — META P0 force-multiplier
- **`.claude/skills/document-generation/word/`** — companion skill for Word/DOCX generation
- **`.claude/skills/quality/persona-based-business-review/`** — sister skill for 3-agent outside-in audit pattern

## Reference

- `reference/outside-in-audit-prompts.md` — 3-agent prompt templates (GVHD + GVPB + Defense committee)
- `reference/vn-thesis-conventions.md` — UTC/HUST/UET/HCMUT convention notes
- `templates/thesis-info.md.template` — student/advisor info template
- `templates/chapter-mapping.md.template` — chapter outline template
- `templates/bibliography.md.template` — IEEE bibliography template
- `templates/thesis-assemble.py.template` — python-docx assembly pipeline template
- `scripts/check-thesis-content-standard.sh` — heuristic grep validator for §3 banned patterns
