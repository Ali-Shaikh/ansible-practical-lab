# Troubleshooting

## Codespaces container create fails

### Symptom A: Feature could not be processed (GHCR)

```text
ERR: Feature 'ghcr.io/devcontainers/features/…' could not be processed.
You may not have permission to access this Feature, or may not be logged in.
```

This lab **does not use Dev Container Features**. If you still see this, the Codespace is on an **old commit**. Open branch `feature/lab-repair-from-bootstrap` (or main after it lands) and recreate the Codespace.

### Symptom B: docker buildx exit code 100 during Feature install

```text
./devcontainer-features-install.sh … exit code: 100
```

Root cause (confirmed in similar public reports and Microsoft image issues):

1. Feature install runs `apt-get update` inside the base image.
2. `mcr.microsoft.com/devcontainers/python` ships a **Yarn apt source** whose GPG key is expired/missing.
3. `apt-get update` fails → exit **100** (same for docker-in-docker Feature install).

References: [devcontainers/images#1752](https://github.com/devcontainers/images/issues/1752), same exit-100 pattern on python + dind in Codespaces.

**This lab's fix:** `.devcontainer/Dockerfile` uses clean `mcr.microsoft.com/devcontainers/base:ubuntu-24.04`, installs Docker CE from docker.com and Python from Ubuntu apt. No Features, no Yarn apt repo.

If create still fails, confirm the branch has `.devcontainer/Dockerfile` and `devcontainer.json` with `"build": { "dockerfile": "Dockerfile" }` (not `image` + `features`).

### Recovery alpine container

If Codespaces drops you into a recovery alpine image, the real build failed. Delete the Codespace and recreate after the Dockerfile-based config is on the branch.

## Docker Is Not Running

Run:

```bash
docker version
```

Docker should show both a client and server.

Inside a Codespace, if the client works but the server does not, check `/tmp/dockerd.log` (DinD entrypoint log).

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
