ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

ARG HOST_USER=learner
ARG HOST_PASSWORD=learner

ENV DEBIAN_FRONTEND=noninteractive
ENV HOST_USER=${HOST_USER}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       dbus \
       iproute2 \
       less \
       openssh-server \
       python3 \
       python3-apt \
       sudo \
       systemd \
       systemd-sysv \
       vim-tiny \
    && rm -rf /var/lib/apt/lists/*

# systemd mode (LAB_INIT=systemd): run sshd as a classic unit rather than
# socket activation, and mask units that make no sense in a container.
RUN systemctl disable ssh.socket 2>/dev/null || true \
    && systemctl enable ssh.service \
    && systemctl mask \
       systemd-udevd.service \
       systemd-udevd-control.socket \
       systemd-udevd-kernel.socket \
       systemd-modules-load.service \
       systemd-logind.service \
       systemd-networkd.service \
       systemd-resolved.service \
       getty.target \
       console-getty.service

RUN useradd --create-home --shell /bin/bash "${HOST_USER}" \
    && echo "${HOST_USER}:${HOST_PASSWORD}" | chpasswd \
    && usermod --append --groups sudo "${HOST_USER}" \
    && printf '%s ALL=(ALL) NOPASSWD:ALL\n' "${HOST_USER}" > /etc/sudoers.d/90-lab-user \
    && chmod 0440 /etc/sudoers.d/90-lab-user \
    && mkdir -p /var/run/sshd \
    && install --directory --owner="${HOST_USER}" --group="${HOST_USER}" --mode=0700 "/home/${HOST_USER}/.ssh" \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22

# systemd shuts down cleanly on SIGRTMIN+3; sshd exits on it too, so the
# signal is safe for both init modes.
STOPSIGNAL SIGRTMIN+3

CMD ["/usr/local/bin/entrypoint.sh"]
