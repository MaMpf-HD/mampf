#!/usr/bin/env python3

import json
import os
import sys
from collections import Counter


def severity_counts(vulnerabilities):
    counts = Counter()
    for vulnerability in vulnerabilities:
        counts[vulnerability.get("Severity", "UNKNOWN")] += 1
    return counts


def main():
    path = os.environ.get("TRIVY_RESULTS_PATH", "trivy-results.json")
    if not os.path.exists(path):
        output = "\n".join(
            [
                "## Trivy Scan",
                "",
                "Trivy did not produce a results file.",
                f"Expected file: `{path}`",
                "The image build will continue, but no scan summary is available for this run.",
            ]
        )
        print(output)
        step_summary = os.environ.get("GITHUB_STEP_SUMMARY")
        if step_summary:
            with open(step_summary, "a", encoding="utf-8") as handle:
                handle.write(output + "\n")
        return 0

    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except json.JSONDecodeError:
        output = "\n".join(
            [
                "## Trivy Scan",
                "",
                "Trivy produced an unreadable results file.",
                f"Results file: `{path}`",
                "The image build will continue, but no scan summary is available for this run.",
            ]
        )
        print(output)
        step_summary = os.environ.get("GITHUB_STEP_SUMMARY")
        if step_summary:
            with open(step_summary, "a", encoding="utf-8") as handle:
                handle.write(output + "\n")
        return 0

    results = data.get("Results") or []

    os_results = []
    dependency_results = []
    for result in results:
        if result.get("Class") == "os-pkgs":
            os_results.append(result)
        else:
            dependency_results.append(result)

    os_vulnerabilities = [
        vulnerability
        for result in os_results
        for vulnerability in (result.get("Vulnerabilities") or [])
    ]
    vulnerable_dependency_results = [
        result for result in dependency_results if result.get("Vulnerabilities")
    ]

    lines = []
    lines.append("## Trivy Scan")
    lines.append("")
    lines.append("Scanned image references:")
    lines.append(
        f"- MaMpf deploy image: `{os.environ['IMAGE_DIGEST_REFERENCE']}`"
    )
    lines.append("")
    lines.append("Not scanned by this workflow:")
    lines.append("- Separate service images such as Redis and Memcached")
    lines.append("")

    os_target = "runtime image"
    os_type = "os"
    if os_results:
        os_target = os_results[0].get("Target") or os_target
        os_type = os_results[0].get("Type") or os_type

    os_counts = severity_counts(os_vulnerabilities)
    lines.append("Scanned surfaces inside the MaMpf deploy image:")
    lines.append(
        f"- Base image / OS packages (`{os_type}`): {len(os_vulnerabilities)} matching vulnerabilities"
    )
    if os_vulnerabilities:
        lines.append(
            "  Severities: " + ", ".join(
                f"{severity} {os_counts[severity]}"
                for severity in ("CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN")
                if os_counts[severity]
            )
        )
        lines.append(f"  Target: `{os_target}`")

    if vulnerable_dependency_results:
        lines.append("- Application dependencies found in the image:")
        for result in vulnerable_dependency_results:
            vulnerabilities = result.get("Vulnerabilities") or []
            counts = severity_counts(vulnerabilities)
            target = result.get("Target") or "unknown target"
            target_type = result.get("Type") or "unknown"
            lines.append(
                "  - "
                f"`{target}` ({target_type}): {len(vulnerabilities)} vulnerabilities"
                + " ["
                + ", ".join(
                    f"{severity} {counts[severity]}"
                    for severity in ("CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN")
                    if counts[severity]
                )
                + "]"
            )
            for vulnerability in vulnerabilities:
                fixed = vulnerability.get("FixedVersion") or "no fix listed"
                package = vulnerability.get("PkgName") or "unknown package"
                installed = (
                    vulnerability.get("InstalledVersion") or "unknown version"
                )
                vulnerability_id = (
                    vulnerability.get("VulnerabilityID") or "unknown id"
                )
                lines.append(
                    f"    - `{vulnerability_id}` in `{package}` {installed} -> {fixed}"
                )
    else:
        lines.append("- Application dependencies found in the image: none")

    output = "\n".join(lines)
    print(output)

    step_summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if step_summary:
        with open(step_summary, "a", encoding="utf-8") as handle:
            handle.write(output + "\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
