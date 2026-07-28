# Instruction Authoring Principles

Eight principles drawn from academic research (ETH Zurich, SkillsBench) and practitioner experience (Boris Cherny). These apply across all artifact types — prompt templates, CLAUDE.md, skills, and agent definitions.

Reference principles by number (P1–P9) in reviews and guardrails.

---

## P1: Prescribe, Don't Describe

Include only hard requirements an agent cannot discover on its own. Build tools, test runners, naming conventions that differ from defaults. Agents already navigate codebases — 67% of human-written context files include repo overviews that don't reduce exploration steps (ETH Zurich).

- Good: `Use uv for package management`
- Bad: `This project uses uv for package management, which handles virtual environments and…`

## P2: Write Reactively, Not Proactively

Start minimal. Add rules only when you observe a failure. Each entry should trace to a specific incident. LLM-generated context files performed worse than no context file (ETH Zurich). Add entries only after mistakes, not in anticipation.

## P3: Focus on 2–3 Modules — Eliminate Templates

Each skill covers one procedure with at least one worked example. Remove output format templates — they enable shortcuts that bypass the procedure. Comprehensive skills degraded performance by -2.9pp (SkillsBench).

Replace `[placeholder]` templates with constraint lines that say what must be true.

## P4: Invest in Verification, Not Instruction

Give the agent a way to check its own work. A one-line test command is worth more than a paragraph of style guidance. Context files increase exploration tokens 14–22% without improving outcomes; verification loops 2–3x quality (Boris Cherny).

## P5: Specialize for Your Domain

Don't write skills for things the model already knows (REST patterns, React structure, Git workflows). Write for unique conventions, domain-specific APIs, unusual architectures, post-training-cutoff knowledge, and proprietary tooling. Generic software engineering gained only +4.5pp; specialized domains gained up to +51.9pp (SkillsBench).

## P6: Protect Context with Subagents

Use agents for complex subtasks. Each agent gets only the context it needs. Results flow back without polluting the main session. Context files increase reasoning tokens 14–22% per task — for parallel workflows, this compounds multiplicatively (ETH Zurich).

## P7: Never Auto-Generate Context Files

Do not use `claude init` or automated tools to generate CLAUDE.md content. LLM-generated context files: -0.5% to -2% resolve rate (ETH Zurich). Self-generated skills: -1.3pp average (SkillsBench).

## P9: Judgement Over Rules

For content that isn't discoverable and does need to be said, prefer a judgement call tied to context over a blanket rule. Claude 5-generation models infer correct behavior from surrounding context; enumerated rules force extra reasoning cycles to reconcile conflicts and stop transferring once the situation shifts slightly.

- Bad: `Never write multi-paragraph docstrings.`
- Good: `Write code that reads like the surrounding code: match its comment density, naming, and idiom.`

P1 asks whether the content belongs at all. P9 asks, for what remains, whether it's phrased as an inferable judgement or an absolute rule.

## P8: Separate Routing from Execution

Skill descriptions are always loaded in context, even when the body is not. The description routes (when to invoke); the body executes (how to act).

| | Description (frontmatter) | Body (SKILL.md content) |
|---|---|---|
| **Purpose** | Routing — when to invoke | Execution — how to act |
| **Always in context?** | Yes | No (loaded on invocation) |
| **Content** | Trigger phrases, use-when framing | Procedure, worked example, constraints |
| **Behavioral instructions?** | Never | Yes |

Optimized descriptions improve activation from 20% to 50%; adding quoted trigger examples reaches 90% (skill routing analysis).
