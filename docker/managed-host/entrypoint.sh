#!/usr/bin/env bash
set -euo pipefail

ssh-keygen -A

if [[ -f /lab-ssh/authorized_keys ]]; then
  install --directory --owner="${HOST_USER:-learner}" --group="${HOST_USER:-learner}" --mode=0700 "/home/${HOST_USER:-learner}/.ssh"
  cp /lab-ssh/authorized_keys "/home/${HOST_USER:-learner}/.ssh/authorized_keys"
  chown "${HOST_USER:-learner}:${HOST_USER:-learner}" "/home/${HOST_USER:-learner}/.ssh/authorized_keys"
  chmod 600 "/home/${HOST_USER:-learner}/.ssh/authorized_keys"
fi

exec /usr/sbin/sshd -D -e
