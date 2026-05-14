# Security Policy

## Reporting a vulnerability

If you discover a security issue in this starter kit (e.g., a scripted command that could be exploited, a rule template that leaks secrets, a `bin/` script with insecure defaults), please report it privately:

- **Preferred:** [GitHub Security Advisories](https://github.com/VictorAurelius/claude-starter-kit/security/advisories/new) (private, encrypted)
- **Email:** `vannkite@outlook.com` (subject: `[claude-starter-kit] security`)

Do **not** open a public issue for security reports.

## Response timeline

- Initial acknowledgement: within 7 days
- Assessment + fix plan: within 14 days for confirmed issues
- Public disclosure: after fix lands + reasonable patch window for downstream users

## Scope

In scope:
- `bin/*.sh` install / upgrade / contribute scripts
- `scripts/*` validators + helpers
- `rules/` + `skills/` templates with executable hooks or commands
- `.github/` workflows (if added in future versions)

Out of scope:
- Anthropic Claude Code itself — report to Anthropic
- User's own project code adopting this kit — user responsibility
- Third-party tools referenced in rules (e.g., `gh`, `jq`) — report upstream

## Supported versions

We patch the latest `v2.x.y` minor and the previous one. Older versions get fixes on best-effort basis.
