# Design-First Investigation Order — design → gaps → docs → code (code LAST)

**Priority:** 🟠 MANDATORY — investigation source-ordering governance
**Version:** 1.0.0
**Created:** 2026-06-08
**Last-Reviewed:** 2026-06-08
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Mọi investigation / câu hỏi "X hoạt động thế nào / X có đúng không / X có phải gap không / tại sao X behave vậy / X có nên làm Y không". Out-of-scope: tra cứu single-fact thuần code (file nào định nghĩa symbol Z), debug syntax error, khi chắc chắn không có design doc liên quan (pure impl detail).

---

## 1. The Rule

> **Khi investigate bất cứ điều gì (hành vi hệ thống / câu hỏi kiến trúc / "đây có phải gap không" / "nên làm thế nào"), PHẢI check nguồn theo thứ tự: (1) DESIGN (architecture docs / ADR / design-system) → (2) GAPS (`gap-status.csv` + gap files) → (3) DOCUMENTS (business / planning / runbook / guide) → (4) CODE cuối cùng.**

Code cho biết hệ thống ĐANG LÀM GÌ (what IS). Design cho biết hệ thống NÊN LÀM GÌ (what SHOULD BE). Để kết luận "đúng / sai / là gap", PHẢI biết intended design TRƯỚC. Đọc code đầu tiên = lấy implementation accident làm "design", hoặc bỏ sót gap đã giải thích sẵn deviation đó.

Force-multiplier: 1 chuẩn thứ tự investigate → mọi câu hỏi subsequent kết luận đúng "correct-vs-gap" thay vì suy diễn design từ code.

---

## 2. Trigger pattern — khi nào rule fires

| Câu hỏi / tình huống | Fire? |
|---|---|
| "X hoạt động thế nào?" (behavior/architecture) | ✅ YES — design trước |
| "Đây có phải gap không / sao chưa fix?" | ✅ YES — design (intended) → gaps (đã filed chưa) → code |
| "Tại sao X behave thế này?" | ✅ YES |
| "X có nên làm Y không / đúng spec chưa?" | ✅ YES — design = spec source |
| Trước khi file gap mới về 1 deviation | ✅ YES — confirm deviation thật so với design + chưa có gap |
| Trước khi propose fix cho "lỗi" | ✅ YES — verify "lỗi" thật vs design intended |
| "File nào định nghĩa symbol Z?" (single-fact lookup) | ❌ NO — tra code trực tiếp |
| Debug syntax / stack trace cụ thể | ❌ NO — code là nguồn đúng |
| Pure impl detail không có design doc | ❌ NO — code trực tiếp |

Rule **KHÔNG** fires khi: tra cứu fact đơn lẻ, debug lỗi runtime cụ thể, hoặc scope thuần implementation không có tài liệu design tương ứng.

---

## 3. Required order (4 tầng)

| # | Tầng | Nguồn | Trả lời câu hỏi |
|---|---|---|---|
| 1 | **DESIGN** | `documents/02-architecture/**` (ADR, architecture docs, design-system) + decision docs | Hệ thống NÊN làm gì (intended) |
| 2 | **GAPS** | `bash scripts/query-gaps.sh <keyword>` + `gap-status.csv` + gap files | Deviation đã biết giữa design ↔ reality (đã filed chưa) |
| 3 | **DOCUMENTS** | `documents/01-business/**` (rules/use-cases/api-contract) + `documents/03-planning/**` + `documents/05-guides/**` runbook | Chi tiết behavior intended + context |
| 4 | **CODE** | source files / config | Reality — hệ thống ĐANG làm gì |

**Quy trình:** đọc tầng 1 → 2 → 3 → 4. Dừng sớm nếu đủ kết luận (vd design + gap đã trả lời → không cần code). Khi tới code, đối chiếu code ↔ design (tầng 1) để phán "match / drift / gap".

### 3.1 Kết luận đúng cách

