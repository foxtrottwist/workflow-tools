#!/usr/bin/env python3
"""
aggregate-findings.py

Reads partition-*.md files from a code-audit state directory, deduplicates
findings, sorts by severity, and writes:
  - findings.md: human-readable aggregated report
  - findings-summary.local.json: machine-readable summary with check results
"""

import sys
import os
import re
import json
import glob
from datetime import datetime, timezone


SEVERITY_ORDER = {"CRITICAL": 0, "WARNING": 1, "INFO": 2}


def parse_partition_file(path):
    """Parse a partition-*.md file and return list of finding dicts."""
    findings = []
    try:
        with open(path, encoding="utf-8") as f:
            content = f.read()
    except OSError as e:
        print(f"Warning: could not read {path}: {e}", file=sys.stderr)
        return findings

    # Match finding blocks: #### [SEVERITY]: [Title]
    # followed by Location / Issue / Fix bullet points
    pattern = re.compile(
        r"####\s+(CRITICAL|WARNING|INFO):\s+(.+?)\n"
        r"((?:[-*]\s+\*\*\w+\*\*:.*\n?)*)",
        re.MULTILINE,
    )

    for match in pattern.finditer(content):
        severity = match.group(1).strip()
        title = match.group(2).strip()
        body = match.group(3)

        location = ""
        issue = ""
        fix = ""

        loc_match = re.search(r"\*\*Location\*\*:\s*(.+)", body)
        issue_match = re.search(r"\*\*Issue\*\*:\s*(.+)", body)
        fix_match = re.search(r"\*\*Fix\*\*:\s*(.+)", body)

        if loc_match:
            location = loc_match.group(1).strip()
        if issue_match:
            issue = issue_match.group(1).strip()
        if fix_match:
            fix = fix_match.group(1).strip()

        findings.append(
            {
                "severity": severity,
                "title": title,
                "location": location,
                "issue": issue,
                "fix": fix,
                "source": os.path.basename(path),
            }
        )

    return findings


def deduplicate(findings):
    """Remove duplicate findings keyed on (location, title)."""
    seen = set()
    unique = []
    for f in findings:
        key = (f["location"], f["title"])
        if key not in seen:
            seen.add(key)
            unique.append(f)
    return unique, len(findings) - len(unique)


def sort_findings(findings):
    """Sort findings: CRITICAL first, then WARNING, then INFO."""
    return sorted(findings, key=lambda f: SEVERITY_ORDER.get(f["severity"], 99))


def render_findings_md(findings, project_dir, partitions_read):
    """Render the aggregated findings.md content."""
    counts = {s: 0 for s in SEVERITY_ORDER}
    for f in findings:
        counts[f["severity"]] = counts.get(f["severity"], 0) + 1

    lines = [
        f"# Audit Summary: {os.path.basename(project_dir.rstrip('/'))}\n",
        "## Overview",
        f"- Partitions: {partitions_read}",
        f"- Critical: {counts['CRITICAL']} | Warnings: {counts['WARNING']} | Info: {counts['INFO']}",
        "",
    ]

    for severity in ["CRITICAL", "WARNING", "INFO"]:
        section_findings = [f for f in findings if f["severity"] == severity]
        if not section_findings:
            continue
        section_label = {
            "CRITICAL": "Critical Issues",
            "WARNING": "Warnings",
            "INFO": "Info",
        }[severity]
        lines.append(f"## {section_label}")
        lines.append("")
        for f in section_findings:
            lines.append(f"#### {severity}: {f['title']}")
            if f["location"]:
                lines.append(f"- **Location**: {f['location']}")
            if f["issue"]:
                lines.append(f"- **Issue**: {f['issue']}")
            if f["fix"]:
                lines.append(f"- **Fix**: {f['fix']}")
            lines.append("")

    return "\n".join(lines)


def build_summary_json(checks, total, counts, partitions_read, duplicates_removed):
    return {
        "script": "aggregate-findings",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "checks": checks,
        "summary": {
            "total_findings": total,
            "critical": counts.get("CRITICAL", 0),
            "warning": counts.get("WARNING", 0),
            "info": counts.get("INFO", 0),
            "partitions_read": partitions_read,
            "duplicates_removed": duplicates_removed,
        },
    }


def main():
    if len(sys.argv) != 2:
        print("Usage: aggregate-findings.py <audit-dir>", file=sys.stderr)
        print("  e.g. aggregate-findings.py .workflow.local/code-audit/my-project/", file=sys.stderr)
        sys.exit(1)

    audit_dir = sys.argv[1]

    if not os.path.isdir(audit_dir):
        print(f"Error: directory not found: {audit_dir}", file=sys.stderr)
        sys.exit(1)

    partition_files = sorted(
        glob.glob(os.path.join(audit_dir, "partition-*.md"))
    )

    checks = []
    all_findings = []
    partitions_read = len(partition_files)

    # Check 1: parse partitions
    for path in partition_files:
        findings = parse_partition_file(path)
        all_findings.extend(findings)

    checks.append(
        {
            "name": "parse_partitions",
            "passed": True,
            "details": f"Read {partitions_read} partition file{'s' if partitions_read != 1 else ''}",
        }
    )

    # Check 2: deduplicate
    unique_findings, duplicates_removed = deduplicate(all_findings)
    checks.append(
        {
            "name": "dedup",
            "passed": True,
            "details": f"Removed {duplicates_removed} duplicate{'s' if duplicates_removed != 1 else ''}",
        }
    )

    # Sort by severity
    sorted_findings = sort_findings(unique_findings)

    # Render and write findings.md
    findings_path = os.path.join(audit_dir, "findings.md")
    findings_md = render_findings_md(sorted_findings, audit_dir, partitions_read)
    try:
        with open(findings_path, "w", encoding="utf-8") as f:
            f.write(findings_md)
        checks.append({"name": "output", "passed": True})
    except OSError as e:
        checks.append({"name": "output", "passed": False, "details": str(e)})
        print(f"Error: could not write findings.md: {e}", file=sys.stderr)
        sys.exit(1)

    # Count by severity
    counts = {s: 0 for s in SEVERITY_ORDER}
    for f in sorted_findings:
        counts[f["severity"]] = counts.get(f["severity"], 0) + 1

    # Write findings-summary.local.json
    summary = build_summary_json(
        checks,
        total=len(sorted_findings),
        counts=counts,
        partitions_read=partitions_read,
        duplicates_removed=duplicates_removed,
    )
    summary_path = os.path.join(audit_dir, "findings-summary.local.json")
    try:
        with open(summary_path, "w", encoding="utf-8") as f:
            json.dump(summary, f, indent=2)
            f.write("\n")
    except OSError as e:
        print(f"Warning: could not write findings-summary.local.json: {e}", file=sys.stderr)

    # Print summary to stdout
    s = summary["summary"]
    print(
        f"Aggregated {s['total_findings']} findings "
        f"({s['critical']} critical, {s['warning']} warning, {s['info']} info) "
        f"from {s['partitions_read']} partition(s). "
        f"Removed {s['duplicates_removed']} duplicate(s)."
    )
    print(f"Output: {findings_path}")


if __name__ == "__main__":
    main()
