---
name: skill-advisor
description: >-
  Intelligently analyzes user needs from natural language, extracts keywords
  and domain concepts, searches both locally installed and remote skills via
  the skills CLI (npx skills find), then presents ranked recommendations with
  relevance scores and install commands. Helps users discover skills they
  didn't know existed.
when_to_use: >-
  When a user describes a task, project, or problem in natural language
  (especially without mentioning specific skills). Examples: "I want to build
  a...", "How do I deploy...", "Can you help me convert...", "Recommend tools
  for...", "What's the best way to test...". Also trigger-able manually via
  /skill-advisor.
disable-model-invocation: false
user-invocable: true
argument-hint: "[describe your task or need]"
---

# Skill Advisor — Discover Skills While You Work

Stop guessing which skills exist. Describe your task in natural language and
Skill Advisor finds the right tools for you.

## What It Does

1. **Understands your needs** — Extracts domain, tools, actions, and related
   concepts from your request.
2. **Checks local skills** — Finds already-installed skills that might help.
3. **Searches the ecosystem** — Queries the open agent skills registry with
   multiple keyword combinations.
4. **Ranks & recommends** — Presents findings by relevance tier with install
   commands.

---

## Trigger Sensitivity Configuration

This skill ships with `disable-model-invocation: false` (auto-trigger on).
If you find it triggers too often, adjust in your agent's settings.

### Sensitivity levels (choose one)

| Level | Behavior | How to set |
|-------|----------|------------|
| 🔋 **Aggressive** (default) | Triggers on most messages; skips only chitchat, simple Q&A, typo fixes | Current setting |
| ⚖️ **Balanced** | Triggers when user clearly describes a task or asks for recommendations | Add `paths: "!**/*.fix"` to frontmatter |
| 🎯 **Conservative** | Only triggers when user asks about skills/tools/automation explicitly | Set `disable-model-invocation: true` |

---

## Workflow

### Step 1 — Triage

Does the user's message fall into the skip list?
- **Skip**: Pure chitchat, simple fact Q&A, narrow typo/bug fix
- **Process**: Everything else

### Step 2 — Analyze Intent

Extract from the user's request:

| Dimension | Ask yourself | Example: "deploy my React app to AWS" |
|-----------|-------------|---------------------------------------|
| **Domain** | What tech area? | Web deployment, cloud infra |
| **Tools** | What tools mentioned/implied? | React, AWS |
| **Action** | What does user want to do? | Deploy, host |
| **Related** | What else might they need? | CI/CD, Docker, monitoring, SSL, DNS |

Read `references/keyword-mappings.md` to expand your keyword list with
related concepts the user may not have mentioned.

### Step 3 — Check Local

Use your agent's native mechanism to see what skills are already installed.
Examples for common agents:

```bash
# Claude Code
ls ~/.claude/skills/ 2>/dev/null && ls .claude/skills/ 2>/dev/null

# Codex / Cursor / Copilot (universal path)
ls ~/.agents/skills/ 2>/dev/null && ls .agents/skills/ 2>/dev/null
```

Or use the skills CLI (if installed):
```bash
npx skills check   # shows installed skills and available updates
```

Note any installed skills that match the user's domain/action.

### Step 4 — Detect Available Search Tools

Before searching, quickly check which discovery tools are available in the
user's environment. Don't assume any specific tool — detect and adapt:

```bash
# Check for the standard skills CLI
which npx 2>/dev/null && npx skills --version 2>/dev/null

# Check for other common skill managers
which openskills 2>/dev/null
npx load-skill --version 2>/dev/null

# Check local skill directories for discovery-oriented skills
ls ~/.claude/skills/ 2>/dev/null | grep -iE 'find|search|discover|browse'
ls ~/.agents/skills/ 2>/dev/null | grep -iE 'find|search|discover|browse'
```

Build a list of **actually available** search methods. Common ones include:

| Tool | How to invoke | What it searches |
|------|--------------|-----------------|
| `npx skills find` | `npx skills find "<query>"` | skills.sh registry |
| `find-skills` skill | Invoke the skill with keywords | GitHub SKILL.md files |
| `openskills` | `openskills search "<query>"` | Multiple registries |
| `load-skill` | `npx load-skill search "<query>"` | Broad skill index |
| Agent-native search | Varies by agent | Agent-specific |

