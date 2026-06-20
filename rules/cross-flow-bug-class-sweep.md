# Cross-Flow Bug-Class Sweep Mandate — fix once → grep all sister sites

**Priority:** 🟠 MANDATORY — bug-fix completeness governance
**Version:** 1.1.0
**Created:** 2026-05-28
**Last-Reviewed:** 2026-06-08
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Mọi PR fix bug — sau khi identify bug class + fix code site #1, PHẢI grep similar bug class signature trong codebase TRƯỚC khi flip issue closed

---

## 1. The Rule

> **Sau khi fix bug trong 1 flow, MUST grep + audit other flows cho same bug class signature TRƯỚC khi flip gap/PR closed. Document sweep evidence inline trong fix PR.**

Bug class signature = pattern khiến bug xảy ra (vd anti-pattern code, missing header, validation gap). Single-site fix without sweep = silent recurrence khi sister flow hit same class.

Sister rule trong direction inverse:
- `audit-to-gap-pipeline.md` Decision-Doc Code-Sync — **decision-doc lands → grep stale code refs**
- Rule này — **bug fix lands → grep similar bug class in sister flows**

---

## 2. Trigger pattern

Rule fires khi PR scope = bug fix có:

| Pattern | Ví dụ |
|---|---|
| **Missing header/parameter on API call** | FE thiếu required header (vd scope header / auth context header) on a POST call → grep mọi `apiClient.*call` xem có miss tương tự không |
| **Anti-pattern code construct** | `htmlEscape(input)` single-arg → grep all sites for same call |
| **Default-deny security-config catch** | Public endpoint trả 401 vì `anyRequest().authenticated()` → grep other "public" endpoints có cùng config gap |
| **Missing null-check / validation** | NullPointerException ở Service X → grep similar service pattern |
| **Race / concurrency issue** | Order race detected ở Flow A → grep other Order-* paths cho same race signature |
| **Locale/encoding bug** | Diacritic corrupted ở 1 form → grep other forms với same sanitization |
| **N+1 query** | Service X ship lazy load → grep other services for same `findById` loop pattern |

Rule **KHÔNG** fire khi:
- Bug is hyper-local (typo, single-file logic error, single value off-by-one)
- Bug class strictly bounded (vd 1 specific endpoint signature)
- Scope-limited rule applied (vd "this exception only for this domain")

---

## 3. Required artifacts khi rule fires

PR body / commit body / closing comment MUST contain section `## Cross-flow sweep evidence (per cross-flow-bug-class-sweep.md §3)`:

```markdown
## Cross-flow sweep evidence (per cross-flow-bug-class-sweep.md §3)

**Bug class signature:** <1-line describing pattern, vd "FE call site dùng apiClient không gắn required scope header">

**Grep command run:**
```bash
grep -rnE "fetch\(['\"]\\s*/api/|axios\\.(get|post|put|delete|patch)\\(" \
  src/ 2>/dev/null | grep -v "apiClient\|node_modules\|test"
```

**Sites found + verdict:**

| # | File:line | Verdict | Reason |
|---|---|---|---|
| 1 | `SomeForm.tsx:84` | DEFER | per-user scope, không scope-bound — same class signature nhưng risk N/A |
| 2 | `verify-email/page.tsx:28` | EXEMPT | Public endpoint (no auth required), no scope header needed |
| ... | ... | FIX / DEFER / EXEMPT | reason |

**Decision:**
- Sites FIXED this PR: N (list)
- Sites DEFERRED to follow-up: M (file gap link)
- Sites EXEMPT (rule N/A reason documented): K
```

---

## 4. Sweep methodology

| Bug class category | Grep pattern suggestion |
|---|---|
| FE missing header | `grep -rnE "(fetch\\|axios\\.\\\\w+).*api/v1" src/` |
| BE missing @Transactional | `grep -rn "repository\\.save" src/ -A2 -B2 \\| grep -B1 "save" \\| grep -v "@Transactional"` |
| Java null-check absent | `grep -rnE "\\\\.get(Name\\|Email\\|Id)\\(\\)" src/ -A0 \\| grep -v "Optional\\|null"` |
| API URL hardcoded vs config | `grep -rnE "\"https?://[^\"]+\"" src/ \\| grep -v "test\\|example"` |
| Default-deny security-config gap | `grep -rn "permitAll\\|.authenticated()" SecurityConfig.java` |
| Locale/encoding | `grep -rn "htmlEscape\\|encode\\|URLEncoder" src/` |
| Sanitization bypass | `grep -rn "raw\\|unsafe\\|sanitiz" src/` |