Sau khi đi đủ tầng, kết luận dạng:
> "Design (ADR-NNN / architecture/X.md) nói SHOULD BE = A. Code hiện = B. Gap GAP-NNN [đã filed / chưa filed] track deviation này."

KHÔNG kết luận "code làm B nên design chắc là B" (suy diễn ngược — banned §4).

---

## 4. Banned shortcuts

| ❌ Don't | ✅ Do |
|---|---|
| Grep code đầu tiên để trả lời "X hoạt động thế nào" | Đọc architecture/ADR trước → code verify sau |
| Suy diễn design intent TỪ code ("code làm vậy nên design chắc vậy") | Design doc là spec source; code chỉ là reality |
| Kết luận "là gap" mà chưa đọc design (không biết intended) | Design trước → mới biết deviation thật so với gì |
| Kết luận "không phải gap, code đúng rồi" mà chưa check design + gaps | Code "chạy được" ≠ đúng design; check 2 tầng trên trước |
| File gap mới mà chưa query gaps hiện có | `query-gaps.sh` trước (tránh duplicate) |
| Skip design "vì chắc không có doc" mà chưa thử tìm | Glob `documents/02-architecture/**` + grep keyword trước khi bỏ qua |
| Đọc cả 4 tầng cho 1 fact lookup đơn giản | Single-fact → code trực tiếp (rule không fire §2) |

---

## 5. Override mechanism

Genuine exception (design doc chắc chắn không tồn tại cho scope thuần-impl, hoặc câu hỏi là debug runtime cụ thể):

```
git commit -m "...
DESIGN_FIRST_SKIP: <reason — e.g. 'pure impl debug, no design doc for this stack-trace'>"
```

Inline note trong narrative cũng được (rule investigate, không phải artifact). Pattern frequency >10%/quarter triggers meta-review.

---

## 6. Worked self-test — "is behavior X a bug or intended?" investigation

**Scenario:** User hỏi "feature behaves theo cách Y — đây là bug hay design cố ý? đã filed gap chưa?". Đi **CODE-FIRST**: grep ngay các source files liên quan, đọc handler/component, kết luận "code làm Y, không thấy chỗ nào làm Z khác" + suy diễn architecture TỪ code.

**Vi phạm:** trả lời câu hỏi kiến trúc/gap bằng code trước design → không thể nói chắc "behavior LẼ RA phải là Z (design) nhưng code làm Y (gap)" hay "design vốn intended Y". User phải push back nhiều lần.

**Apply rule retroactively (đúng thứ tự):**
1. **DESIGN:** đọc `documents/02-architecture/**` cho feature đó + ADR liên quan → biết intended behavior là Y hay Z.
2. **GAPS:** `query-gaps.sh <feature-keyword>` → deviation đã filed chưa.
3. **DOCUMENTS:** business/planning về feature.
4. **CODE:** handler / component → đối chiếu với design tầng 1.

**Kết luận đúng cách sẽ là:** "ADR-NNN/architecture nói feature SHOULD do Z. Code hiện làm Y. Gap [GAP-NNN / chưa filed]." — phán được correct-vs-gap, thay vì suy diễn.

**Counterfactual:** design-first → 1 câu trả lời dứt khoát, 0 user push-back round-trip. Self-test PASS ✅ — rule fires đúng trên chính class incident sinh ra nó.

---

## 7. Enforcement (per `rule-change-process.md` §6.5 Enforcement Parity Mandate)

### 7.1 Self-detection (in-turn)

Trước khi grep/Read CODE để trả lời câu hỏi match §2 trigger, mentally check:
- Đã đọc DESIGN (architecture/ADR) cho scope này chưa?
- Đã `query-gaps.sh` chưa?
- Nếu CHƯA → STOP, đi tầng 1-3 trước, code cuối cùng.

### 7.2 Reviewer-checklist (active now)

Khi review PR có investigation/gap-filing/fix-proposal:
- [ ] Kết luận có cite DESIGN source (ADR/architecture) làm spec, không phải suy diễn từ code?
- [ ] Đã query gaps hiện có trước khi file gap mới (tránh duplicate)?
- [ ] "Là gap / không phải gap" verdict dựa design intended, không chỉ "code chạy được"?

