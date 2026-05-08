#!/usr/bin/env python3

import base64
import json
import logging
import os
import subprocess
import sys
from typing import List

import requests


def get_bake_config(release: str) -> dict:
    result = subprocess.run(["docker", "buildx", "bake", "--print", release], capture_output=True, text=True, check=True)

    return json.loads(result.stdout)


def is_image_available(tag: str) -> bool:
    image, tag = tag.split(":")
    token = base64.b64encode(os.environ.get("GITHUB_TOKEN", "").encode()).decode()
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"https://ghcr.io/v2/{image}/tags/list", headers=headers)
    response.raise_for_status()

    return tag in response.json().get("tags", [])


def get_latest_releases(release_name: str) -> List[str]:
    headers = {"Authorization": f"Bearer {os.environ.get('GITHUB_TOKEN')}"}
    response = requests.get(f"https://api.github.com/repos/cloudfoundry/{release_name}/releases", headers=headers)
    response.raise_for_status()

    return [tag.get("name") for tag in response.json()][:5]


def main():
    if len(sys.argv) < 2:
        sys.exit("Usage: latest-images.py [release-name]")

    release_name = sys.argv[1]
    full_release_name = f"{release_name}-release"
    release_var = f"{release_name.upper()}_RELEASE_VERSION"

    bake_config = get_bake_config(release_name)
    targets = bake_config.get("target", {}).keys()

    for version in get_latest_releases(full_release_name):
        build_image = False
        for target in targets:
            tag = f"cloudfoundry/k8s/{target}:{version}"
            if not is_image_available(tag):
                logging.debug(f"Image {tag} not found, will trigger build for {release_name} release {version}")
                build_image = True
                break
        if build_image:
            subprocess.run(
                [
                    "docker",
                    "buildx",
                    "bake",
                    "--var",
                    f"{release_var}={version}",
                    "--set",
                    "*.output=type=image,push-by-digest=true,name-canonical=true,push=false",  # set push=true later
                    "--set",
                    f"*.platform={os.environ.get('PLATFORM', 'linux/amd64,linux/arm64')}",
                    "--metadata-file",
                    f"{os.environ.get('METADATA_PATH', 'metadata.json')}",
                    release_name,
                ],
                stdout=sys.stdout,
                stderr=sys.stderr,
                check=True,
            )


if __name__ == "__main__":
    main()
