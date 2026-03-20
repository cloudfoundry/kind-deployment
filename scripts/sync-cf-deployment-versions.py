#!/usr/bin/env python3

import subprocess
import base64
import json
import os
import yaml
import sys
import re
import requests


def get_bake_config(release: str) -> dict:
    result = subprocess.run(["docker", "buildx", "bake", "--print", release], capture_output=True, text=True, check=True)
    return json.loads(result.stdout)


def get_tags_by_release(release: str) -> list:
    config = get_bake_config(release)
    all_tags = []
    for target in config.get("target", {}).values():
        all_tags.extend([f"cloudfoundry/k8s/{tag}" for tag in target.get("tags", []) if "latest" not in tag])

    return all_tags


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
    updated = re.sub(r"(#\s*sync:\s*release=([\w-]+))\n(\s*)(tag:\s*)([\"']?).*?\5", lambda m: replace_tag(release_versions, m), content)
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


def latest_cf_deployment_release() -> str:
    headers = {"Authorization": f"Bearer {os.environ.get('GITHUB_TOKEN')}"}
    response = requests.get("https://api.github.com/repos/cloudfoundry/cf-deployment/releases/latest", headers=headers)
    response.raise_for_status()
    latest_version = response.json()["tag_name"]
    print(f"Latest cf-deployment release: {latest_version}")
    return latest_version


def cf_deployment_manifest() -> dict:
    version = latest_cf_deployment_release()
    headers = {"Authorization": f"Bearer {os.environ.get('GITHUB_TOKEN')}"}
    response = requests.get(f"https://raw.githubusercontent.com/cloudfoundry/cf-deployment/refs/tags/{version}/cf-deployment.yml", headers=headers)
    response.raise_for_status()
    return yaml.safe_load(response.text.encode("utf-8"))


def is_image_available(tag) -> bool:
    image, tag = tag.split(":")

    token = base64.b64encode(os.environ.get("GITHUB_TOKEN").encode()).decode()
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"https://ghcr.io/v2/{image}/tags/list", headers=headers)

    response.raise_for_status()
    return tag in response.json().get("tags", [])


def main():
    manifest = cf_deployment_manifest()

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

    missing_images = []

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

        for tag in get_tags_by_release(r["name"]):
            if not is_image_available(tag):
                missing_images.append(tag)

    if missing_images:
        print(f"The following images are missing: \n{', \n'.join(missing_images)}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
