# Knowledge Mode

Phase templates for knowledge work domains: research, writing, analysis, and planning. Each phase maps to a Task tool dispatch with `max_turns` controlling iteration depth.

## Research Synthesis (R1-R4)

For literature review, source synthesis, investigation.

```markdown
- [ ] **R1**: Source Discovery
  - Criteria: {N} relevant sources identified, topic areas mapped
  - Output: `sources/bibliography.md`
  - Max turns: 5

- [ ] **R2**: Source Evaluation
  - Criteria: Each source assessed for credibility, relevance, recency
  - Output: `sources/evaluation.md`
  - Max turns: 5

- [ ] **R3**: Pattern Extraction
  - Criteria: Key themes, contradictions, gaps identified
  - Output: `analysis/patterns.md`
  - Max turns: 5

- [ ] **R4**: Synthesis
  - Criteria: Coherent narrative integrating sources
  - Output: `outputs/synthesis.md`
  - Max turns: 8
```

### Phase Guidance

**R1: Source Discovery**
- Map topic areas first, then identify source types
- Aim for breadth before depth
- Note gaps in available sources

**R2: Source Evaluation**
- Use consistent evaluation dimensions (credibility, recency, synthesis value)
- Identify priority sources per topic area
- Flag conflicting or contradictory sources

**R3: Pattern Extraction**
- Look for themes, contradictions, and gaps
- Cross-reference claims across sources
- Note confidence levels

**R4: Synthesis**
- Build narrative from patterns, not source-by-source
- Integrate conflicting viewpoints
- Support claims with specific citations

## Document Production (D1-D4)

For reports, articles, proposals, written deliverables.

```markdown
- [ ] **D1**: Structure Development
  - Criteria: Outline with section purposes, flow logic
  - Output: `drafts/outline.md`
  - Max turns: 3

- [ ] **D2**: Section Drafting
  - Criteria: Complete first draft of all sections
  - Output: `drafts/draft-v1.md`
  - Max turns: 5

- [ ] **D3**: Revision Pass
  - Criteria: Clarity, flow, evidence integration improved
  - Output: `drafts/draft-v2.md`
  - Max turns: 5

- [ ] **D4**: Final Polish
  - Criteria: Voice consistency, formatting, ready for delivery
  - Output: `outputs/final.md`
  - Max turns: 3
```

### Phase Guidance

**D1: Structure Development**
- Purpose-driven outline (why each section exists)
- Logical flow between sections
- Identify evidence needed per section

**D2: Section Drafting**
- Get ideas on paper first
- Flag weak areas for revision
- Maintain consistent voice

**D3: Revision Pass**
- Strengthen thesis and arguments
- Add specific examples and evidence
- Improve transitions and flow

**D4: Final Polish**
- Voice and tone consistency
- Formatting for audience
- Remove redundancy

### Quality Checklist

- [ ] Clear thesis or central argument
- [ ] Supporting points with evidence
- [ ] Coherent flow between sections
- [ ] Appropriate tone for audience
- [ ] No unsupported claims

## Analysis Workflow (A1-A4)

For data interpretation, pattern identification, recommendations.

```markdown
- [ ] **A1**: Data Gathering
  - Criteria: All relevant inputs collected, organized
  - Output: `data/collected/`
  - Max turns: 5

- [ ] **A2**: Pattern Identification
  - Criteria: Trends, anomalies, relationships documented
  - Output: `analysis/patterns.md`
  - Max turns: 5

- [ ] **A3**: Interpretation
  - Criteria: Findings contextualized, implications drawn
  - Output: `analysis/interpretation.md`
  - Max turns: 5

- [ ] **A4**: Recommendations
  - Criteria: Actionable next steps with rationale
  - Output: `outputs/recommendations.md`
  - Max turns: 5
```

### Pattern Categories (A2)

- **Trends**: Directional changes over time
- **Anomalies**: Unexpected values or behaviors
- **Correlations**: Relationships between variables
- **Gaps**: Missing data or coverage

### Phase Guidance

**A1: Data Gathering**
- Organize inputs by type/source
- Note data quality issues
- Identify gaps in coverage

**A2: Pattern Identification**
- Look for all pattern categories
- Document with specific examples
- Note confidence levels

**A3: Interpretation**
- Contextualize findings
- Consider alternative explanations
- Note confidence levels

**A4: Recommendations**
- Actionable next steps
- Rationale tied to analysis
- Risk/benefit considerations

## Planning Workflow (P1-P4)

For decisions, strategy, project planning.

```markdown
- [ ] **P1**: Context Gathering
  - Criteria: Current state, constraints, stakeholders mapped
  - Output: `planning/context.md`
  - Max turns: 5

- [ ] **P2**: Option Generation
  - Criteria: Multiple viable approaches identified
  - Output: `planning/options.md`
  - Max turns: 5

- [ ] **P3**: Evaluation
  - Criteria: Options assessed against criteria, tradeoffs clear
  - Output: `planning/evaluation.md`
  - Max turns: 5

- [ ] **P4**: Decision Documentation
  - Criteria: Recommended path with rationale, next steps
  - Output: `outputs/decision.md`
  - Max turns: 3
```

### Evaluation Dimensions (P3)

- **Feasibility**: Can we do this?
- **Impact**: What does it achieve?
- **Risk**: What could go wrong?
- **Cost**: Time, money, effort
- **Reversibility**: Can we undo it?

### Phase Guidance

**P1: Context Gathering**
- Current state assessment
- Constraints (time, resources, dependencies)
- Stakeholder mapping

**P2: Option Generation**
- Multiple viable approaches (3+ minimum)
- Include unconventional options
- Note initial feasibility concerns

**P3: Evaluation**
- Assess all dimensions
- Make tradeoffs explicit
- Use consistent scoring if applicable

**P4: Decision Documentation**
- Recommended path with rationale
- Rejected alternatives and why
- Next steps and owners
- Success criteria

## Combining Domains

Some tasks span domains:

**Research then Writing**: R1-R4 then D1-D4
**Analysis then Planning**: A1-A4 then P1-P4
**Research then Analysis**: R1-R2 then A1-A4

Note dependencies in the plan file.
