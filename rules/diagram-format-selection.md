---
paths:
  - "documents/02-architecture/**/*.md"
  - "documents/06-diagrams/**/*.md"
  - "documents/03-planning/**/*.md"
  - ".claude/rules/**/*.md"
  - ".claude/skills/**/*.md"
---

# Diagram Format Selection — Mermaid / PlantUML / ASCII per use case

**Priority:** 🟠 MANDATORY — documentation visual-aid governance
**Version:** 1.0.4
**Created:** 2026-05-18
**Last-Reviewed:** 2026-05-21
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Mọi markdown file dưới `documents/**`, `.claude/rules/**`, `.claude/skills/**`, và root README.md có chứa diagram (flowchart, sequence, ER, class, state, gantt, pie, hoặc architecture box-arrow visualization). Scope = nội dung diagram content; KHÔNG cover screenshots/PNG, photos, hoặc icon emoji.

---

## 1. The Rule

> **Khi cần diagram trong markdown, PHẢI pick ĐÚNG MỘT trong 3 format (Mermaid / PlantUML / ASCII) theo §2 selection matrix. Plain ASCII box-drawing chấp nhận CHỈ cho simple flow (≤5 node) hoặc khi target renderer không support Mermaid.**

Recurrence pattern: một architecture doc dùng plain ASCII với ~30 node trong khi target renderer (GitHub) native-render Mermaid → reader phải đọc text art thay vì xem rendered diagram. Rule này codify selection criteria để tránh lặp.

Force-multiplier: 1 quyết định format đúng → mọi reader tương lai xem rendered diagram thay vì decode ASCII text → comprehension time giảm ~5x.

---

## 2. Format selection matrix

### 2.1 Decision flow (3 questions)

1. **Diagram type là gì?**
2. **Renderer support Mermaid không?** (GitHub ✅ / GitLab ✅ / Notion ✅ / Obsidian ✅ / VS Code preview ✅ — đa số ✅)
3. **Số node + complexity?**

### 2.2 Per-type recommendation

| Diagram type | Recommended | Fallback | Khi nào dùng ASCII |
|---|---|---|---|
| **Flowchart / decision tree** | **Mermaid** `flowchart TD/LR` | PlantUML | ≤5 node, linear flow |
| **Sequence (interaction over time)** | **Mermaid** `sequenceDiagram` | PlantUML | ≤3 actor + ≤5 message |
| **ER (entity-relationship)** | **Mermaid** `erDiagram` | PlantUML | Hiếm — usually need crow's foot |
| **Class / object** | **Mermaid** `classDiagram` | PlantUML | Hiếm |
| **State machine** | **Mermaid** `stateDiagram-v2` | PlantUML | Hiếm |
| **Gantt timeline** | **Mermaid** `gantt` | — | KHÔNG — Gantt cần actual rendering |
| **Pie chart** | **Mermaid** `pie` | — | KHÔNG |
| **Architecture (box + arrow) — generic** | **Mermaid** `flowchart TB/LR` | PlantUML | ≤5 box, simple data flow |
| **Cloud architecture diagram (with service logos)** | **PlantUML + cloud-icon stdlib** (`!includeurl .../...`) | Mermaid flowchart fallback (no icons) | KHÔNG — cloud diagrams cần official logos |
| **Network topology / cluster** | **Mermaid** `flowchart` với subgraph | PlantUML deployment | Hiếm |
| **CI/CD pipeline** | **PlantUML** | Mermaid | ≤5 step, no swimlane |
| **C4 model (Context/Container/Component)** | **PlantUML** với C4-PlantUML | Mermaid `C4Context` (limited) | KHÔNG — C4 cần PlantUML-quality |
| **Quick inline reference** | **ASCII** | — | Đây CHÍNH LÀ use case duy nhất cho ASCII trong rule này |

### 2.3 Format characteristics

| | Mermaid | PlantUML | ASCII / Unicode |
|---|---|---|---|
| GitHub native render | ✅ | ❌ (cần external server) | ✅ (raw text) |
| GitLab native render | ✅ | ✅ (built-in) | ✅ |
| Notion / Obsidian | ✅ | ✅ (plugin) | ✅ |
| VS Code preview | ✅ (built-in) | ✅ (extension) | ✅ |
| Print PDF | ✅ | ✅ | ⚠️ (font-dependent) |
| Cú pháp đơn giản | ✅ | Trung bình | ✅ |
| Loại diagram | Nhiều (10+) | Rất nhiều (15+) | Đơn giản |
| Maintenance khi sửa | ✅ Edit text | ✅ Edit text | ❌ Re-flow toàn diagram |
| Diff readability | ✅ | ✅ | ❌ (whitespace nhạy cảm) |
| Cần tool external | Không | Cần server hoặc plugin | Không |

