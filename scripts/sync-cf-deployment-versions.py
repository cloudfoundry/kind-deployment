#!/usr/bin/env python3
import os
import yaml
import sys
import re


def update_chart_yaml(chart_yaml_path, version):
    with open(chart_yaml_path) as f:
        content = f.read()
    updated = re.sub(r"^(appVersion:\s*).*$", rf"\g<1>{version}", content, flags=re.MULTILINE)
    with open(chart_yaml_path, "w") as f:
        f.write(updated)
    print(f"Setting appVersion in {chart_yaml_path} to {version}")


def update_values_yaml(values_path, release_versions):
    with open(values_path) as f:
        content = f.read()
    updated = re.sub(
        r"(#\s*sync:\s*release=([\w-]+))\n(\s*)(tag:\s*)([\"']?).*?\5",
        lambda m: replace_tag(release_versions, m),
        content
    )
    with open(values_path, "w") as f:
        f.write(updated)
    print(f"Updated tags in {values_path}")


def replace_tag(release_versions, m):
    release_name = m.group(2)
    indent = m.group(3)
    quote = m.group(5)
    version = release_versions.get(release_name)
    if version is None:
        return m.group(0)
    return f"# sync: release={release_name}\n{indent}tag: {quote}{version}{quote}"


def main():
    if len(sys.argv) != 2:
        print("Usage: sync-cf-deployment-versions.py <cf-deployment.yml>", file=sys.stderr)
        sys.exit(1)

    input_path = sys.argv[1]

    with open(input_path) as f:
        manifest = yaml.safe_load(f)

    releases = manifest.get("releases", [])
    if not releases:
        print("No releases found in cf-deployment manifest", file=sys.stderr)
        sys.exit(1)
        

 
    releases_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "releases")
    release_versions = {r["name"]: str(r["version"]) for r in releases}
    
    manifest_version = manifest.get("manifest_version")
    if not manifest_version:
        print("No manifest_version found in cf-deployment manifest", file=sys.stderr)
        sys.exit(1)
    else:
        manifest_version = str(manifest_version).lstrip("v")
        release_versions["cf-deployment"] = manifest_version

    for r in releases:
        helm_dir = os.path.join(releases_dir, r["name"], "helm")
        chart_yaml_path = os.path.join(helm_dir, "Chart.yaml")
        values_path = os.path.join(helm_dir, "values.yaml")
        
        if not os.path.exists(chart_yaml_path):
            print(f"Skipping chart update of '{r['name']}' no chart found at {chart_yaml_path}", file=sys.stderr)
            continue

        update_chart_yaml(chart_yaml_path, str(r["version"]))

        if not os.path.exists(values_path):
            print(f"Skipping values update of '{r['name']}' no values found at {values_path}", file=sys.stderr)
            continue

        update_values_yaml(values_path, release_versions)


if __name__ == "__main__":
    main()
