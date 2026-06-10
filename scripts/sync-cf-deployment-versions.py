#!/usr/bin/env python3

import argparse
import os
from ruamel.yaml import YAML
import yaml
import sys
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
                

def latest_cf_deployment_release() -> str:
    headers = {"Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}"}
    response = requests.get("https://api.github.com/repos/cloudfoundry/cf-deployment/releases/latest", headers=headers)
    response.raise_for_status()
    latest_version = response.json()["tag_name"]
    print(f"Latest cf-deployment release: {latest_version}")
    return latest_version


def cf_deployment_manifest(ref: str = None) -> dict:
    if not ref:
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

    values_file = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "versions.yaml")
 
    yaml = YAML()
    yaml.preserve_quotes = True
    with open(values_file, "r") as f:
        values = yaml.load(f)
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
                print(f"error in release update of '{r['name']}': no value found", file=sys.stderr)
                sys.exit(1)

        values["charts"][yaml_key]["version"] = str(r["version"])
        print(f"Updated release '{r['name']}' to version {r['version']}")

    with open(values_file, "w") as f:
        yaml.dump(values, f)

if __name__ == "__main__":
    main()
