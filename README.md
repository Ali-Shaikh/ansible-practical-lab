# Ansible Practical Lab

This repo provides a small Docker based server estate for learning and testing Ansible commands, inventories and playbooks without renting servers or building virtual machines.

## Quick Start

Linux, macOS, or Windows with WSL:

```bash
./lab doctor
./lab up
./lab ping
```

Windows without WSL:

```powershell
.\lab.ps1 doctor
.\lab.ps1 up
.\lab.ps1 ping
```

## What Runs

- `forge`: on-demand Ansible control-node container.
- `atlas`: general Linux host.
- `beacon`: web host.
- `ledger`: database style host.
- `vaultbox`: secrets and certificate practice host.

The managed hosts are Ubuntu containers with SSH enabled. That is a lab shortcut so Ansible can practise normal SSH based Linux automation.

`forge` is built during setup, but it is not kept running. Commands such as `ping`, `facts` and `play` start a short-lived control-node container when Ansible is needed.

## Useful Commands

```bash
./lab doctor
./lab up
./lab status
./lab ping
./lab facts
./lab play playbooks/00_ping.yml
./lab shell
./lab down
./lab reset
```

## Run Any Ansible Command

Every command that starts with `ansible` is passed straight through to the
`forge` control node, with the repo mounted at `/workspace` and
`inventory/lab` as the default inventory:

```bash
./lab ansible web -m ansible.builtin.command -a uptime
./lab ansible-inventory --graph
./lab ansible-vault encrypt group_vars/secret.yml
./lab ansible-doc ansible.builtin.copy
./lab ansible-galaxy collection list
./lab lint                # ansible-lint over the repo
```

On Windows use `.\lab.ps1` the same way, and pass verbosity as `-vv` or
`-vvv` rather than bare `-v` (PowerShell reserves `-v` for `-Verbose`).

## Add More Hosts

```bash
./lab add-host titan            # plain linux host
./lab add-host cypress web      # also joins the web group
./lab up                        # build and start the new host
./lab remove-host cypress       # stop it and delete its files
```

`add-host` creates one Docker Compose drop-in under `compose.hosts/` and one
inventory file in each of `inventory/lab/` and `inventory/local/`, picking
the next free SSH port from 2226 upwards. The `lab` wrappers and `doctor`
pick the drop-ins up automatically, so no existing file needs editing.

## Running Ansible From The Host

The lab commands above run Ansible inside the short-lived `forge` container,
using the `inventory/lab` directory (hosts addressed by their Docker network
names).

If you have the OpenSSH client and Ansible installed on your own machine
(Linux, macOS, or WSL), you can also drive the lab directly from the host
using `inventory/local`, which reaches the managed hosts over the published
`127.0.0.1` ports:

```bash
ansible all -i inventory/local -m ansible.builtin.ping
ansible-playbook -i inventory/local playbooks/01_facts.yml
```

This path uses the host-side key at `.lab/ssh/id_ed25519`, so run it from the repo root.

## Known Limits

The managed hosts run sshd as their main process rather than systemd, so
`ansible.builtin.service` and `ansible.builtin.systemd` tasks will fail.
Practise packages, files, templates, users and cron instead. Everything else
behaves like a normal SSH-managed Ubuntu server.

## Version Policy

The lab defaults to Ubuntu 24.04 LTS. It is a supported LTS release and includes Python 3.12, which is required by current Ansible community package releases.

The control-node image installs Ansible with the current official `pipx` method:

```bash
pipx install --include-deps ansible
```

You can override the defaults before rebuilding:

```bash
UBUNTU_VERSION=26.04 docker compose build --no-cache
ANSIBLE_PACKAGE=ansible==14.1.0 docker compose build --no-cache forge
```

Version changes are accepted when `doctor`, `up`, `ping`, `facts` and the starter playbooks pass.

## Lab Credentials

The managed hosts use key-based SSH by default. The first `up` or `reset` command creates a lab-specific key pair here:

```text
.lab/ssh/id_ed25519
.lab/ssh/id_ed25519.pub
```

The public key is installed into the managed hosts when they start. The private key stays on your machine and is ignored by Git.

The `.lab/ssh` directory is kept in the repository with `.gitkeep`, but generated key files are ignored.

The images also contain this lab-only account:

- User: `learner`
- Password: `learner`

SSH password authentication is disabled in the normal lab path. The password exists only for the local Linux account inside the disposable containers. Do not copy this credential pattern into real infrastructure.

## Official References

- Ansible installation guide: https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html
- Ansible inventory guide: https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_inventory.html
- Docker Compose install guide: https://docs.docker.com/compose/install/
