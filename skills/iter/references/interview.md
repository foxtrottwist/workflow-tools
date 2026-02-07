# Interview Questions

Discovery questions for plan mode. Use **AskUserQuestion** during discovery interviews when user input is needed to finalize scope or resolve ambiguity.

## Tool Usage

```
Invoke AskUserQuestion with:
- question: The question text
- options: Array of choices (first option can end with "(Recommended)")
- multiSelect: true/false (allow multiple selections)
```

Users can always select "Other" to provide free text input.

## Core Questions (Both Modes)

### 1. Outcome

```yaml
question: "What outcome do you need?"
options:
  - "{inferred from prompt} (Recommended)"
  - "Implement a feature"
  - "Fix a bug"
  - "Research/analyze"
  - "Write a document"
  - "Plan/decide"
```

### 2. Completion Criteria

```yaml
question: "What does 'done' look like?"
multiSelect: true
options:
  - "Specific deliverable"
  - "Quality threshold"
  - "All tests passing"
  - "Manual verification works"
  - "Code review approved"
```

### 3. Constraints

```yaml
question: "Any constraints?"
multiSelect: true
options:
  - "Timeline pressure"
  - "Format requirements"
  - "Backward compatibility"
  - "Performance critical"
  - "None / flexible"
```

## Development Mode Questions

### 4. Technical Approach

```yaml
question: "Technical approach?"
options:
  - "Follow existing patterns (Recommended)"
  - "Specific approach: [describe]"
  - "Need to explore codebase first"
  - "Let me decide based on what I find"
```

### 5. UI/Frontend (if applicable)

```yaml
question: "UI requirements?"
options:
  - "Match existing design system"
  - "New design provided"
  - "Minimal viable UI"
  - "Need design review first"
```

### 6. API/Backend (if applicable)

```yaml
question: "API style?"
options:
  - "Follow existing conventions (Recommended)"
  - "REST"
  - "GraphQL"
  - "RPC"
```

### 7. Refactor Scope (if applicable)

```yaml
question: "Refactor scope?"
options:
  - "Minimal - fix immediate issue"
  - "Moderate - improve surrounding code"
  - "Comprehensive - full module cleanup"
```

## Knowledge Mode Questions

### 4. Source Requirements (Research)

```yaml
question: "What sources should be included?"
multiSelect: true
options:
  - "Academic / peer-reviewed"
  - "Industry reports"
  - "News / journalism"
  - "Primary sources"
  - "Flexible"
```

### 5. Scope Boundary (Research)

```yaml
question: "What's the scope boundary?"
options:
  - "Broad overview"
  - "Specific aspect: [describe]"
  - "Time-bounded: [period]"
  - "Geographic focus: [region]"
```

### 6. Target Format (Writing)

```yaml
question: "What's the target format?"
options:
  - "Report / white paper"
  - "Article / blog post"
  - "Executive summary"
  - "Proposal"
  - "Other: [describe]"
```

### 7. Audience (Writing)

```yaml
question: "Who's the audience?"
options:
  - "Technical experts"
  - "General business"
  - "Executive level"
  - "Public / general"
```

### 8. Available Inputs (Analysis)

```yaml
question: "What data/inputs are available?"
multiSelect: true
options:
  - "Files to analyze"
  - "Sources to gather from"
  - "Existing research"
  - "Need to identify inputs"
```

### 9. Decision Context (Planning)

```yaml
question: "What's the decision context?"
multiSelect: true
options:
  - "Options already identified"
  - "Constraints known"
  - "Stakeholders involved"
  - "Need to gather context"
```

## Question Limits

- **Max questions**: 4-6 per interview
- **Timeout**: AskUserQuestion has 60s timeout
- **Fallback**: If uncertain, note in plan file for clarification during planning

## Output: Plan File

Generate after interview and write to the plan file (specified by plan mode system):

```markdown
# Iterative: {Task Name}

**Mode:** {development|knowledge}
**Domain:** {feature|bug|refactor|research|writing|analysis|planning}

## Outcome Needed
{From question 1}

## Done When
{From question 2, as checklist}

## Constraints
{From question 3}

## Approach / Notes
{From remaining questions, open questions}

## Tasks / Phases
{Decomposed work units — see development.md or knowledge.md}
```
