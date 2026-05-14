# CLAUDE.md (with-governance example)

This example shows how to adopt the **full governance stack** from the Claude Code Starter Kit — suitable for teams or solo devs who want all the rule-driven guardrails active.

## Adopting

```bash
git clone https://github.com/VictorAurelius/claude-starter-kit ../kit
../kit/bin/init-project.sh . --full
```

Or upgrade an existing project:
```bash
../kit/bin/upgrade-project.sh . --dry-run    # Preview
../kit/bin/upgrade-project.sh .              # Interactive merge
```

## What this brings in

- All 26 rules under `.claude/rules/` (audit-to-gap pipeline, gap-done discipline, post-merge sync, deploy standards, etc.)
- 15 skills under `.claude/skills/` (TDD, brainstorm, debug, code review, quality-audit /100, ui-review /128, etc.)
- Helper scripts under `scripts/` (frontmatter validators, gap-status CSV check, docs check)
- CSV-canonical patterns for gap status + rules index + ADRs index (per `meta-csv-index-pattern.md`)

## Team-specific rule example

When your team has a recurring miss specific to your codebase, you add a project rule (NOT to the kit) here:

```
.claude/rules/example-team-rule.md
```

See [`example-team-rule.md`](rules/example-team-rule.md) for shape.

## Promoting team rules back to the kit

If a project rule turns out to be useful for other projects, run:
```bash
../kit/bin/contribute.sh . "Why this rule should be in the kit"
```

This opens a contribution proposal for the kit maintainer to review per the 4-question triage.
