#!/usr/bin/env python3

import argparse
import os
from ruamel.yaml import YAML
import yaml
import sys
import requests
import semver

BOSH_RELEASES = {
    "capi": "capi",
    "cf-networking": "cfNetworking",
    "credhub": "credhub",
    "diego": "diego",
    "log-cache": "logCache",
    "loggregator": "loggregator",
    "loggregator-agent": "loggregatorAgent",
    "routing": "routing",
    "uaa": "uaa",
    "nfs-volume": "nfsVolume",
    "cflinuxfs4": "cflinuxfs4",
}

BUILDPACKS = [
    "java-buildpack",
    "nodejs-buildpack",
    "go-buildpack",
    "binary-buildpack",
    "dotnet-core-buildpack",
    "nginx-buildpack",
    "php-buildpack",
    "python-buildpack",
    "r-buildpack",
    "ruby-buildpack",
    "staticfile-buildpack",
]

STACKS = [
    "cflinuxfs4",
]

MANAGED_RELEASES = set(BOSH_RELEASES.keys()) | set(BUILDPACKS) | set(STACKS)


def parse_semver(version: str):
    normalized = version.lstrip("v")
    try:
        return semver.VersionInfo.parse(normalized)
    except ValueError:
        return None


def should_apply_version_update(current_version: str, new_version: str, release_name: str, target_type: str) -> bool:
    current_semver = parse_semver(current_version)
    new_semver = parse_semver(new_version)

    if not current_semver or not new_semver:
        return True

    if new_semver < current_semver:
        print(
            f"Skipping {target_type} '{release_name}' downgrade: current={current_version}, new={new_version}",
            file=sys.stderr,
        )
        return False
    elif new_semver == current_semver:
        print(
            f"Skipping {target_type} '{release_name}' version={current_version} unchanged",
            file=sys.stderr,
        )
        return False

    return True


def latest_cf_deployment_release() -> str:
    headers = {"Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}"}
    response = requests.get(
        "https://api.github.com/repos/cloudfoundry/cf-deployment/releases/latest",
        headers=headers,
    )
    response.raise_for_status()
    latest_version = response.json()["tag_name"]
    print(f"Latest cf-deployment release: {latest_version}")
    return latest_version


def cf_deployment_manifest(ref: str = None) -> dict:
    headers = {"Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}"}
    response = requests.get(
        f"https://raw.githubusercontent.com/cloudfoundry/cf-deployment/{ref}/cf-deployment.yml",
        headers=headers,
    )
    response.raise_for_status()
    return yaml.safe_load(response.text.encode("utf-8"))


def nfs_release_version(ref: str = None) -> dict:
    headers = {"Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}"}
    response = requests.get(
        f"https://raw.githubusercontent.com/cloudfoundry/cf-deployment/{ref}/operations/enable-nfs-volume-service.yml",
        headers=headers,
    )
    response.raise_for_status()
    for op in yaml.safe_load(response.text.encode("utf-8")):
        if op.get("type") == "replace" and op.get("path") == "/releases/-":
            nfs_version = str(op["value"]["version"])
            print(f"Found nfs-volume release version: {nfs_version}")

            return {
                "name": "nfs-volume",
                "version": nfs_version,
            }

    return {}


def main():
    parser = argparse.ArgumentParser(description="Sync cf-deployment release versions into values.yaml.gotmpl")
    parser.add_argument(
        "--ref",
        default=None,
        help="Git ref (branch, tag, or SHA) to download cf-deployment.yml from. Defaults to the latest release tag.",
    )
    args = parser.parse_args()

    if not args.ref:
        args.ref = f"refs/tags/{latest_cf_deployment_release()}"
    else:
        print(f"Using cf-deployment ref: {args.ref}")

    manifest = cf_deployment_manifest(ref=args.ref)

    releases = manifest.get("releases", [])
    releases.append(nfs_release_version(ref=args.ref))
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
        if r["name"] not in MANAGED_RELEASES:
            print(
                f"Skipping release update of '{r['name']}': not a managed release",
                file=sys.stderr,
            )
            continue
        yaml_key = BOSH_RELEASES.get(r["name"], "unknown")
        if yaml_key in values.get("charts", {}):
            current_version = str(values["charts"][yaml_key]["version"])
            new_version = str(r["version"])
            if should_apply_version_update(current_version, new_version, r["name"], "release"):
                values["charts"][yaml_key]["version"] = new_version
                print(f"Updated release '{r['name']}' from version {current_version} to version {new_version}")
        elif r["name"] in BUILDPACKS and r["name"] in values.get("buildpacks", {}):
            current_version = str(values["buildpacks"][r["name"]]["tag"])
            new_version = str(r["version"])
            if should_apply_version_update(current_version, new_version, r["name"], "buildpack"):
                values["buildpacks"][r["name"]]["tag"] = new_version
                print(f"Updated buildpack '{r['name']}' to version {new_version}")
        elif r["name"] in STACKS and r["name"] in values.get("stacks", {}):
            current_version = str(values["stacks"][r["name"]]["tag"])
            new_version = str(r["version"])
            if should_apply_version_update(current_version, new_version, r["name"], "stack"):
                values["stacks"][r["name"]]["tag"] = new_version
                print(f"Updated stack '{r['name']}' to version {new_version}")
        else:
            print(
                f"error in release update of '{r['name']}': no value found",
                file=sys.stderr,
            )
            sys.exit(1)

    with open(values_file, "w") as f:
        yaml.dump(values, f)


if __name__ == "__main__":
    main()
