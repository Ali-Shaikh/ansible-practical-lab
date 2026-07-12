# Reference Versions And Version Policy

These are the default versions and version rules for this lab.

- Default Ubuntu image: `ubuntu:24.04`
- Ansible install method in the control-node image: `pipx install --include-deps ansible`
- Docker Compose command style: `docker compose`
- Compose file name used by this repo: `docker-compose.yml`
- Lab SSH key type: Ed25519

## Ubuntu Version

The lab defaults to Ubuntu 24.04 LTS. It is a supported LTS release and provides Python 3.12, which is required by current Ansible community package releases.

The repo exposes `UBUNTU_VERSION` as a build argument so the lab can use a different Ubuntu image without rewriting Dockerfiles:

```bash
UBUNTU_VERSION=26.04 docker compose build --no-cache
```

After changing the base image, rebuild the full lab and run `doctor`, `up`, `ping`, `facts` and the starter playbooks.

## Ansible Package

The control-node image installs the current released `ansible` package using the official Ansible `pipx` method.

The control node is built as an on-demand container. It is not kept running after `up`; commands such as `ping`, `facts` and `play` start a short-lived `forge` container.

## SSH Access Policy

Managed hosts use SSH keys by default. The wrapper creates a lab-specific Ed25519 key pair under `.lab/ssh`, mounts the public key into each managed host, and points Ansible at the private key.

On Windows, bind-mounted files can appear too permissive inside Linux containers. The control-node entrypoint copies the private key to `/tmp/lab-ssh/id_ed25519` with `0600` permissions before running Ansible, and copies the matching public key to `/tmp/lab-ssh/id_ed25519.pub` for playbooks that install authorized keys from the lab key.

The lab images still set a `learner` password for the local Linux account, but normal Ansible commands use the private key.

To pin a specific Ansible package version, set `ANSIBLE_PACKAGE` before building:

```bash
ANSIBLE_PACKAGE=ansible==14.1.0 docker compose build --no-cache forge
```

## Official References

- Ansible installation guide: https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html
- Ansible release and maintenance: https://docs.ansible.com/projects/ansible/latest/reference_appendices/release_and_maintenance.html
- Ansible package on PyPI: https://pypi.org/project/ansible/
- Docker Compose application model: https://docs.docker.com/compose/intro/compose-application-model/
- Docker Engine on Ubuntu: https://docs.docker.com/engine/install/ubuntu/
