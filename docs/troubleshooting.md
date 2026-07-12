# Troubleshooting

## Codespaces: Feature Could Not Be Processed

If GitHub Codespaces fails during container creation with an error like:

```text
ERR: Feature 'ghcr.io/devcontainers/features/…' could not be processed.
You may not have permission to access this Feature, or may not be logged in.
```

the CLI failed while resolving a Feature from GHCR. That message is generic: the Feature may be public, and the real problem is often registry reachability from the Codespaces host, not private package access.

This lab is set up to avoid GHCR Feature pulls:

- Python comes from `mcr.microsoft.com/devcontainers/python:1-3.12`
- Docker-in-Docker is a **local** Feature under `.devcontainer/features/docker-in-docker` (vendored from the official Microsoft Feature)
- Ansible is installed in `postCreateCommand` via pipx

If create still fails:

1. Confirm the Codespace branch includes those files (not an older commit that still references `ghcr.io/devcontainers/features/...`).
2. Delete the failed Codespace and create a new one after the branch is up to date.
3. Recovery containers (base alpine with no lab tooling) mean the real devcontainer never started; rebuild after the fix is on the branch.

## Docker Is Not Running

Run:

```bash
docker version
```

Docker should show both a client and server.

## Compose Is Missing

Run:

```bash
docker compose version
```

Install Docker Desktop or the Docker Compose plugin if the command is missing.

## Ansible Cannot Reach Hosts

Check the containers:

```bash
./lab status
```

Then reset the lab:

```bash
./lab reset
./lab ping
```

## SSH Key Problems

The lab creates a dedicated SSH key under `.lab/ssh`. If the key is missing or corrupt, recreate it:

```bash
rm -rf .lab
./lab up
./lab ping
```

On Windows without WSL, remove the `.lab` folder and run:

```powershell
.\lab.ps1 up
.\lab.ps1 ping
```