### Step 5 — Search Remote

Use **all available tools** detected in Step 4. Each tool may cover a
different part of the ecosystem, so combining them gives the best results.

Run 3–6 searches per available tool with varied keywords:

```bash
# Example: if npx skills and find-skills are both available
npx skills find "<exact keywords>"      # skills.sh registry
npx skills find "<broader keywords>"    # widen scope
npx skills find "<related domain>"      # adjacent areas
# + invoke find-skills with the top 2–3 keywords
```

> ⚠️ **Important:** When reporting results, always record which tool each
> skill was found with. This lets users understand the discovery path and
> reproduce it later.

**Search strategy:**
- Start specific, then broaden (e.g. "react deploy aws" → "deploy hosting" → "cloud infrastructure")
- Cover related domains (e.g. deploying → also search CI/CD, monitoring)
- Search in English even if the user writes in another language
- At least one broad category search to catch unexpected matches
- Deduplicate results before presenting (same skill found by multiple tools)

### Step 6 — Rank & Present

Score results by relevance:

| Tier | Criteria |
|------|----------|
| 🔥 **Strong match** | Directly addresses the user's stated task |
| 👍 **Worth considering** | Covers a related or adjacent need |
| 💡 **Might be useful** | Broader utility in the user's domain |

For each recommendation, include:
- Skill name and install path (`owner/repo@skill-name`)
- One-line description
- Why it's relevant to this specific request
- The install command (`npx skills add owner/repo@skill-name`)
- **Search source** — the actual tool that found this skill
  (report whatever was used: `npx skills find "..."`, `find-skills`,
  `openskills`, `load-skill`, etc. — multiple if found by more than one)

### Step 7 — Ask the User

Present findings then ask:
- Which ones they want installed
- Whether to search in a different direction
- If they want more detail on any recommendation

---

## Output Template

```markdown
## 🔍 What I understood

**Task**: [one-line summary]
**Domain**: [tech area] | **Tools**: [tools] | **Action**: [action]
**Search keywords**: [list of keywords used]
**Search methods**: [list actually-used tools, e.g. `npx skills find`, `find-skills`, `openskills`]

## 📦 Already installed

| Skill | Useful because |
|-------|---------------|
| name | reason (or "No matching skills found") |

## 🌐 Recommendations

### 🔥 Strong matches
| Skill | Description | Why this helps | Source | Install |
|-------|------------|---------------|--------|---------|
| ... | ... | ... | `npx skills find "..."` | `npx skills add ...` |

### 👍 Worth considering
| Skill | Description | Why this helps | Source | Install |
|-------|------------|---------------|--------|---------|
| ... | ... | ... | `find-skills` | `npx skills add ...` |

### 💡 Might be useful
| Skill | Description | Why this helps | Source | Install |
|-------|------------|---------------|--------|---------|
| ... | ... | ... | `npx skills find "..."` + `find-skills` | `npx skills add ...` |

## 💭 Recommendation

[1–2 sentence summary of the best install combo]

---
Want me to install any of these? Or search in a different direction?
```

---

## Principles

1. **Search generously, recommend selectively** — Cast a wide net with keywords
   but only show the best matches.
2. **Explain the "why"** — Every recommendation must connect back to the user's
   request.
3. **Think upstream and downstream** — What comes before and after the user's
   stated task?
4. **Bilingual coverage** — Always try English keywords (the ecosystem is
   English-dominant).
5. **Max 5 per tier** — Keep recommendations focused; more isn't better.
6. **Default to project install** — Install skills into the project scope
   (no `-g` flag) so each project keeps its own dependencies. Users who
   prefer global can add `-g`.

---

## Compatibility

Built for the [Agent Skills](https://agentskills.io) open standard. Tested with:

- **Claude Code** — full support (symlink + universal install)
- **Codex** — universal install path
- **Cursor** — universal install path
- **GitHub Copilot** — universal install path
- **Gemini CLI** — requires skills CLI available
- Other agents supporting the Agent Skills standard

**Requires:** `npx skills` CLI (installed automatically on first use, or via
`npm install -g skills-cli`).
