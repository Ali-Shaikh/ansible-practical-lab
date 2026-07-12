# Vendored Dev Container Features

## `docker-in-docker`

Local copy of the official Feature
[ghcr.io/devcontainers/features/docker-in-docker:2.17.0](https://github.com/devcontainers/features/tree/main/src/docker-in-docker)
so Codespaces does not need to resolve Features from GHCR at create time.

Source licence: MIT (Microsoft Corporation), see headers in `install.sh`.

To refresh from upstream, pull the OCI layer for tag `2` / version `2.17.0` from
`ghcr.io/devcontainers/features/docker-in-docker` and replace the files in
`docker-in-docker/`.
