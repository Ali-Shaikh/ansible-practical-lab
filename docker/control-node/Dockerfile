ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION} AS control-node

ENV DEBIAN_FRONTEND=noninteractive
ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin
ARG ANSIBLE_PACKAGE=ansible

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       git \
       openssh-client \
       pipx \
       python3 \
       python3-pip \
       sshpass \
    && rm -rf /var/lib/apt/lists/*

RUN pipx install --include-deps "${ANSIBLE_PACKAGE}" \
    && pipx install ansible-lint

# Install the Galaxy collections declared for the lab so playbooks that use
# them work out of the box. requirements.yml is the single source of truth.
COPY requirements.yml /tmp/requirements.yml
RUN ansible-galaxy collection install -r /tmp/requirements.yml

WORKDIR /workspace

COPY docker/control-node/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]

# Studio: the control node plus code-server, giving a browser-based VS Code
# with an integrated terminal where ansible commands run directly against
# the lab hosts. Optional; only built for the `studio` compose profile.
FROM control-node AS studio

ARG CODE_SERVER_VERSION=4.127.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://code-server.dev/install.sh \
       | sh -s -- --version "${CODE_SERVER_VERSION}" \
    && code-server --install-extension redhat.ansible

EXPOSE 8443

CMD ["code-server", "--bind-addr", "0.0.0.0:8443", "--auth", "none", "--disable-telemetry", "/workspace"]
