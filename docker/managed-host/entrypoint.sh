#!/usr/bin/env bash
set -euo pipefail

ssh-keygen -A

# /run is a tmpfs in systemd mode, so the privilege-separation directory
# from the image build does not survive to runtime.
mkdir -p /run/sshd

if [[ -f /lab-ssh/authorized_keys ]]; then
  install --directory --owner="${HOST_USER:-learner}" --group="${HOST_USER:-learner}" --mode=0700 "/home/${HOST_USER:-learner}/.ssh"
  cp /lab-ssh/authorized_keys "/home/${HOST_USER:-learner}/.ssh/authorized_keys"
  chown "${HOST_USER:-learner}:${HOST_USER:-learner}" "/home/${HOST_USER:-learner}/.ssh/authorized_keys"
  chmod 600 "/home/${HOST_USER:-learner}/.ssh/authorized_keys"
fi

# LAB_INIT=systemd boots a real init (set via compose.systemd.yml), so
# service and systemd tasks behave as on a full server. The default stays
# sshd as PID 1: no privileged containers needed.
if [[ "${LAB_INIT:-sshd}" == "systemd" ]]; then
  exec /lib/systemd/systemd
fi

exec /usr/sbin/sshd -D -e
