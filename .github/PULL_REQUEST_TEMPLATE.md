# Pull Request

## Summary

<!-- 1-2 sentence summary of what this PR does -->

## What changed

<!-- Bullet list of concrete changes — file paths, new rules added, etc. -->

-
-

## Why

<!-- Motivation. If it's a rule addition, cite the originating incident. -->

## Type

- [ ] 🐛 Bug fix (PATCH)
- [ ] 📐 New rule (MINOR — see triage checklist below)
- [ ] 🛠️ New skill (MINOR — see triage checklist below)
- [ ] ✏️ Docs / wording / typo (PATCH)
- [ ] 🔥 Breaking change (MAJOR)

## Versioning bump indication

Per `rules/skill-conventions.md` semver:

- [ ] **PATCH** (x.y.z+1) — fix content, improve wording, update existing
- [ ] **MINOR** (x.y+1.0) — add new skill / script / rule / template
- [ ] **MAJOR** (x+1.0.0) — remove or restructure existing skill / script

## 4-question triage (if adding rule or skill)

Per `docs/CONTRIBUTING.md`:

- [ ] **Generalize:** Applies broadly across projects, not narrow to one stack
- [ ] **Stable:** Unlikely to need rewrite within 6 months
- [ ] **No project paths:** Doesn't hardcode paths/names from a specific project
- [ ] **Battle-tested:** Survived at least one real incident or 90 days of active use

## Checklist

- [ ] `VERSION` bumped
- [ ] `CHANGELOG.md` entry added (newest at top)
- [ ] `README.md` version reference updated if applicable
- [ ] For rules: enforcement section present (per `rule-change-process.md` §6.5)
- [ ] For skills: SKILL.md < 100 lines, gotchas section present
