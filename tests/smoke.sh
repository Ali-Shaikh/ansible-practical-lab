#!/usr/bin/env bash
set -euo pipefail

docker compose config >/dev/null
bash -n lab
bash -n scripts/doctor.sh

# Basic role and playbook syntax presence check (full validation in CI)
test -d roles/common/tasks
test -d roles/web/templates
test -f playbooks/30_templates_and_rollouts.yml
test -f playbooks/40_roles_and_vault.yml
test -f playbooks/templates/lab_status.j2
echo "Smoke: roles and advanced playbook files present."