### 7.3 Memory auto-load (paired same-PR)

Paired memory entry reminds thứ tự design→gaps→docs→code tại session start.

### 7.4 Detector (HONEST DEFER per `incident-to-rule-pipeline.md` §3.1)

- **Complexity:** phát hiện "đọc code trước design khi investigate" cần phân loại intent của câu hỏi + thứ tự tool-call — NLP trên reasoning, không trivial.
- **Recurrence:** 1.
- **Decision:** self-detection §7.1 + reviewer-checklist + worked self-test §6 đủ cho v1.0.0; revisit khi recurrence ≥2.

### 7.5 Override — per §5.

---

## 8. Atomic-unique-bar check (per `rule-change-process.md` §5.1)

- ✅ **Atomic:** single concept = investigation source ordering (design first, code last)
- ✅ **Unique:** `mcp-first-with-fallback.md` covers TOOL selection (MCP vs Bash), không cover SOURCE-OF-TRUTH ordering; `gap-architecture-v2.md` covers "query CSV first" cho gap status narrow; `audit-to-gap-pipeline.md` state-check covers verify-before-file nhưng không mandate design-before-code reading order
- ✅ **Widely applicable:** mọi investigation / architecture question / gap-filing
- ✅ **Body discipline:** §1 The Rule ≤2 "and"/"và" conjunction

---

## 9. Relationship to other rules

- **`mcp-first-with-fallback.md`** — covers TOOL tier (MCP→dedicated→Bash); rule này covers SOURCE tier (design→gaps→docs→code). Khác axis, compose.
- **`gap-architecture-v2.md`** — query CSV canonical for gap status; rule này dùng nó làm tầng 2 (GAPS) trong thứ tự rộng hơn.
- **`audit-to-gap-pipeline.md`** state-check — verify trước khi file gap; rule này thêm "verify gì trước": design intended trước code reality.
- **`agent-action-bias.md`** — do-it-yourself; rule này = check-design-yourself-first.
- **`meta-gap-priority.md`** §3 — META P1 force-multiplier (1 chuẩn investigation order → mọi câu hỏi subsequent kết luận đúng).
- **`incident-to-rule-pipeline.md`** — rule này = direct output của 1 user-flagged code-first miss qua 5-stage.
- **`rule-change-process.md`** §6.5 Enforcement Parity — rule + reviewer-checklist + memory + worked self-test §6 same PR.
- (paired memory entry, same-PR).

---

## 10. Auto-load justification (per `context-budget-mandate.md` §3.2)

KHÔNG dùng `paths:` frontmatter — always-load. Lý do:
- **Fire tại investigation decision-time, mọi domain** — câu hỏi "X hoạt động thế nào / là gap không" xảy ra trên code/docs/config/infra bất kỳ; không có natural file-scope glob.
- **Path-scope sẽ miss case quan trọng** — investigation thường bắt đầu TRƯỚC khi đọc file nào (chính là lúc rule cần fire để định hướng đọc design trước).
- **Token cost chấp nhận được** — force-multiplier (mỗi investigation đúng thứ tự → kết luận đúng correct-vs-gap, tránh user round-trip).
- **Priority MANDATORY giữ nguyên** — §5 override cho phép skip; always-load per §3.2 row 2.

Re-evaluate nếu: (a) pre-reasoning NLP hook khả dụng, (b) >5 false-positive/quarter, (c) rule >300 dòng.

---

## 11. Log

- **2026-06-08 (v1.0.0):** Extracted into starter-kit from a real 200+ PR project. Codifies the design→gaps→docs→code reading order after an investigation read code first to answer an architecture/"is this a bug or intended?" question — inferring design from implementation accident instead of citing the spec, which forced multiple user push-back rounds. META P1 force-multiplier per `meta-gap-priority.md` §3.