### 2.4 Default preference

**Default = Mermaid**, vì:
- Native render trên GitHub (common primary remote)
- Cú pháp đơn giản hơn PlantUML cho most cases
- Diff-friendly (text + indentation)
- Edit easier (single text block)
- Đa số diagram types supported

**Chỉ pick PlantUML khi:**
- C4 model (Context/Container/Component) — PlantUML có C4-PlantUML library mature
- Detailed deployment diagram với nhiều stereotype
- Complex sequence với group/loop/alt sophistic
- Existing PlantUML pipeline trong dự án (vd `documents/06-diagrams/plantuml/`)

**Chỉ pick ASCII khi:**
- Diagram ≤5 node + ≤8 arrow (inline reference)
- Target renderer KHÔNG support Mermaid (rare)
- Code comment trong source file (ASCII more grep-able)

---

## 3. Example: a service send flow

### ❌ Anti-pattern (plain ASCII for a large graph)

```
   [App service]
                                │
                                │  HTTP POST /api/email/send
                                ▼
              ┌──────────────────────────────────────────┐
              │            email microservice             │
              └──────────────────────────────────────────┘
                                │
                                │ NotificationChannel interface
                                ▼
                ┌──────────────────────────────────┐
                │  Spring picks implementation     │
                └──────────────────────────────────┘
                       │                    │
                       ▼                    ▼
        ┌──────────────────────┐  ┌──────────────────────┐
        │  ProviderAChannel    │  │  ProviderBChannel    │
...
```

~30 nodes, 30+ ASCII box-drawing chars per line, ~50 lines. Reader phải decode visually. GitHub renders as monospace text.

### ✅ Required pattern (Mermaid flowchart)

````markdown
```mermaid
flowchart TD
    App[App service]
    App -->|HTTP POST /api/email/send| EmailSvc[email microservice<br/>provider = A default]
    EmailSvc --> Channel{NotificationChannel}
    Channel -->|provider=A| A[ProviderAChannel<br/>✅ EXISTS]
    Channel -->|provider=B<br/>NOT WIRED| B[ProviderBChannel<br/>❌ TODO]
    A -->|SDK call| AVendor[Provider A cloud<br/>Signs với A DKIM key]
    B -->|HTTP POST| BVendor[Provider B cloud<br/>Signs với B DKIM key]
    AVendor -->|SMTP relay| MX[Recipient MX]
    BVendor -->|SMTP relay| MX
    MX -->|DNS lookup<br/>verify DKIM signature| DNS[DNS records<br/>_domainkey + SPF + DMARC]
    MX -->|DKIM PASS| Inbox[📧 Inbox]
    MX -->|DKIM FAIL| Spam[🚫 Spam / rejected]
```
````

Reader trên GitHub thấy rendered flowchart. Edit dễ (sửa 1 line). Diff readable.

### ✅ Required pattern (Mermaid sequenceDiagram cho time-ordered flow)

````markdown
```mermaid
sequenceDiagram
    participant App as App service
    participant Email as email microservice
    participant A as ProviderAChannel
    participant Vendor as Provider A cloud
    participant MX as Recipient MX
    participant DNS as DNS records

    App->>Email: POST /api/email/send
    Email->>A: NotificationChannel.send()
    A->>Vendor: vendor SDK send
    Vendor->>Vendor: Sign với DKIM private key
    Vendor->>MX: SMTP relay
    MX->>DNS: Lookup _domainkey TXT
    DNS-->>MX: DKIM public keys
    MX->>MX: Verify DKIM signature
    alt Signature PASS
        MX-->>App: 📧 Inbox delivery
    else Signature FAIL
        MX-->>App: 🚫 Spam / reject
    end
```
````

Use sequenceDiagram khi muốn show ORDER (request → verify → send → render). Use flowchart khi muốn show TOPOLOGY (boxes + connections).

---

## 4. Anti-patterns

