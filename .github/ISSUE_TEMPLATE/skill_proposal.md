---
name: 🛠️ Skill proposal
about: Propose a new skill for the starter kit (a knowledge package Claude can invoke)
title: "[Skill] "
labels: skill-proposal, enhancement
assignees: ''
---

## Proposed skill

**Name:** (slug, e.g. `quality/pre-flight-check`)
**Category:** (per `rules/skill-conventions.md` §9 — pick one)
  - [ ] 1. Library & API Reference
  - [ ] 2. Product Verification
  - [ ] 3. Data Fetching & Analysis
  - [ ] 4. Business Process
  - [ ] 5. Code Scaffolding
  - [ ] 6. Code Quality & Review
  - [ ] 7. CI/CD & Deployment
  - [ ] 8. Runbooks
  - [ ] 9. Infrastructure Ops

## Folder structure proposed

```
skills/<category>/<skill-name>/
├── SKILL.md              ← entry point <100 lines
├── reference/            ← detailed tables (loaded only when needed)
├── scripts/              ← helper scripts (if any)
└── data/                 ← persistent state (if any)
```

## Why this is distinguished from existing skills

What gap does it fill? Why can't an existing skill cover the same need?

## Activation trigger phrases

What will users say to invoke this? Include exact phrases in both English and Vietnamese where applicable.

Example:
```yaml
description: "Use when user says 'quick audit', 'audit nhanh', or before merging
  a feature PR. Runs 5-category check with red/yellow/green output."
```

## Gotchas section (highest-value content)

List 3-5 project-specific failure points this skill addresses. These are what Claude can't know from training.

## Acceptance

- [ ] SKILL.md body < 100 lines
- [ ] Detailed content in `reference/` (not in body)
- [ ] Does NOT teach Claude generic knowledge it already has
- [ ] Description written as trigger conditions for the model, not human summary
- [ ] At least 3 gotchas listed
