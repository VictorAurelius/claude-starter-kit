# CLAUDE.md (minimal example)

This is a **minimal** example showing how to adopt the Claude Code Starter Kit on a barebones project. It pulls only the core conventions; advanced governance is in `examples/with-governance/`.

## Adopting the kit

```bash
# From your project root:
git clone https://github.com/VictorAurelius/claude-starter-kit ../claude-starter-kit
../claude-starter-kit/bin/init-project.sh .
```

Or via remote install (no clone needed):
```bash
curl -fsSL https://raw.githubusercontent.com/VictorAurelius/claude-starter-kit/main/bin/install-remote.sh | bash
```

## What this minimal config gives you

- Vietnamese-language communication preference (see kit's CLAUDE.md template)
- TDD enforcement skill activation on code changes
- Basic git workflow rules (branch naming, no direct commit to main)
- Quality-audit skill on demand (`/quality-audit`)

## What to do next

1. Read the kit's `rules/skill-conventions.md`
2. Try the `/start-session` skill at the start of each Claude Code session
3. When you find a recurring miss → run `incident-to-rule-pipeline.md` 5-stage to convert into a permanent guard

## Project-specific tweaks

This is where you'd add project-specific rules / skills / personas. The kit ships generic; you customize.
