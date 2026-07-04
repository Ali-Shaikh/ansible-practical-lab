---
name: ansible-lab
description: Operate the Docker-based Ansible practice lab in this repo. Use when starting or resetting the lab, running ansible/ansible-playbook/ansible-vault or any other Ansible CLI, adding or removing managed hosts, writing new playbooks, or debugging SSH and connectivity failures between the control node and the lab hosts.
---

# Ansible Practical Lab

A disposable server estate for practising Ansible. Managed hosts are Ubuntu
containers with SSH; Ansible runs in a short-lived control-node container
called `forge`, so nothing needs to be installed on the user's machine except
Docker, Git and an OpenSSH client.

Use `./lab <command>` (Linux, macOS, WSL) or `.\lab.ps1 <command>` (Windows
PowerShell). Both wrappers behave identically. Always prefer the wrapper over
raw `docker compose`, because it assembles the compose file list from
`docker-compose.yml` plus the per-host drop-ins in `compose.hosts/`.

## Layout

- `docker-compose.yml`: forge (control node, profile `tools`) + the four
  default hosts atlas, beacon (web), ledger (database), vaultbox (secrets).
- `compose.hosts/<name>.yml`: one drop-in per host added with `add-host`.
- `inventory/lab/`: inventory as seen from inside forge (Docker DNS names).
- `inventory/local/`: same hosts as seen from the host machine
  (127.0.0.1 + published ports), for people running Ansible natively.
- `playbooks/`: numbered playbooks; 00-09 connectivity and facts,
  10+ configuration.
- `.lab/ssh/`: generated lab SSH key pair. Never commit the private key;
  Git ignores it already.

## Everyday commands

```bash
./lab up                 # build and start everything (also creates the SSH key)
./lab ping               # ansible.builtin.ping against all hosts
./lab play playbooks/10_baseline.yml
./lab down               # stop the estate; reset rebuilds from scratch
```

Any command starting with `ansible` is passed straight through to forge:

```bash
./lab ansible web -m ansible.builtin.command -a uptime
./lab ansible-inventory --graph
./lab ansible-vault encrypt group_vars/secret.yml
./lab ansible-doc ansible.builtin.copy
./lab ansible-galaxy collection list
```

`./lab lint` runs ansible-lint (installed in forge), `./lab inventory` prints
the group graph, `./lab shell` opens bash in forge, `./lab exec <cmd>` runs
anything else there.

PowerShell note: pass verbosity as `-vv` or `-vvv`, never bare `-v`
(PowerShell steals it as the common `-Verbose` parameter).

## Adding and removing hosts

```bash
./lab add-host titan          # plain linux host
./lab add-host cypress web    # also joins the web group
./lab up                      # builds and starts the new host
./lab remove-host cypress
```

`add-host` writes three files (compose drop-in, lab inventory, local
inventory) and picks the next free SSH port from 2226. Do not hand-edit
`docker-compose.yml` to add hosts; use the drop-in mechanism so
`remove-host` and the doctor port checks keep working. Default hosts
(atlas, beacon, ledger, vaultbox) cannot be removed this way.

## Writing playbooks

- Put them in `playbooks/` with the number prefix convention.
- Target groups (`linux`, `web`, `database`, `secrets`), not raw host names.
- Use fully qualified module names (`ansible.builtin.*`); available Galaxy
  collections are pinned in `requirements.yml` and baked into the forge
  image, so a change there needs `docker compose build forge`.
- Validate before running:
  `./lab ansible-playbook playbooks/NN_name.yml --syntax-check`, then
  `./lab lint playbooks/NN_name.yml`, then `./lab play playbooks/NN_name.yml`.
- A second run should report `changed=0`; treat non-idempotent tasks as bugs.

## Constraints to remember

- The managed hosts run sshd as PID 1, not systemd. `ansible.builtin.service`
  / `systemd` tasks will fail. Practise packages, files, templates, users,
  cron and similar instead, or start daemons with `ansible.builtin.command`.
- Containers are Ubuntu 24.04 with Python 3; `become` works via passwordless
  sudo for the `learner` user.
- The learner/learner password is a lab-only convention; SSH password auth is
  disabled and only the generated key is used. Never copy this pattern into
  real infrastructure and never commit anything from `.lab/`.

## Troubleshooting

- Connection refused or unreachable: `./lab status`, then `./lab reset`.
- Key problems: delete `.lab/` and run `./lab up` (regenerates the key and
  reinstalls it into the hosts on start).
- Port clash on 2222-2225/8080: `./lab doctor` names the busy port.
- Changed the control-node image or requirements.yml: `docker compose build
  forge` (or `./lab up`, which rebuilds).
