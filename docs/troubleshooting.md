# Troubleshooting

## Codespaces: Feature Could Not Be Processed

If GitHub Codespaces fails during container creation with an error like:

```text
ERR: Feature 'ghcr.io/devcontainers/features/python:1' could not be processed.
You may not have permission to access this Feature, or may not be logged in.
```

the CLI failed while resolving a Feature from GHCR (often a transient registry/auth problem, not a private package). This lab avoids the Python Feature and uses the pre-built image `mcr.microsoft.com/devcontainers/python:1-3.12` instead; Ansible is installed in `postCreateCommand`.

If you still hit a Feature resolve error (for example on `docker-in-docker`):

1. Delete the failed Codespace and create a new one (retry often succeeds).
2. Ensure you are opening the branch that contains the current `.devcontainer/devcontainer.json`.
3. As a last resort, temporarily remove `.devcontainer/devcontainer-lock.json` so Features resolve without pin, then rebuild.

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
