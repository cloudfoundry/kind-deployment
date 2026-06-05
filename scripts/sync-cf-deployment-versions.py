#!/usr/bin/env python3

import argparse
import os
import yaml
import sys
import re
import requests

BOSH_RELEASES = { "capi": "capi",
                  "cf-networking": "cfNetworking",
                  "credhub": "credhub",
                  "diego": "diego",
                  "log-cache": "logCache",
                  "loggregator": "loggregator",
                  "loggregator-agent": "loggregatorAgent",
                  "routing": "routing",
                  "uaa": "uaa",
                }
                

def load_yaml_from_gotmpl(file_path: str) -> dict:
    with open(file_path) as f:
        content = f.read()

    # Replace Go template expressions so the remaining content is valid YAML.
    sanitized = re.sub(r"\{\{.*?\}\}", '"__GOTMPL__"', content, flags=re.DOTALL)
    return yaml.safe_load(sanitized) or {}


def update_gotmpl_with_versions(file_path: str, values: dict) -> None:
    chart_versions = {}
    for name, cfg in values.get("charts", {}).items():
        if isinstance(cfg, dict) and "version" in cfg:
            chart_versions[name] = str(cfg["version"])

    with open(file_path) as f:
        lines = f.readlines()

    in_charts = False
    current_chart = None

    for i, line in enumerate(lines):
        if re.match(r"^charts:\s*$", line):
            in_charts = True
            current_chart = None
            continue

        if in_charts and re.match(r"^[A-Za-z_][A-Za-z0-9_]*:\s*$", line):
            in_charts = False
            current_chart = None

        if not in_charts:
            continue

        chart_match = re.match(r"^  ([A-Za-z0-9][A-Za-z0-9_-]*):\s*$", line)
        if chart_match:
            current_chart = chart_match.group(1)
            continue

        if current_chart not in chart_versions:
            continue

        version_match = re.match(r"^(\s*version:\s*)([\"']?)([^\"'#\s\n]+)([\"']?)(.*)$", line)
        if not version_match:
            continue

        prefix = version_match.group(1)
        quote = version_match.group(2) if version_match.group(2) else '"'
        suffix = version_match.group(5)
        # Preserve the original line's newline character if present
        has_newline = line.endswith("\n")
        lines[i] = f"{prefix}{quote}{chart_versions[current_chart]}{quote}{suffix}"
        if has_newline:
            lines[i] += "\n"

    with open(file_path, "w") as f:
        f.writelines(lines)


def latest_cf_deployment_release() -> str:
    headers = {"Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}"}
    response = requests.get("https://api.github.com/repos/cloudfoundry/cf-deployment/releases/latest", headers=headers)
    response.raise_for_status()
    latest_version = response.json()["tag_name"]
    print(f"Latest cf-deployment release: {latest_version}")
    return latest_version


def cf_deployment_manifest(ref: str = None) -> dict:
    if ref is None:
        ref = f"refs/tags/{latest_cf_deployment_release()}"
    else:
        print(f"Using cf-deployment ref: {ref}")
    headers = {"Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}"}
    response = requests.get(f"https://raw.githubusercontent.com/cloudfoundry/cf-deployment/{ref}/cf-deployment.yml", headers=headers)
    response.raise_for_status()
    return yaml.safe_load(response.text.encode("utf-8"))


def main():
    parser = argparse.ArgumentParser(description="Sync cf-deployment release versions into values.yaml.gotmpl")
    parser.add_argument("--ref", default=None, help="Git ref (branch, tag, or SHA) to download cf-deployment.yml from. Defaults to the latest release tag.")
    args = parser.parse_args()

    manifest = cf_deployment_manifest(ref=args.ref)

    releases = manifest.get("releases", [])
    if not releases:
        print("No releases found in cf-deployment manifest", file=sys.stderr)
        sys.exit(1)

    values_file = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "values.yaml.gotmpl")
    values = load_yaml_from_gotmpl(values_file)
    release_versions = {r["name"]: str(r["version"]) for r in releases}

    manifest_version = manifest.get("manifest_version")
    if not manifest_version:
        print("No manifest_version found in cf-deployment manifest", file=sys.stderr)
        sys.exit(1)
    else:
        manifest_version = str(manifest_version).lstrip("v")
        release_versions["cf-deployment"] = manifest_version

    for r in releases:
        if r["name"] not in BOSH_RELEASES:
                print(f"Skipping release update of '{r['name']}': not a managed release", file=sys.stderr)
                continue
        yaml_key = BOSH_RELEASES[r["name"]]
        if yaml_key not in values.get("charts", {}):
                print(f"Skipping release update of '{r['name']}': no value found", file=sys.stderr)
                continue

        values["charts"][yaml_key]["version"] = str(r["version"])
        print(f"Updated release '{r['name']}' to version {r['version']}")

    update_gotmpl_with_versions(values_file, values)

if __name__ == "__main__":
    main()
