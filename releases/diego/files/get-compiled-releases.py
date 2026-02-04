import yaml
import requests
import sys
import tarfile
import os
import re


def get_compiled_releases(cf_deployment_version):
    """Fetch and return compiled releases from cf-deployment."""
    FILE_URL = f"https://raw.githubusercontent.com/cloudfoundry/cf-deployment/refs/tags/v{cf_deployment_version}/operations/use-compiled-releases.yml"

    response = requests.get(FILE_URL)
    response.raise_for_status()

    return yaml.safe_load(response.text)


def process_releases(compiled_releases):
    """Process releases and print buildpack URLs."""
    os.makedirs("/tmp/final/cf-assets", exist_ok=True)

    for release in compiled_releases:
        if "diego" in release["path"]:
            print(f"Downloading {release["value"]["url"]}")
            diego_response = requests.get(release["value"]["url"])
            diego_response.raise_for_status()
            with open("/tmp/diego.tgz", "wb") as f:
                f.write(diego_response.content)
            with tarfile.open("/tmp/diego.tgz", "r:gz") as tar:
                tar.extractall("/tmp")
            extract_lifecycle("buildpack_app_lifecycle")
            extract_lifecycle("cnb_app_lifecycle")
            extract_lifecycle("docker_app_lifecycle")

            os.rename("/tmp/compiled_packages/healthcheck.tgz", "/tmp/final/cf-assets/healthcheck.tgz")
            os.rename("/tmp/compiled_packages/proxy.tgz", "/tmp/final/cf-assets/proxy.tgz")


        if "buildpack" in release["path"]:
            extract_buildpack(release["value"]["name"], release["value"]["url"])
        
        if "garden-runc" in release["path"]:
            extract_init(release["value"]["url"])

    for filename in os.listdir("/tmp/final"):
        # Match pattern: name-cflinuxfs4-v<semver>.zip
        match = re.match(r"^(.+-cflinuxfs4)-v\d+\.\d+\.\d+(\.zip)$", filename)
        if match:
            new_filename = match.group(1) + match.group(2)
            old_path = os.path.join("/tmp/final", filename)
            new_path = os.path.join("/tmp/final", new_filename)
            os.rename(old_path, new_path)
            print(f"Renamed {filename} to {new_filename}")


def extract_lifecycle(name):
    print(f"Processing lifecycle {name}")

    os.makedirs(f"/tmp/final/v1/static/{name}", exist_ok=True)
    with tarfile.open(f"/tmp/compiled_packages/{name}.tgz", "r:gz") as tar:
        tar.extractall(f"/tmp/final/v1/static/{name}")


def extract_buildpack(name, url):
    print(f"Processing buildpack {name} ({url})")

    response = requests.get(url)
    response.raise_for_status()
    file_name = f"/tmp/{name}.tgz"
    with open(file_name, "wb") as f:
        f.write(response.content)
    with tarfile.open(file_name, "r:gz") as tar:
        tar.extract(f"./compiled_packages/{name}-cflinuxfs4.tgz", "/tmp")
        with tarfile.open(f"/tmp/compiled_packages/{name}-cflinuxfs4.tgz", "r:gz") as buildpack_tar:
            buildpack_tar.extractall(f"/tmp/final")


def extract_init(url):
    print(f"Processing garden-runc init ({url})")

    response = requests.get(url)
    response.raise_for_status()
    file_name = "/tmp/garden-runc.tgz"
    with open(file_name, "wb") as f:
        f.write(response.content)

    with tarfile.open(file_name, "r:gz") as tar:
        tar.extract("./compiled_packages/guardian.tgz", "/tmp")

    with tarfile.open("/tmp/compiled_packages/guardian.tgz", "r:gz") as guardian_tar:
        guardian_tar.extract("./bin/init", "/tmp")

    with tarfile.open("/tmp/final/cf-assets/init.tgz", "x:gz") as init_tar:
        init_tar.add("/tmp/bin/init", arcname="init")


if __name__ == "__main__":
    CF_DEPLOYMENT_VERSION = sys.argv[1]
    print(f"Fetching compiled releases for cf-deployment version: {CF_DEPLOYMENT_VERSION}")
    compiled_releases = get_compiled_releases(CF_DEPLOYMENT_VERSION)
    process_releases(compiled_releases)
