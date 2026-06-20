# Feature-Ship Runtime Walk Mandate — RST walk before DONE flip for user-facing features

**Priority:** 🔴 CRITICAL — feature shipping discipline; closes trust-pass anti-pattern
**Version:** 1.1.0
**Created:** 2026-05-28
**Last-Reviewed:** 2026-05-28
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Every gap với scope "user-facing feature" (FE page + BE endpoint + persistence + side effect — typical CRUD + workflow) before DONE flip. Out-of-scope: pure refactor, internal infra changes, docs-only updates, dev-tool changes.

---

## 1. The Rule

> **Trước khi flip ANY gap với scope "user-facing feature" → DONE, MUST chạy manual RST walkthrough end-to-end trên production-equivalent stack với persona-relevant credential.** Audit + unit + integration tests CANNOT substitute. Walk evidence (HTTP status + DB row + side effect verification + screenshot/UI snapshot if applicable) pasted vào gap closure block.

`pre-handoff-self-test-completeness.md` §3 mandates **post-fix** re-walk. Rule này extends to **original feature ship** — same evidence requirement, different trigger moment. A real feature-ship walk surfaced 17 bugs in a shipped-DONE feature; 2 were P0 feature paths completely missing (email send + user provision). Audit suite 76-94/100 + 25 unit tests PASS, all bugs invisible until a human walked the flow.

---

## 2. What counts as "user-facing feature"

Trigger pattern — gap scope includes ANY of:

| Pattern | Example |
|---|---|
| **Persona-attributed AC** | "Owner can invite staff", "Parent can view child grade", "Student submits assignment" |
| **FE page + BE endpoint pair** | New `/admin/staff/invite` page + `POST /api/v1/staff-invitations` controller |
| **Multi-service workflow** | invite → email → token-click → accept → user-provision → login |
| **State machine transition** | INVOICE: DRAFT → ISSUED → PAID → REFUNDED |
| **Side effect beyond DB write** | Email send / notify / payment gateway redirect / file upload |
| **Scoped data flow** | Per-scope DB write requiring scope resolution + access check |

Out-of-scope (rule N/A):

| Pattern | Why exempt |
|---|---|
| Pure refactor (no behavior change) | E.g., rename method, extract helper — no AC to walk |
| Internal infra (deploy config, secrets rotation) | No user-facing surface |
| Documentation-only updates | Per `docs-only-pr-auto-merge.md` — no walk needed |
| Dev-tool / CI workflow changes | Internal, no production user flow |
| Bug-fix walks (covered by `pre-handoff-self-test-completeness.md` §3) | Sister rule covers post-fix; this rule covers original-ship |

---

## 3. Required walk evidence per scope

### 3.1 Stack-up evidence

- All required services healthy (BE + FE + infra)
- Test data fixture populated (per seed script or documented DB UPDATE)
- Persona credential resolved (test fixture user OR signup-fresh path)

### 3.2 Walk evidence per acceptance criterion

For EACH AC in gap:

| AC type | Required evidence |
|---|---|
| "User can do X" (UI flow) | Browser screenshot OR cite Bước N HTTP status from Network tab; URL navigated; click sequence documented |
| "API returns 201 with shape Y" | curl output OR Network tab response body + DevTools status code |
| "DB row created with field Z=value" | `SELECT ... WHERE ...` query output |
| "Email sent to Y" | Mail-catcher UI screenshot OR API query showing recipient |
| "Background job triggers W" | Logs grep showing job execution OR queue depth dec OR side effect verified |
| "User receives notification" | Recipient inbox/UI verification — not just sender-side log |
| "State transitions X → Y" | DB query showing status field changed |

Walk evidence pasted into gap closure under `## Walk evidence (per feature-ship-runtime-walk-mandate.md §3)` section.

### 3.3 Stack-down acceptable

Walk on local dev stack (production-equivalent) acceptable. Cloud/prod verification optional unless gap also covers infra.

### 3.4 Catalog-then-batch-fix walk workflow

> **Khi walk surfaces 1+ bugs mid-flow, MUST catalog all bugs reaching end-of-walk TRƯỚC khi fix bất kỳ bug nào. Batch fix all → single rebuild → re-walk.** Inline rebuild after each bug found = anti-pattern (thrash, wasted compute, broken walk continuity).

**Required protocol:**

