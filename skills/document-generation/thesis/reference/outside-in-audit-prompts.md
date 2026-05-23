# Outside-In Audit Prompts — 3-Agent Roleplay Templates

3 parallel audit agents simulating thesis committee. Spawn before thesis V1 ship to surface 30-80 findings inside-out review misses.

## Agent 1 — Persona Simulation (GVHD + GVPB + Defense Committee)

```
Roleplay as 3 distinct examiners reading my thesis V1:

1. GVHD (Giáo viên hướng dẫn, advisor)
   - Read for academic depth + methodology rigor + contribution clarity
   - Background: senior CNTT lecturer, PhD, supervised 30+ theses
   - Concerns: "Đóng góp khoa học cụ thể là gì? Phương pháp luận có theo IEEE 730 / Beck TDD / Deming PDCA không? Literature review đủ depth không?"
   - Output: 10-15 findings ranked P0/P1/P2

2. GVPB (Giáo viên phản biện, reviewer)
   - Read for legal/compliance + presentation quality + defense risk
   - Background: industry-experienced lecturer, security/PDPL aware
   - Concerns: "Vi phạm pháp luật không? PDPL DPO + DPIA roadmap? Penetration test evidence? Sample data anonymized?"
   - Output: 10-15 findings ranked P0/P1/P2

3. Defense Committee Chair
   - Read for examiner-question failure modes (top 10 risks)
   - Background: defense panel chair, asks hard questions
   - Concerns: "Page count too long shows unfocused scope? Diagram chỉ Mermaid text? KPI placeholders? 'Claude' mentions in body?"
   - Output: 10-15 findings ranked by question-severity

Cover: documents/<thesis-dir>/chapters/*.md (read all chapter MDs cover-to-cover)

Output format:
- ID prefix per persona (GVHD-NN / GVPB-NN / COMM-NN)
- Section + line reference
- Concern statement
- Severity P0/P1/P2
- Suggested fix
```

## Agent 2 — Sample Benchmark Audit

```
Read 2 reference DOCX from your school's archive (best to use student samples already accepted by committee):
- Sample 1: known-good báo cáo thực tập / đồ án từ previous student same major
- Sample 2: known-good đề cương DATN (thesis proposal)

Compare with my thesis V1 chapter MDs across dimensions:
1. Format compliance (page size / margins / heading sizes / numbering)
2. Frontmatter structure (cover / bìa phụ / LỜI CẢM ƠN / MỤC LỤC / danh mục)
3. Chapter naming convention ("CHƯƠNG N." vs plain number)
4. Bibliography style (IEEE format / inline cite / page-num)
5. Section depth (typical max 3 levels per VN spec)
6. Figure caption convention ("Hình X.Y. ..." + "Nguồn: ...")

Output:
- 10-15 findings comparing my V1 vs sample baseline
- Match / Drift / Improvement areas
- Format ID prefix BENCH-NN
- Severity P0/P1/P2
```

## Agent 3 — Failure-mode Matrix

```
Top 10 defense failure modes for this thesis topic. For each:

1. Statement of failure mode (vd "Committee asks 'Vì sao Mermaid không render?'")
2. Likelihood (LOW/MEDIUM/HIGH)
3. Severity if surfaces (LOW/MEDIUM/HIGH/CRITICAL)
4. Pre-defense mitigation
5. In-defense response plan

Categories to cover:
- Methodology rigor questions
- Compliance + PDPL + Cybersecurity questions (if scope touches user data)
- Empirical evidence questions ("KPI measure thế nào?")
- Scope questions ("Vì sao không include X?")
- Originality questions ("Đóng góp khoa học vs existing tools?")
- Tooling questions ("Vì sao chọn stack Y thay vì Z?")
- Hard format questions ("Page count quá dài?")

Output:
- 10-15 failure modes
- ID prefix FAIL-NN
- Mitigation P0/P1/P2 sorted by Likelihood × Severity
- Cross-reference to rubric §C category
```

## Combining findings

Merge 3 agent outputs into single matrix:

```
documents/<your-audits-dir>/persona-review/YYYY-MM-DD-thesis-v1-outside-in-audit.md
```

Format:
- ID column (preserve agent prefix: GVHD-01, BENCH-03, FAIL-07)
- Section reference
- Finding
- Severity P0/P1/P2
- Fix scope (1-line)
- Cluster tag (group similar findings)

Common clusters surfaced:
- F-A* — Citation/factual claim issues (cluster across agents)
- F-B* — Format/structure issues
- F-C* — Cross-reference / acronym / figure attribution issues

Use clusters to plan fix waves (Phase 4 fix sweep).

## Worked example output

From a real VN bachelor thesis V1 audit (2026-05-19, 110-page draft):

- Agent 1 (GVHD + GVPB + Committee): 43 findings
- Agent 2 (UTC benchmark): 18 findings
- Agent 3 (Failure-mode matrix): 21 findings
- Total: 82 NEW findings beyond 14 user-flagged inside-out items
- Rubric v1 (6-category, inflated): 82/100 B-
- Rubric v2 (9-category, realistic per `thesis-content-standard.md`): 42/100 F
- Path to 87/100 B+ post all fixes: ~45-point gain via category-by-category fix

→ Without outside-in audit, V1 ship at "82 B-" perceived ready; real defense risk much higher.
