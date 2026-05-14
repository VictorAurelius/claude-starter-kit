# Example Team Rule — replace with your actual rule

**Priority:** 🟡 ADVISORY
**Version:** 1.0.0
**Created:** YYYY-MM-DD
**Last-Reviewed:** YYYY-MM-DD
**Reviewer-Approver:** @your-team-lead
**Applies to:** Specific scope unique to your project — paths, services, or workflow phases

---

## 1. The Rule

> Your one-line rule statement here.

Pattern this off `rules/rule-change-process.md` §3 frontmatter and §6.5 Enforcement Parity (rule + detection ship same PR).

## 2. Why

What incident triggered this? Reference your project's gap tracker or memory entry.

## 3. Enforcement

- Pre-merge reviewer checklist line
- Optional: detection script in `scripts/`
- Optional: hook in `.husky/` or `.github/workflows/`

## 4. Override mechanism

```
git commit -m "...
RULE_OVERRIDE: reason + follow-up gap link"
```

## 5. Log

- **YYYY-MM-DD** (v1.0.0): Rule created. Reviewer: @your-team-lead.

---

This file is a **template** — replace contents with your actual team rule. Delete this template paragraph when you do.
