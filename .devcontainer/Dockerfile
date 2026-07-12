# Codespaces / Dev Containers workspace image for the Ansible lab.
#
# Avoids Dev Container Features (GHCR resolve failures + python-image Yarn GPG
# breaking apt with exit 100). Clean Ubuntu base + Docker CE + DinD entrypoint.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        iptables \
        pigz \
        python3 \
        python3-pip \
        python3-venv \
        pipx \
        uidmap \
        xz-utils \
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
    && usermod -aG docker vscode \
    && mkdir -p /usr/local/share \
    && echo 'export PATH="/home/vscode/.local/bin:$PATH"' > /etc/profile.d/vscode-local-bin.sh

COPY docker-init.sh /usr/local/share/docker-init.sh
RUN chmod +x /usr/local/share/docker-init.sh

# Keep root as image user so ENTRYPOINT can start dockerd.
# Codespaces/VS Code connect as vscode via remoteUser in devcontainer.json.
ENV DOCKER_BUILDKIT="1" \
    PIPX_HOME="/home/vscode/.local/pipx" \
    PIPX_BIN_DIR="/home/vscode/.local/bin" \
    PATH="/home/vscode/.local/bin:${PATH}"

ENTRYPOINT ["/usr/local/share/docker-init.sh"]
CMD ["sleep", "infinity"]