**Banned shortcuts:**

- ❌ `| head` truncation trên grep — must read FULL output (per `audit-to-gap-pipeline.md` hardened protocol)
- ❌ "Trust that other flow doesn't have it" — empirical verify required
- ❌ Single-keyword grep — use multi-pattern OR construct (vd file name + class name + import)
- ❌ Skip sweep "vì fix ở interceptor level cover all" — verify by grep, document evidence

### 4.1 Statically-detectable class → persistent detector mandate

> **Nếu bug class detect được TĨNH (grep/AST trên source — vd "FE gọi endpoint BE không expose", "page không wrap shell", "missing header on apiClient call"), manual grep 1 lần KHÔNG đủ — MUST ship persistent CI detector (script + WARN-mode job) để check MỌI flow trên MỌI PR, không chỉ flow đang walk.**

Manual sweep chỉ check tại thời điểm walk + dựa vào người nhớ chạy → flow chưa walk vẫn ẩn instance của class. CI detector chạy mọi PR → catch class across all flows tự động (kể cả flow chưa walk). Đây là khác biệt "process bắt 1 lần" vs "meta tự check mọi flow".

| Class detect được tĩnh? | Sweep đủ chưa? |
|---|---|
| ✅ Có (source grep/AST) — vd FE↔BE contract, missing-shell-wrapper, missing-header | Manual grep = tạm; **MUST file + build CI detector** (per `incident-to-rule-pipeline.md` §3.1 — nếu detector non-trivial, HONEST-defer với gap + ETA, KHÔNG bỏ) |
| ❌ Không (runtime-only — vd race condition, env-specific) | Manual sweep + runtime walk (browser/RST); detector defer |

Detector ship per `rule-change-process.md` §6.5 Enforcement Parity (WARN-mode đầu, HARD-STOP sau grace). Self-test: detector PHẢI flag được pre-fix state của incident gốc.

---

## 5. Decision matrix per site found

| Verdict | Khi nào | Action |
|---|---|---|
| **FIX** | Same bug class + same scope = will manifest | Apply fix this PR (batch fix per `feature-ship-runtime-walk-mandate.md` §3.4) |
| **DEFER** | Same class but different scope, separate concern | File follow-up gap với grep evidence linked |
| **EXEMPT** | Pattern match but NOT bug class (false positive) | Document inline why exempt — review trail |

---

## 6. Worked self-test — missing-header sweep

**Bug class:** FE call site sử dụng a shared `apiClient` không gắn required scope header (scope-bound path → 403).

**Fix site #1:** `src/lib/api/client.ts` — extend request interceptor để extract scope từ JWT + attach required header.

**Sweep applied này PR:**

```bash
grep -rnE "fetch\\(['\"]\\s*/api/|axios\\.(get|post|put|delete|patch)\\(" \
  src/ 2>/dev/null | grep -v "apiClient\\|node_modules\\|test\\|spec\\|.next"
```

**4 sites found:**

| # | Site | Verdict | Reason |
|---|---|---|---|
| 1 | `SomeForm.tsx:84` raw fetch | **DEFER** | per-user scope; backend permitAll (no scope check); risk N/A for current fix |
| 2 | `verify-email/page.tsx:28` axios.post | **EXEMPT** | Public path (in whitelist); no scope header needed |
| 3 | `client.ts:56` axios.post refresh | **EXEMPT** | Token refresh — different scope (auth not scope-bound) |
| 4 | `use-theme.ts` fetch admin endpoint | **EXEMPT** | Admin-level scope, not scope-bound |

**Decision:**
- Sites FIXED this PR: 1 (apiClient interceptor — covers ~95% caller surface)
- Sites DEFERRED: 0
- Sites EXEMPT: 3 (documented inline)

→ Rule fires correctly: apiClient interceptor fix is sufficient cho current scope; no follow-up gap needed for sweep findings. Self-test PASS ✅

**Counterfactual without rule:** Fix interceptor + close issue; raw `fetch` site silently has same risk class (if its scope ever becomes scope-bound). Risk = silent recurrence weeks/months later.

---

## 7. Anti-patterns

