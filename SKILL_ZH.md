---
name: skill-advisor
description: >-
  从自然语言中智能分析用户需求，提取关键词和领域概念，通过 skills CLI
  (npx skills find) 搜索本地已安装的和远程的技能，然后按相关性排名推荐，
  附带安装命令。帮助用户发现有价值但未曾听闻的技能。
when_to_use: >-
  当用户用自然语言描述一个任务、项目或问题时（尤其是不提具体技能名称时）。
  例如："我想做一个..."、"怎么部署..."、"帮我转换...格式"、"推荐一个...工具"、
  "最好的测试方式是..."。也可以手动通过 /skill-advisor 调用。
disable-model-invocation: false
user-invocable: true
argument-hint: "[描述你的任务或需求]"
---

# Skill Advisor — 边工作边发现技能

别再猜有哪些技能了。用自然语言描述你的任务，Skill Advisor 帮你找到合适的工具。

## 它做什么

1. **理解你的需求** — 从请求中提取领域、工具、动作、关联概念。
2. **检查本地技能** — 找出已安装且可能有帮助的技能。
3. **搜索生态** — 用多组关键词组合在开放技能注册表中搜索。
4. **排名推荐** — 按相关性分级展示，附安装命令。

---

## 触发灵敏度配置

本技能默认 `disable-model-invocation: false`（自动触发）。
如果觉得触发太频繁，可以在 agent 配置中调整。

### 灵敏度等级（三选一）

| 等级 | 触发行为 | 设置方式 |
|------|----------|----------|
| 🔋 **激进**（默认） | 大部分消息都触发，跳过闲聊、简单问答、修错别字 | 当前默认设置 |
| ⚖️ **平衡** | 仅在用户明确描述任务或请求推荐时触发 | 在 frontmatter 添加 `paths: "!**/*.fix"` |
| 🎯 **保守** | 仅在用户显式询问技能/工具/自动化时触发 | 设置 `disable-model-invocation: true` |

---

## 工作流程

### 第一步 — 分流判断

用户的消息属于跳过列表吗？
- **跳过**：纯闲聊、简单事实问答、狭义改错别字/修小 bug
- **处理**：其他所有消息

### 第二步 — 意图分析

从用户请求中提取：

| 维度 | 问自己 | 示例："把我的 React 项目部署到 AWS" |
|------|--------|--------------------------------------|
| **领域** | 涉及什么技术领域？ | Web 部署、云基础设施 |
| **工具** | 提到或隐含了什么工具？ | React、AWS |
| **动作** | 用户想做什么？ | 部署、托管 |
| **关联** | 还可能需要什么？ | CI/CD、Docker、监控、SSL、DNS |

阅读 `references/keyword-mappings.md` 扩展关键词列表，补充用户未提及的相关概念。

### 第三步 — 本地检查

使用当前 agent 的原生方式查看已安装的技能。常见 agent 示例：

```bash
# Claude Code
ls ~/.claude/skills/ 2>/dev/null && ls .claude/skills/ 2>/dev/null

# Codex / Cursor / Copilot（universal 路径）
ls ~/.agents/skills/ 2>/dev/null && ls .agents/skills/ 2>/dev/null
```

或者使用 skills CLI（如果已安装）：
```bash
npx skills check   # 显示已安装技能和可用更新
```

标记与用户领域/动作相匹配的已安装技能。

### 第四步 — 探测可用搜索工具

搜索之前，先检查用户环境中实际可用的发现工具。不要假设特定工具存在 —
先探测再适配：

```bash
# 检查标准 skills CLI
which npx 2>/dev/null && npx skills --version 2>/dev/null

# 检查其他常见的技能管理器
which openskills 2>/dev/null
npx load-skill --version 2>/dev/null

# 检查本地技能目录中的发现类技能
ls ~/.claude/skills/ 2>/dev/null | grep -iE 'find|search|discover|browse'
ls ~/.agents/skills/ 2>/dev/null | grep -iE 'find|search|discover|browse'
```

整理出**实际可用**的搜索方式。常见的有：

| 工具 | 调用方式 | 搜索范围 |
|------|---------|---------|
| `npx skills find` | `npx skills find "<查询>"` | skills.sh 注册表 |
| `find-skills` 技能 | 调用技能并传入关键词 | GitHub 上的 SKILL.md 文件 |
| `openskills` | `openskills search "<查询>"` | 多个注册表 |
| `load-skill` | `npx load-skill search "<查询>"` | 广泛的技能索引 |
| Agent 原生搜索 | 因 agent 而异 | agent 专属 |

