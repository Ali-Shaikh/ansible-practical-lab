# Compact Checkpoint - Ansible Practical Lab

Date: 2026-07-08

## Goal Achieved
Completed the remaining work for the "Practical Ansible" article series (Articles 6 and 7) inside the ansible-practical-lab:

- Full roles/ structure (common + web) with tasks, handlers, templates, defaults, meta.
- Article 6 support: templates + Jinja2, serial rollouts, validation (`failed_when`, `changed_when`), playbook `30_templates_and_rollouts.yml`.
- Article 7 support: Vault example + encryption instructions, role composition, production guardrails, playbook `40_roles_and_vault.yml`.
- Supporting: Updated CI (syntax + smoke for new playbooks + roles), smoke.sh, README, added standalone playbook template example.
- New articles written: `articles/06-...md` and `07-...md` following existing style, tone, and structure.
- Vault example prepared (group_vars/secrets/vault_example.yml) with clear instructions.

## Current State
- Lab infrastructure: mature (already was).
- Playbooks 00-20: unchanged (kept simple for early articles).
- New: roles/, 30_ and 40_ playbooks, templates inside roles + playbook level.
- Articles 1-7: all present in /articles/.
- CI and tests updated to cover the new material.
- British English, practical tone, FQCN used everywhere.

## What Was Verified
- All new files present and correctly structured.
- Earlier manual runs (ping + baseline) succeeded.
- Syntax checks prepared in CI and can be run via `./lab play ... --syntax-check`.
- Docker builds and basic connectivity previously confirmed in session.

## Next / Open
- Full end-to-end runtime test of 30_ and 40_ (recommend `LAB_INIT=systemd ./lab up` then the plays).
- Optionally encrypt the vault_example in a real session: `./lab ansible-vault encrypt group_vars/secrets/vault_example.yml`.
- Update any external index or lab.cloudsprocket.org links when publishing.
- Consider adding more roles or a patching demo in a follow-up.

## How to Resume
1. `cd ansible-practical-lab`
2. `.\lab.ps1 doctor && .\lab.ps1 up`
3. Test: `.\lab.ps1 play playbooks/30_templates_and_rollouts.yml --limit atlas`
4. For services: `LAB_INIT=systemd .\lab.ps1 up` then run service-heavy plays.
5. Vault demo: encrypt the example file then run `40_roles_and_vault.yml`.

All changes follow the original plan, guardrails, and existing conventions (numbered playbooks, group targeting, roles best practices).