| ❌ Don't | ✅ Do |
|---|---|
| Fix Bug X in file A + close issue, không grep file B/C/D | Grep + document evidence trong PR body |
| Sweep with single narrow keyword | Multi-pattern grep (file pattern + class + import + symbol) |
| Document sweep verbally only in chat | Inline §Cross-flow sweep evidence section trong PR body |
| Defer all sister sites "for next time" without follow-up gap | DEFER requires gap filing same-PR |
| EXEMPT without inline reason | Each EXEMPT row needs 1-line rationale |
| Apply rule only to similar bug ID | Apply by bug CLASS signature, không phải bug instance |

---

## 8. Enforcement (per `rule-change-process.md` §6.5)

### 8.1 Reviewer-checklist (active now)

Pre-merge review for any PR labeled `bug`, `bugfix`, hoặc PR body containing `fix:` `fixes #` `Bug #`:

- [ ] Bug class signature identified inline?
- [ ] Sweep grep command shown + output documented?
- [ ] Sites table với FIX/DEFER/EXEMPT verdict per row?
- [ ] DEFER rows có follow-up gap link?
- [ ] EXEMPT rows có 1-line rationale?

### 8.2 Override mechanism

Genuine exception (hyper-local bug, vd typo fix, single off-by-one):

```
git commit -m "...
CROSS_FLOW_SWEEP_SKIP: <reason — e.g. typo fix; single-character; hyper-local logic>"
```

Trailer logged. Pattern frequency >20%/quarter triggers meta-review (rule scope mis-defined hoặc reviewer too permissive).

### 8.3 Memory auto-load (deferred per `incident-to-rule-pipeline.md` §3.1)

Paired memory entry could remind tại session start trước khi fix bug. Defer ≥7 ngày; reviewer-checklist + worked self-test §6 sufficient cho v1.0.0.

### 8.4 CI grep detector (deferred per premature-rule guard)

Future: scan PR body cho `fix:` / `Bug #` patterns + verify presence of `## Cross-flow sweep evidence` section. WARN if missing. Defer until recurrence count ≥2 post-rule.

---

## 9. Relationship to other rules

- **`audit-to-gap-pipeline.md`** Decision-Doc Code-Sync — sister rule INVERSE direction (decision-doc → code-sweep); rule này covers bug-fix → similar-flow-sweep direction
- **`audit-to-gap-pipeline.md`** hardened state-check protocol — banned `| head` truncation; this rule inherits same constraint
- **`feature-ship-runtime-walk-mandate.md`** §3.4 catalog-then-batch protocol — rule này extends: catalog includes "similar sites" not just "same site"
- **`meta-gap-priority.md`** §3 — META P0 force-multiplier (eliminate silent recurrence class permanently)
- **`incident-to-rule-pipeline.md`** — rule này = direct output user-flagged "thêm rule, sau khi fix 1 bug ở 1 flow, check flow khác có bug này không"
- **`rule-change-process.md`** §6.5 Enforcement Parity Mandate — rule + reviewer-checklist + worked self-test §6 paired same PR

---

## 9.5 Auto-load justification (per `context-budget-mandate.md` §3.2)

Rule này KHÔNG dùng `paths:` frontmatter — luôn auto-load mỗi session. Lý do:

- **Fire tại bug-fix decision-time, không file-read-time** — rule kích hoạt khi Claude *vừa fix xong 1 bug* (bất kỳ ngôn ngữ / layer nào: Java / TS / SQL / config). Không có natural file-scope glob: bug class có thể ở `**/*.java`, `**/*.tsx`, `**/*.sql`... — path-scope tới mọi source = quá rộng, gần như always-load anyway.
- **Path-scope sẽ miss case quan trọng** — fix bug đôi khi chỉ sửa 1 dòng config / 1 method; nếu scope `**/*.java` thì miss khi sweep cần thiết cho TS-side sister flow (vd origin: FE `fetch()` bypass interceptor).
- **Token cost chấp nhận được** — ~3k tokens × mỗi session; force-multiplier (mỗi bug fix sweep 1 lần → eliminate silent recurrence class).

Re-evaluate nếu: (a) harness publishes post-edit hook detect "bug-fix just landed", (b) rule grows >300 lines.

---

## 10. Log

- **2026-05-28 (v1.1.0):** Extracted into starter-kit from a real 200+ PR project. Codifies that after fixing a bug in one flow you must grep for the same bug-class signature across all sister flows before closing — and ship a persistent CI detector when the class is statically detectable — to eliminate silent recurrence in flows that were never walked.