### 第五步 — 远程搜索

使用第四步中探测到的**所有可用工具**。不同工具覆盖生态的不同角落，
组合使用效果最好。

每个可用工具运行 3~6 次不同关键词的搜索：

```bash
# 示例：如果 npx skills 和 find-skills 都可用
npx skills find "<精确关键词>"      # skills.sh 注册表
npx skills find "<宽泛关键词>"      # 扩大范围
npx skills find "<关联领域>"        # 相邻领域
# + 用前 2~3 个关键词调用 find-skills
```

> ⚠️ **重要：** 记录结果时，务必标注每个技能是通过哪个工具找到的。
> 这样用户能清楚发现路径，也方便日后复现。

**搜索策略：**
- 从精确到宽泛（如 "react deploy aws" → "deploy hosting" → "cloud infrastructure"）
- 覆盖关联领域（如 部署 → 同时也搜 CI/CD、监控）
- 即使用户用中文提问，也搜索英文关键词（英文生态更丰富）
- 至少做一次宽泛分类搜索，捕捉意外匹配
- 不同工具找到的相同技能需去重后再展示

### 第六步 — 排名展示

按相关性打分：

| 等级 | 标准 |
|------|------|
| 🔥 **强烈推荐** | 直接对应用户提出的任务 |
| 👍 **值得考虑** | 覆盖关联或相邻的需求 |
| 💡 **可能有用** | 用户所在领域的通用工具 |

每条推荐包含：
- 技能名称和安装路径（`owner/repo@skill-name`）
- 一句话描述
- 为什么与本次请求相关
- 安装命令（`npx skills add owner/repo@skill-name`）
- **搜索来源** — 实际使用的工具，如实报告
  （如 `npx skills find "..."`、`find-skills`、`openskills`、`load-skill` 等，
  多个工具找到的标注多个）

### 第七步 — 征求用户意见

展示结果后询问：
- 想安装哪些？
- 是否需要调整搜索方向？
- 是否需要了解某个推荐的更多详情？

---

## 输出模板

```markdown
## 🔍 需求理解

**任务**: [一句话总结]
**领域**: [技术领域] | **工具**: [涉及工具] | **动作**: [核心动作]
**搜索关键词**: [使用的关键词列表]
**搜索方式**: [实际使用的工具列表，如 `npx skills find`、`find-skills`、`openskills`]

## 📦 本地已有

| 技能 | 为什么有用 |
|------|-----------|
| 名称 | 原因（或 "无匹配技能"） |

## 🌐 远程推荐

### 🔥 强烈推荐
| 技能 | 描述 | 为什么推荐 | 来源 | 安装 |
|------|------|-----------|------|------|
| ... | ... | ... | `npx skills find "..."` | `npx skills add ...` |

### 👍 值得考虑
| 技能 | 描述 | 为什么推荐 | 来源 | 安装 |
|------|------|-----------|------|------|
| ... | ... | ... | `find-skills` | `npx skills add ...` |

### 💡 可能有用
| 技能 | 描述 | 为什么推荐 | 来源 | 安装 |
|------|------|-----------|------|------|
| ... | ... | ... | `npx skills find "..."` + `find-skills` | `npx skills add ...` |

## 💭 建议

[1~2 句推荐安装组合的总结]

---
需要我安装哪些？或者换个方向搜索？
```

---

## 原则

1. **广搜精选** — 关键词撒大网，但只展示最匹配的结果。
2. **解释关联** — 每条推荐必须说明与用户需求的联系。
3. **考虑上下游** — 用户任务的前置和后置环节还需要什么？
4. **双语覆盖** — 始终尝试英文关键词（技能生态英文占主导）。
5. **每级最多 5 条** — 保持聚焦，多不等于好。
6. **默认项目级安装** — 安装到项目范围（不加 `-g`），每个项目独立管理依赖。
   用户如需全局可用可自行加 `-g`。

---

## 兼容性

基于 [Agent Skills](https://agentskills.io) 开放标准构建。已测试：

- **Claude Code** — 完整支持（symlink + universal install）
- **Codex** — universal install 路径
- **Cursor** — universal install 路径
- **GitHub Copilot** — universal install 路径
- **Gemini CLI** — 需要 skills CLI 可用
- 其他支持 Agent Skills 标准的 agent

**依赖：** `npx skills` CLI（首次使用自动安装，或 `npm install -g skills-cli`）。