```
1. Start walk → execute step 1
2. Step N hit bug?
   ├─ YES → CATALOG bug (file path + line + symptom + provisional fix idea)
   │        Apply workaround if any (vd: skip step, use dev header, manual DB UPDATE)
   │        Continue to step N+1 — DO NOT rebuild
   └─ NO  → continue to step N+1
3. Reach end-of-walk (terminal step OR cannot proceed even with workaround)
4. Batch fix ALL catalogued bugs trong code (single Edit session)
5. Single rebuild (1 container restart cycle)
6. Re-walk full flow → verify all fixes + no new bugs introduced
7. If new bugs surface trên re-walk → goto step 2 (treat re-walk as fresh walk)
```

**Cost analysis (rebuild cycle):**

| Service | Single rebuild cost | 2-bug inline cost | 2-bug batch cost | Saved |
|---|---|---|---|---|
| Service A (gateway-type) | ~60s rebuild + ~30s health | 2 × 90s = 180s | 90s | 90s |
| Service B (build-heavy) | ~90s build + ~30s health | 2 × 120s = 240s | 120s | 120s |
| Backend service C | ~120s + ~30s health | 2 × 150s = 300s | 150s | 150s |
| **Mixed (A + B)** | n/a | **~360s = 6 phút** | **~180s = 3 phút** | **3 phút (50%)** |

Scaling: 5 bugs spread across 3 services inline = ~15 phút rebuild thrash. Batch = ~3 phút. **80% saving** with batch protocol.

**Banned shortcuts:**

| ❌ Inline-rebuild anti-pattern | ✅ Catalog-then-batch |
|---|---|
| Walk step → 401 → fix code → rebuild → walk → 401 → fix → rebuild ... | Walk → 401 → catalog Bug #N → workaround/skip → continue walk → catalog Bug #M → ... → end → fix all → rebuild once → re-walk |
| "Rebuild now để verify fix ngay" | Verify trong re-walk pass; intermediate rebuild adds time without bug-detection value |
| Different fix-rebuild cycle cho mỗi service | Single rebuild + restart cycle for ALL affected services |
| Lose context of remaining walk steps to debug rebuild | Walk catalog preserves context — Bug #18 finding doesn't block discovering Bug #19 |

**Workaround patterns** (to continue walk past blocker):

| Bug class | Workaround |
|---|---|
| Auth 401 mid-walk | Skip endpoint, manual DB INSERT/UPDATE to simulate post-condition |
| Routing mismatch | curl direct service (bypass gateway) — verify backend logic independently |
| Email send fail | Skip email step, manually fetch token from DB |
| Missing field/column | Manual ALTER TABLE / UPDATE for walk continuation |
| FE redirect loop | curl raw API (bypass FE) — verify BE shape |
| Side effect not firing | Manually trigger via container exec / admin command |

Workarounds are **walk-continuation aids**, NOT fixes — code fix still required in batch step 4.

**Exception (rare):** if Bug #N is a **walk-blocking compile error** preventing the stack from starting at all, rebuild required mid-walk because subsequent walk impossible. Document as `WALK_BATCH_EXCEPTION: <reason>` in walk evidence.

**Self-test (worked example):**

Actual (anti-pattern):
1. Walk step 4a → 401 → fix Bug #18 gateway whitelist → rebuild gateway ~90s → walk
2. Step 4a → 401 still → fix Bug #19 service SecurityConfig → rebuild service ~120s → walk
3. Total: ~210s rebuild + 2 walk-restart cycles + context loss between bugs

Correct (this rule):
1. Walk step 4a → 401 → catalog Bug #18 (gateway whitelist) → workaround: try direct service curl
2. Direct service curl → 401 → catalog Bug #19 (SecurityConfig) → can't continue without fix
3. Batch fix Bug #18 + Bug #19 in single Edit session
4. Single rebuild both services in parallel (one wait) ~120s
5. Re-walk step 4a → verify both fixes pass → continue Step 4b/4c/4d
6. Total: ~120s rebuild + 1 re-walk cycle + full context preserved

Save: ~90s rebuild + 1 cognitive context switch. Scales to N bugs.

---

## 4. Banned shortcuts

