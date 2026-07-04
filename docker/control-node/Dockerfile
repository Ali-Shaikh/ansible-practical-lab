ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

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
