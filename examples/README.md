# Examples

Two example projects showing how to adopt the Claude Code Starter Kit.

| Example | What it shows |
|---|---|
| [`minimal-project/`](minimal-project/) | Bare minimum `.claude/CLAUDE.md` adoption — only core conventions |
| [`with-governance/`](with-governance/) | Full governance stack — all 26 rules + 15 skills + helper scripts + CSV-canonical patterns + template for project-specific rules |

Both examples are skeletons — only the `.claude/` directory is populated to illustrate the kit usage. Real adoption uses the full `bin/init-project.sh` flow.

## Quick start

```bash
git clone https://github.com/VictorAurelius/claude-starter-kit ../kit
../kit/bin/init-project.sh /path/to/your/new-project
```

See [`../docs/INSTALL.md`](../docs/INSTALL.md) and [`../docs/GETTING-STARTED.md`](../docs/GETTING-STARTED.md) for full install / setup guides.
