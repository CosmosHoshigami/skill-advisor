# Task Match Skills — Discover Skills While You Work

> Stop guessing which agent skills exist. Describe your task naturally and
> Task Match Skills finds the right tools for you.

[![Agent Skills](https://img.shields.io/badge/Agent%20Skills-Compatible-blue)](https://agentskills.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## What is this?

Task Match Skills is an **agent skill** that automatically analyzes your requests
and searches the open agent skills ecosystem to find relevant tools. You
describe what you want to do — it finds skills that can help.

### Example

```
You:  "I want to deploy my React app to AWS with CI/CD"

Task Match Skills:
  🔍 Analyzes: domain=deployment, tools=React/AWS, action=deploy+automate
  📦 Checks: your installed skills
  🌐 Searches: "react deploy aws", "ci cd pipeline", "cloud infrastructure"...
  📋 Recommends: ranked list with install commands
```

## Quick Install

```bash
npx skills add CosmosHoshigami/task-match-skills
```

This installs the skill to your current project. To install globally (all projects),
add the `-g` flag:

```bash
npx skills add CosmosHoshigami/task-match-skills -g
```

Requires [npx skills CLI](https://skills.sh). Works with Claude Code, Codex,
Cursor, GitHub Copilot, and any agent supporting the
[Agent Skills](https://agentskills.io) standard.

## Usage

Task Match Skills is designed to activate automatically when you describe a task
in natural language. However, auto-invocation behavior varies across agents.
**To guarantee it runs, explicitly invoke the skill before describing your
task** — for example, type `/task-match-skills` followed by your request in Claude
Code, or use your agent's equivalent skill invocation command. This ensures
the skill searches for relevant tools before you begin working.

## Features

- 🧠 **Intent-aware** — understands domains, tools, and actions from natural language
- 🔍 **Multi-angle search** — searches with multiple keyword combinations for better coverage
- 📊 **Tiered recommendations** — Strong match / Worth considering / Might be useful
- 🌐 **Cross-agent** — works with Claude Code, Codex, Cursor, Copilot, and more
- 🌍 **Bilingual** — accepts input in any language; searches in English for best results
- ⚡ **Configurable** — three sensitivity levels (aggressive / balanced / conservative)

## Trigger Sensitivity

Task Match Skills ships in **aggressive** mode (triggers on most messages). If you
prefer less frequent suggestions:

| Mode | When it triggers | How to switch |
|------|-----------------|---------------|
| 🔋 Aggressive | Most messages (skips chitchat, simple Q&A, typo fixes) | Default |
| ⚖️ Balanced | Clear task descriptions and tool requests | Edit SKILL.md frontmatter |
| 🎯 Conservative | User explicitly asks about skills/tools | Set `disable-model-invocation: true` |

## Requirements

- An agent that supports the [Agent Skills](https://agentskills.io) standard
- `npx skills` CLI available (auto-installed on first use)

## Structure

```
task-match-skills/
├── SKILL.md                         # Main skill definition
├── README.md                        # This file
├── LICENSE                          # MIT
├── examples/
│   └── example-output.md            # Sample output walkthrough
└── tests/
    └── validate-skill.sh            # Validation script
```

## Contributing

1. Fork this repository
2. Create a feature branch
3. Add your changes
4. Run `./tests/validate-skill.sh` to verify SKILL.md validity
5. Submit a PR

### Ideas for contribution

- Improve trigger sensitivity heuristics
- Add support for additional agent platforms
- Translate output templates to more languages

## License

MIT — see [LICENSE](LICENSE) for details.