| ❌ Banned | ✅ Required |
|---|---|
| "Unit tests pass + IT pass + audit 90/100 → DONE" | Walk the flow on real stack with real persona credential, verify each AC empirically |
| Flip DONE based on code-level review only | Run the user-facing path; assert side effects empirically |
| Skip walk "vì AC simple" | Simple AC = quick walk (2-5 min). Still required |
| Pre-merge walk done, post-merge skip "since CI green" | CI green ≠ feature works. Walk after merge on rebuilt local stack |
| "Feature paired with separate gap (e.g. email) — defer walk till both ship" | Mark current gap PARTIAL until paired ship + joint walk; do NOT DONE either in isolation |
| Walk in different persona than AC specified | Walk in exact persona AC mandates |
| Walk reaches Bước 2/N then stop "rest is obvious" | Walk to terminal step (final state assertion) |
| Document walk in chat only, not in gap closure | Walk evidence in gap closure (artifact, not session log) |
| Single happy-path walk sufficient | At minimum: happy path + 1 sad path (403/400/expired-token type) |
| "Walk-fix workaround applied → walk passes → DONE" | Walk-fix workaround = PARTIAL, not DONE. Real fix shipped → re-walk → THEN DONE |

---

## 5. Override mechanism

Genuine exception (vendor-only flow blocks dev walk, cloud account unavailable, persona credential unavailable):

```
git commit -m "...
FEATURE_SHIP_WALK_DEFER: <gap-id> — <reason — e.g. 'vendor payment sandbox down, payment flow walk deferred'>
FEATURE_SHIP_WALK_FOLLOWUP: <gap-id-or-deadline — e.g. 'walk within 7 days of vendor restore OR file blocker gap'>"
```

Trailer logged trong quarterly retro. Pattern frequency >10%/quarter triggers meta-review.

Acceptable defer cases:
- Vendor sandbox down (specific external dep)
- Production-only flow (cron job, scheduled task — walk via test trigger)
- Multi-day async flow (email open tracking, payment settle — walk first half + verify async side effect via DB poll)

NOT acceptable defer cases:
- "Feature path not implemented yet" — that means gap is PARTIAL, not DONE-with-defer
- "Audit + tests pass, walk seems unnecessary" — exactly the trust-pass anti-pattern this rule prevents
- "Will walk next sprint" — without concrete blocker = banned

---

## 6. Worked self-test — invite-user feature with email side-effect

**Apply rule retroactively to a feature-ship DONE flip moment.**

### Scope check (§2)
Feature scope = "Owner mời staff" (invite-user with email) — matches:
- ✅ Persona-attributed AC ("Owner can invite staff")
- ✅ FE page + BE endpoint pair (`/admin/staff/invite` + `POST /api/v1/staff-invitations`)
- ✅ Multi-service workflow (invite → email → accept → user-provision → login)
- ✅ Side effect beyond DB write (email send)

→ Rule §1 mandate fires. Walk required before DONE flip.

### What actually happened
1. PR shipped BE with invite service saving DB row only
2. Audit suite (5 audits 76-94/100) PASS
3. 25 unit + controller tests PASS
4. PR merged + gap flipped DONE
5. **NO RST walk executed before DONE flip**

### What rule would have required
**Walk:** Owner login → click "Mời nhân viên" → submit form → check DB row + check mail-catcher email → click accept link in email → set password → login as new staff → verify staff role.

### Counterfactual — 17 bugs that would have been surfaced at PR-time
All 17 bugs would have surfaced at PR review time. Specifically the email-never-sent bug + accept-doesn't-create-user bug would have immediately exposed feature non-functionality.

**Cost comparison:**
- Without rule: 17 bugs shipped to "DONE" state; surfaced 1 day later by RST walk; 8+ rebuild cycles + 2 walk sessions + findings doc + META rule landing = ~6h cost + reputation damage (audit suite credibility)
- With rule: walk at PR time surfaces same 17 bugs in 30 minutes; PR returned to PARTIAL; bugs fixed iteratively pre-DONE; total walk + fix cost ~2-3h; DONE flip honest

**Self-test verdict:** Rule fires correctly on originating incident. Counterfactual saves ~4h + restores audit trust. ✅

---

## 7. Enforcement (per `rule-change-process.md` §6.5 Enforcement Parity Mandate)

### 7.1 Reviewer-checklist (active now)

Pre-merge review for PR closing gap với feature scope:

- [ ] Gap scope matches §2 trigger pattern?
- [ ] PR description / gap closure has `## Walk evidence (per feature-ship-runtime-walk-mandate.md §3)` section?
- [ ] Walk evidence covers each AC per §3.2 table (HTTP status + DB row + side effect + persona-correct)?
- [ ] If override trailer present, reason + follow-up valid per §5?
- [ ] If walk passed with workaround applied (per `pre-handoff-self-test-completeness.md` §3 patterns), gap stays PARTIAL not DONE?

