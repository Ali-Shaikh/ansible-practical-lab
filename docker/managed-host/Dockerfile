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
       iproute2 \
       less \
       openssh-server \
       python3 \
       python3-apt \
       sudo \
       vim-tiny \
    && rm -rf /var/lib/apt/lists/*

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

CMD ["/usr/local/bin/entrypoint.sh"]