| ❌ Don't | ✅ Do |
|---|---|
| Plain ASCII 30+ node "vì dễ paste" | Mermaid flowchart — GitHub renders |
| Mermaid khi diagram chỉ 3 box + 2 arrow | ASCII inline OK cho simple reference |
| PlantUML cho simple flow | Mermaid mặc định (renderer support tốt hơn) |
| Mix 2 format trong same file (one Mermaid + one ASCII) | Pick MỘT format per file |
| Screenshot rendered Mermaid → paste PNG vào markdown | Edit Mermaid text trực tiếp — diff-friendly |
| Sửa ASCII bằng cách re-flow toàn diagram | Mermaid edit = sửa 1 line |
| ASCII diagram cho architecture với ≥10 service | Mermaid flowchart subgraph |
| Khi project đã có PlantUML pipeline → switch sang Mermaid không lý do | Match existing convention; chỉ migrate khi clear benefit |
| Đặt diagram dưới H1 mà không có context | TL;DR + context paragraph TRƯỚC diagram + caption SAU |
| **`<br/>` ANYWHERE trong `sequenceDiagram` block** (participants / messages / Note over / `actor` aliases) | **HARD RULE:** Mermaid sequence parser unreliable với HTML breaks across versions — even when individual context "should" support, surrounding context can break parsing. **Replace ALL `<br/>` với ` — ` separator OR omit subtitle**. Verified breakage: participant aliases (`participant X as Long<br/>Sub`) + Note over text + message labels with multiple `<br/>` chains. |
| **`<br/>` ANYWHERE trong `stateDiagram-v2` block** (transition labels / state descriptions / notes) | **HARD RULE:** stateDiagram parser strict — no HTML. Replace với space. |
| **`;` (semicolon) trong `Note over/left of/right of` text trong `sequenceDiagram` + `stateDiagram-v2` block** | **HARD RULE:** Mermaid parser treats `;` as statement terminator INSIDE Note text — orphans following clause + concatenates next diagram statement → "Expecting ARROW, got NEWLINE" error. **Replace `;` với ` — ` em-dash OR `.` period OR `,` comma**. Verified: `Note over A,B: First clause; second clause` fails parser; `Note over A,B: First clause — second clause` succeeds. |
| `<br/>` trong `flowchart` node labels OR `flowchart` edge labels | ✅ OK — Mermaid flowchart parser supports HTML breaks reliably. Don't refactor unnecessarily. |
| **Subgraph titles bị đè chữ với child nodes** — large fontSize (≥16px) + long subgraph titles + default rendering = text overlap visible | **HARD RULE:** Khi diagram dùng `subgraph` với title labels AND có `themeVariables.fontSize ≥ 16px`, PHẢI specify `subGraphTitleMargin: {top: ≥10, bottom: ≥15}` trong init config + giữ subgraph title ≤30 chars. |
| **Large diagram aspect không control được** (>15 nodes natural Mermaid landscape) | Apply Mermaid init config patterns: `nodeSpacing: 25-30` (tighter horizontal) + `rankSpacing: 60-80` (more vertical breathing) + `fontSize: 16-18px` (larger text); aggregate edges via subgraph-level connections thay vì per-node edges; shorten labels to single-line per node (no `<br/>` chains in flowchart nodes when restructuring for compactness). |

---

## 5. Enforcement (per `rule-change-process.md` §6.5 Enforcement Parity)

### 5.1 Reviewer-checklist (active now)

Pre-merge review cho PR touching `documents/**/*.md`, `.claude/rules/**/*.md`, `.claude/skills/**/*.md`:

- [ ] PR thêm/sửa diagram trong markdown?
- [ ] Nếu CÓ:
  - [ ] Format chọn = Mermaid (default) HOẶC PlantUML (C4/complex) HOẶC ASCII (≤5 node)?
  - [ ] Per §2.2 type recommendation match?
  - [ ] Code fence ```mermaid hoặc ```plantuml hoặc plain (ASCII)?
  - [ ] Diagram rendered correct trên GitHub (preview PR)?

### 5.2 CI grep detector (HONEST DEFER — heuristic FP risk >5%)

Detector HONEST-deferred per `incident-to-rule-pipeline.md` §3 tightened legitimate-deferral conditions:
- **Detector complexity:** Markdown box-drawing chars `┌─┐│└┘` used BOTH for ASCII diagrams AND for tables — distinguishing requires AST parsing, NOT trivial grep
- **FP risk:** High — every markdown table containing borders triggers false positive
- **Decision:** Reviewer-checklist §5.1 + worked self-test §6 sufficient cho v1.0.0; revisit detector when recurrence-count ≥2 OR proven AST-based diagram classifier available

Future detector heuristic regex (when implemented):

```bash
# Heuristic: detect markdown files với 30+ ASCII box-drawing chars cluster
# (potential ASCII diagram > 5 nodes — should be Mermaid)
find documents/ .claude/ -name "*.md" -type f -not -path "*/archived/*" 2>/dev/null \
  | while read f; do
    count=$(grep -cE "^[[:space:]]*[┌┐└┘├┤┬┴┼─│]" "$f" 2>/dev/null)
    if [ "$count" -gt 30 ]; then
      echo "WARN: $f has $count ASCII box-drawing lines — consider Mermaid per diagram-format-selection.md §2"
    fi
  done
```