### 7.2 PR template extension (paired same-PR)

Add to PR template Output Review Checklist:

```markdown
- [ ] **Feature-ship runtime walk** — if PR closes a gap with user-facing feature scope (per `feature-ship-runtime-walk-mandate.md` §2), gap closure contains `## Walk evidence` section per §3 (Stack-up + per-AC evidence). Override: trailer `FEATURE_SHIP_WALK_DEFER:` per §5.
```

### 7.3 Memory auto-load (deferred per `incident-to-rule-pipeline.md` §3.1)

Paired memory entry could remind tại session start before gap DONE flip. Defer per premature-rule guard ≥7 ngày; reviewer-checklist + worked self-test §6 sufficient cho v1.0.0.

### 7.4 CI grep detector (HONEST DEFER per `incident-to-rule-pipeline.md` §3.1 tightened conditions)

- **Detector complexity:** Scan PR body for "feature scope" gap reference + verify presence of `## Walk evidence` section + check evidence covers AC count — requires gap AC parser + PR body NLP, NOT trivial bash
- **Recurrence count:** 0 post-merge
- **FP risk:** High — many legit gap closures wouldn't have explicit `## Walk evidence` heading; would need flexible matcher
- **Decision:** Reviewer-checklist §7.1 + PR template §7.2 + worked self-test §6 sufficient cho v1.0.0; revisit detector when recurrence-count ≥2 post-rule

### 7.5 Override mechanism

Per §5 trailer `FEATURE_SHIP_WALK_DEFER:` — logged quarterly retro. Pattern frequency >10%/quarter → meta-review.

---

## 8. Anti-patterns

| ❌ Don't | ✅ Do |
|---|---|
| Trust audit score → DONE flip without walk | Walk → confirm each AC → THEN flip DONE |
| Walk in dev profile that bypasses real auth/security | Walk on production-equivalent stack with real auth chain |
| Skip walk for "small features" | Small feature = small walk. Still required |
| Walk happy path only | Walk happy + at least 1 sad path (403/400/expired) |
| Walk only API layer | Walk full UI → API → DB → side effect (email/event) → terminal state |
| Trust `[x]` AC checkbox without evidence | Evidence inline (HTTP code + DB query output + screenshot) |
| Defer walk "till paired feature ships" | Mark gap PARTIAL until paired; do NOT mark DONE in isolation |
| Walk only as admin | Walk as exact persona AC mandates (Owner / Teacher / Parent / Student) |
| Walk in dev with mocked services | Walk with real services (mailer actually sending to catcher, broker actually publishing) |

---

## 9. Relationship to other rules

- **`pre-handoff-self-test-completeness.md`** §3 — POST-FIX re-walk mandate; this rule extends to ORIGINAL FEATURE SHIP mandate (different trigger moment, same evidence requirement)
- **`gap-done-discipline.md`** §2 — DONE flip mechanics + AC verified; this rule provides AC verification mechanism (RST walk)
- **`audit-to-gap-pipeline.md`** — fix-time state-check; this rule extends to feature-DONE-time state-check
- **`incident-to-rule-pipeline.md`** — this rule = direct output of a 17-bug feature-ship walk shutdown applied through 5-stage pipeline
- **`rule-change-process.md`** §6.5 Enforcement Parity Mandate — rule + reviewer-checklist + PR template + worked self-test §6 all paired same PR
- **`meta-gap-priority.md`** §3 — META P0 force-multiplier (1 chuẩn walk discipline → mọi feature ship subsequent auto-comply prospectively; eliminates trust-pass class at original-ship moment)
- **`output-review-mandate.md`** §3 — paired same-PR row "Feature-ship runtime walk" tracking review standard
- (paired memory entry) — recurrence of "AC `[x]` ≠ production-verified" trust-pass class; this rule closes the pattern at original-ship moment

---

## 10. Log

- **2026-05-28 (v1.1.0):** Extracted into starter-kit from a real 200+ PR project. Codifies that any user-facing feature gap requires a manual end-to-end runtime walk on a production-equivalent stack before flipping DONE — because a real ship passed full audit + unit tests yet had 17 bugs (incl. 2 entirely-missing P0 feature paths) invisible until a human walked the flow. Includes the catalog-then-batch-fix walk workflow (§3.4) to avoid per-bug rebuild thrash.
