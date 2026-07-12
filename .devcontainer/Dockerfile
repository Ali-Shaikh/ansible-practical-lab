# Codespaces / Dev Containers workspace image for the Ansible lab.
#
# Root cause we avoid:
# 1) GHCR Feature resolve often fails in Codespaces with a generic
#    "permission / not logged in" error.
# 2) Installing Features on mcr.microsoft.com/devcontainers/python runs
#    apt-get update, which exits 100 because that image ships a broken
#    Yarn apt source (expired / missing GPG key). Same exit code 100 seen
#    in Codespaces build logs for docker-in-docker.
#
# So: clean Ubuntu base, install Docker CE from docker.com, no Features.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        python3 \
        python3-pip \
        python3-venv \
        pipx \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && . /etc/os-release \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -f docker \
    && usermod -aG docker vscode

COPY docker-init.sh /usr/local/share/docker-init.sh
RUN chmod +x /usr/local/share/docker-init.sh

USER vscode
ENV PATH="/home/vscode/.local/bin:${PATH}" \
    DOCKER_BUILDKIT="1" \
    PIPX_HOME="/home/vscode/.local/pipx" \
    PIPX_BIN_DIR="/home/vscode/.local/bin"

ENTRYPOINT ["/usr/local/share/docker-init.sh"]
CMD ["sleep", "infinity"]
