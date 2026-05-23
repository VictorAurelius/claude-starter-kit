---
name: thesis-outside-in-audit
description: Khi ship academic thesis cho project software thực tế, MỌI ship V1+ phải qua 3-agent outside-in audit (persona simulation + sample benchmark + failure-mode matrix) TRƯỚC inside-out review. Reason — inside-out review consistently inflates score 30-40 points vs realistic committee-perspective rubric.
metadata:
  type: feedback
---

# Thesis Outside-In Audit — must run BEFORE inside-out review

**Rule:** Mỗi thesis V1+ ship phải qua 3-agent outside-in audit (persona simulation + sample benchmark + failure-mode matrix) TRƯỚC khi tự đánh giá. Use `.claude/skills/document-generation/thesis/` workflow Phase 3.

**Why:** Inside-out review (author tự đọc) consistently inflates score 30-40 points vs realistic committee-perspective rubric. Worked example: 110-page bachelor thesis V1 inside-out rated 82/100 B- (rubric v1 6-category); 9-category rubric v2 với outside-in audit findings rated 42/100 F. Gap = -40 points = 5 critical content-quality dimensions (academic tone, project-internal scrub, draft markers, diagram rendering, compliance phrasing) bị bỏ sót khi tự đánh giá.

**How to apply:**
- Phase 1 (planning): spawn 3 parallel audit agents BEFORE writing chapters → findings inform chapter structure
- Phase 3 (post-draft): spawn 3 parallel audit agents trên V1 draft → typically surfaces 30-80 findings beyond inside-out review
- Combine 3 agent outputs into cluster matrix → prioritize fixes (P0 hard-FAIL first, then category gaps)
- Use [[thesis-content-standard]] rubric /100 (9 categories) as scoring framework
- Use `.claude/skills/document-generation/thesis/reference/outside-in-audit-prompts.md` for 3-agent prompt templates

**Agents:**
1. **Persona Simulation** — roleplay GVHD + GVPB + Defense committee reading thesis V1 cover-to-cover (10-15 findings per persona × 3 = 30-45 findings)
2. **Sample Benchmark** — compare against 2 known-good DOCX from school's archive (10-15 findings on format / convention drift)
3. **Failure-mode Matrix** — top 10 defense-question failure modes ranked by Likelihood × Severity (10-15 mitigation actions)

**Counter-example without outside-in audit:**
Inside-out review consistently catches typos + missing sections but MISSES:
- Academic tone violations ("đối thủ" business jargon, emoji blockquotes, mixed-language code-switching)
- Project-internal language leakage ("Claude", "Wave N", "GAP-XXX", `.claude/` paths)
- Draft-markers (TL;DR sections, TODO placeholders, date-prefix headings)
- Diagram rendering issues (Mermaid as text vs PNG)
- Compliance phrasing risks ("vi phạm Decree 53" explicit admission)
- Page count over cap (110 trang vs 90 trang bachelor auto-FAIL)
- Bibliography order anti-pattern (alphabetical vs first-appearance order)

**Banned shortcut:** "Tôi đã đọc lại 2 lần, không cần outside-in audit" — this is exactly the case where blind spots compound.

Related: [[outside-in-coverage-trigger]] rule (auto-suggest outside-in audit khi user proposes inside-out scope).
