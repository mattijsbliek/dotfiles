# Vendored skills

These skills were originally installed via `npx skills` (https://skills.sh) into
`~/.agents/skills` and symlinked from there into `~/.claude/skills`. They're now
vendored directly into this repo instead, because the `skills` CLI fully deletes
and recreates its canonical skill directories on every `add`/`update` — it can't
coexist with a symlink pointing elsewhere. Updates are manual from here: diff
against the source below and copy over what you want.

| Skill | Source repo | Path |
|---|---|---|
| codebase-design | mattpocock/skills | skills/engineering/codebase-design/SKILL.md |
| diagnosing-bugs | mattpocock/skills | skills/engineering/diagnosing-bugs/SKILL.md |
| domain-modeling | mattpocock/skills | skills/engineering/domain-modeling/SKILL.md |
| edit-article | mattpocock/skills | skills/personal/edit-article/SKILL.md |
| grill-with-docs | mattpocock/skills | skills/engineering/grill-with-docs/SKILL.md |
| grilling | mattpocock/skills | skills/productivity/grilling/SKILL.md |
| handoff | mattpocock/skills | skills/productivity/handoff/SKILL.md |
| implement | mattpocock/skills | skills/engineering/implement/SKILL.md |
| improve-codebase-architecture | mattpocock/skills | skills/engineering/improve-codebase-architecture/SKILL.md |
| prototype | mattpocock/skills | skills/engineering/prototype/SKILL.md |
| research | mattpocock/skills | skills/engineering/research/SKILL.md |
| tdd | mattpocock/skills | skills/engineering/tdd/SKILL.md |
| to-spec | mattpocock/skills | skills/engineering/to-spec/SKILL.md |
| to-tickets | mattpocock/skills | skills/engineering/to-tickets/SKILL.md |
| ubiquitous-language | mattpocock/skills | skills/deprecated/ubiquitous-language/SKILL.md |
| wayfinder | mattpocock/skills | skills/engineering/wayfinder/SKILL.md |
| attach-github-assets | intercom/2x-skills | plugins/pr-tools/skills/attach-github-assets/SKILL.md |
