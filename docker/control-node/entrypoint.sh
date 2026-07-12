#!/usr/bin/env bash
set -euo pipefail

if [[ -f /workspace/.lab/ssh/id_ed25519 ]]; then
  install --directory --mode=0700 /tmp/lab-ssh
  cp /workspace/.lab/ssh/id_ed25519 /tmp/lab-ssh/id_ed25519
  chmod 600 /tmp/lab-ssh/id_ed25519
  # Public key is needed by playbooks that install authorized_keys from the
  # lab key (see managed_users_key_file). Copy it alongside the private key
  # so the path works inside forge on every platform.
  if [[ -f /workspace/.lab/ssh/id_ed25519.pub ]]; then
    cp /workspace/.lab/ssh/id_ed25519.pub /tmp/lab-ssh/id_ed25519.pub
    chmod 644 /tmp/lab-ssh/id_ed25519.pub
  fi
fi

exec "$@"
