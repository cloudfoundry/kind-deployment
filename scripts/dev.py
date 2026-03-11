import subprocess
import json
import sys
import questionary

from ruamel.yaml import YAML

from pathlib import Path


def get_bake_config() -> dict:
    result = subprocess.run(["docker", "buildx", "bake", "--print"], capture_output=True, text=True, check=True)
    return json.loads(result.stdout)


def find_matches(values: dict, image_name: str) -> list:
    image_key_paths = []
    for component, component_values in values.items():
        if isinstance(component_values, dict):
            repo = component_values.get("image", {}).get("repository", "")
            if repo.endswith(image_name):
                image_key_paths.append(component)
    return image_key_paths


def check_cluster():
    temp_path = Path("temp")
    if not temp_path.exists():
        print("Before running this script, please run `make up` to create the cluster.")
        sys.exit(1)


def build_instructions(project):
    tags = bake_config.get("target", {}).get(project, {}).get("tags", [])
    latest_tag = next((tag for tag in tags if tag.endswith(":latest")), None)
    if not latest_tag and len(tags) < 2:
        raise ValueError(f"No tag ending with ':latest' found for project {project}")
    image_name = latest_tag.split(":")[0]

    update_values(image_name)

    print(f"docker buildx bake {project} --set {project}.contexts.src=<path-to-{release}-release>/src")
    print(f"kind load docker-image {latest_tag} --name cfk8s")


def update_values(image_name):
    yaml = YAML()
    yaml.preserve_quotes = True
    yaml.representer.add_representer(type(None), lambda dumper, _: dumper.represent_scalar("tag:yaml.org,2002:null", "~"))

    values_path = Path(f"releases/{release}/helm/values.yaml")

    with open(values_path, "r") as f:
        values = yaml.load(f)

    for match in find_matches(values, image_name):
        keys = match.split(".")
        target = values
        for key in keys:
            target = target[key]

        target["image"]["repository"] = image_name
        target["image"]["tag"] = "latest"

    with open(values_path, "w") as f:
        yaml.dump(values, f)


if __name__ == "__main__":
    check_cluster()

    bake_config = get_bake_config()
    all_releases = bake_config.get("group", {}).get("all", {}).get("targets", [])

    all_releases.remove("cflinuxfs4")
    all_releases.remove("fileserver")
    all_releases.remove("bosh-dns")

    release = questionary.select("Which release are you working on?", choices=all_releases).ask()

    all_projects = bake_config.get("group", {}).get(release, {}).get("targets", [])

    # single project releases are not included in the targets group
    if not all_projects:
        all_projects.append(release)

    default_choices = [questionary.Choice(title=project, checked=True) for project in all_projects]
    projects = questionary.checkbox("Which project(s) are you working on?", choices=default_choices).ask()

    print("Here are some instructions to build a local image and load it into the cluster. Make sure to replace <path-to-release> with the actual path to the release you are working on.")
    print("Docker will ask for confirmation to access the local file system, please allow it to do so.")
    print()
    for project in projects:
        build_instructions(project)
    print("make up")
