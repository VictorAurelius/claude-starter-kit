---
name: 📐 Rule proposal
about: Propose a new rule for the starter kit (governance, conventions, standards)
title: "[Rule] "
labels: rule-proposal, enhancement
assignees: ''
---

## Proposed rule

**Name:** (slug, e.g. `pre-merge-state-check`)
**Scope:** (what files / situations it applies to — be specific)
**Priority:** 🔴 CRITICAL / 🟠 MANDATORY / 🟡 ADVISORY

## Why it's needed (real incident)

Describe the real-world incident that drove this. Rules without an originating incident tend to drift into advisory fiction.

- Date / context:
- What broke:
- What rule would have prevented it:

## 4-question triage checklist

Per `docs/CONTRIBUTING.md`, every proposed rule must pass:

- [ ] **Generalize:** Applies broadly across projects, not narrow to one stack
- [ ] **Stable:** Unlikely to need rewrite within 6 months
- [ ] **No project paths:** Doesn't hardcode paths/names from a specific project
- [ ] **Battle-tested:** Survived at least one real incident or 90 days of active use

## Enforcement plan

Per `rule-change-process.md` §6.5 (Enforcement Parity Mandate), rules ship with detection:

- [ ] Pre-commit hook
- [ ] CI check
- [ ] PR template item
- [ ] Audit skill detection
- [ ] Reviewer-checklist line
- [ ] Self-test fixture demonstrating the rule fires

## Links

- Memory entry (if any):
- Existing related rule (if any):
- Gap reference (if any):
