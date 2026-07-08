#!/usr/bin/env bash
set -euo pipefail

if [[ -f /workspace/.lab/ssh/id_ed25519 ]]; then
  install --directory --mode=0700 /tmp/lab-ssh
  cp /workspace/.lab/ssh/id_ed25519 /tmp/lab-ssh/id_ed25519
  chmod 600 /tmp/lab-ssh/id_ed25519
fi

exec "$@"