WARN-only initially. Track follow-up gap khi stabilize.

### 5.3 Memory auto-load (optional, deferred)

Memory entry reminding tại session start trước khi vẽ diagram. Defer per `incident-to-rule-pipeline.md` premature-rule guard ≥7 ngày; reviewer-checklist + self-test §6 đủ cho v1.0.0.

### 5.4 Override mechanism

Genuine exception (vd ASCII for source code comment, simple inline reference):

```
git commit -m "...
DIAGRAM_FORMAT_OVERRIDE: <file path> — <reason — e.g., 'source code comment, ASCII more grep-able'>"
```

Trailer logged. Pattern frequency >10%/quarter triggers meta-review.

---

## 6. Self-test (worked example — an architecture doc rewrite)

**Pre-state:** An architecture doc that used plain ASCII for a ~30-node graph (~50 lines box-drawing characters). GitHub render = monospace text (không phải rendered diagram).

**Apply §2 decision flow:**
1. Diagram type? → Architecture flow (App → Email → Channel → Vendor → MX → DNS → Inbox/Spam) = `flowchart` type
2. Renderer? → GitHub (primary remote) ✅ supports Mermaid
3. Node count? → ~12 boxes + ~8 arrows = ABOVE 5-node threshold → ASCII not appropriate
4. Verdict per §2.2 "Architecture (box + arrow)" row: **Mermaid `flowchart TD`** required

**Apply:** Rewrite the ASCII diagram → ```` ```mermaid flowchart TD ... ``` ```` block (per §3 Example pattern). Preserve all semantic info (NotificationChannel branching, vendor independent DKIM, DNS lookup, PASS/FAIL terminal states).

**Verdict:** Rule fires correctly on originating incident. Reader trên GitHub sẽ thấy rendered diagram thay vì ASCII text art. Self-test PASS ✅.

**Counterfactual without rule:** Tương lai mỗi diagram được vẽ ad-hoc — recurrence pattern tiếp tục. With rule: 1 standard quyết định 1 lần cho mọi diagram subsequent.

---

## 7. Anti-patterns đặc thù

### 7.1 PlantUML cho non-C4 ở project mặc định Mermaid

Nếu project đã có `documents/06-diagrams/plantuml/` cho legacy CI/CD pipeline diagrams, điều đó KHÔNG có nghĩa là tất cả diagram phải PlantUML. Per §2.4 default = Mermaid; PlantUML chỉ khi C4 hoặc complex deployment.

### 7.2 Caption + context

Diagram đứng một mình KHÔNG đủ. Phải có:
- **TL;DR paragraph** TRƯỚC diagram giải thích "diagram này cho thấy gì"
- **Caption** SAU diagram (tùy chọn nhưng khuyến nghị) chú thích các điểm quan trọng
- **Legend** nếu dùng color/style đặc biệt

Anti-pattern: paste diagram, không context → reader không biết đang nhìn gì.

### 7.3 Diagram trong rule files

Rule files (`.claude/rules/*.md`) — diagram nên minimal vì rules auto-load vào context budget. Per `context-budget-mandate.md` §1, rule body ≤1k token preferred. Mermaid code blocks count vào token budget. Defer diagram-heavy explanation sang skill `reference/` hoặc audit doc.

---

## 8. Relationship to other rules

- **`docs-folder-structure.md`** — chỗ chứa diagram (`documents/06-diagrams/` cho dedicated diagram files); rule này covers FORMAT trong markdown body
- **`context-budget-mandate.md`** §1 + §3.2 — rule files token budget; áp dụng cho diagram trong rules per §7.3
- **`output-review-mandate.md`** §3 — adds row "Diagram format selection" tracking review standard
- **`rule-change-process.md`** §6.5 Enforcement Parity Mandate — rule + reviewer-checklist + self-test §6 all paired same PR
- **`incident-to-rule-pipeline.md`** — rule này direct output của a user-flagged miss applied through 5-stage pipeline
- **`meta-gap-priority.md`** §3 — META P2 force-multiplier (fix 1 chuẩn → mọi diagram subsequent auto-comply)

---

## 9. Log

- **2026-05-18 (v1.0.4):** Extracted into starter-kit from a real 200+ PR project. Codifies which of 3 diagram formats (Mermaid / PlantUML / ASCII) to use per diagram type so readers get rendered diagrams instead of decoding ASCII text art.
