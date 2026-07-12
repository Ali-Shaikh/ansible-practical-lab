#!/usr/bin/env bash
# Lightweight static checks (no Docker estate). Runtime coverage lives in
# .github/workflows/ci.yml (smoke job).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

docker compose config >/dev/null
bash -n lab
bash -n scripts/doctor.sh
bash -n docker/control-node/entrypoint.sh
bash -n docker/managed-host/entrypoint.sh

# Vault demo must not be a loadable group_vars file (would ship plaintext).
if [[ -f inventory/lab/group_vars/secrets/vault_example.yml ]] ||
   [[ -f inventory/local/group_vars/secrets/vault_example.yml ]]; then
  echo "vault_example.yml must not live under group_vars (use vault.yml.example)." >&2
  exit 1
fi
if [[ ! -f inventory/lab/group_vars/secrets/vault.yml.example ]] ||
   [[ ! -f inventory/local/group_vars/secrets/vault.yml.example ]]; then
  echo "Missing inventory/*/group_vars/secrets/vault.yml.example" >&2
  exit 1
fi

echo "Static smoke checks passed."
