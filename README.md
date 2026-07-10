# Ansible Practical Lab

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/Ali-Shaikh/ansible-practical-lab)

This repo provides a small Docker based server estate for learning and testing Ansible commands, inventories and playbooks without renting servers or building virtual machines.

Guides, the quick start and the Practical Ansible article series live at
[lab.cloudsprocket.org](https://lab.cloudsprocket.org). The lab is free and
open source under the [MIT licence](LICENSE).

## Zero-Install: GitHub Codespaces

No Docker on your machine? Open the repo in a Codespace
([codespaces.new/Ali-Shaikh/ansible-practical-lab](https://codespaces.new/Ali-Shaikh/ansible-practical-lab)),
wait for the container to build, then run the normal commands in its
terminal:

```bash
./lab up
./lab ping
```

The devcontainer brings its own Docker engine, so the whole estate runs
inside the Codespace. The same configuration works locally with the
VS Code Dev Containers extension.

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

## Web Studio: Editor And Terminal In The Browser

If you would rather not use a local editor or terminal, start the optional
studio container:

```bash
./lab studio
```

Then open http://127.0.0.1:8443. You get VS Code in the browser with the
repo already open, the Ansible extension installed, and an integrated
terminal that lives on the lab network, so you can run Ansible directly:

```bash
ansible all -m ansible.builtin.ping
ansible-playbook playbooks/10_baseline.yml
ansible-lint playbooks/
```

The studio binds to `127.0.0.1` only and runs without a password; treat it
like the rest of the lab and never expose the port beyond your machine.
`./lab down` stops it along with everything else. Pin a different
code-server release with `CODE_SERVER_VERSION=... docker compose --profile
studio build studio`.

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

## Article-Aligned Playbooks

Starter and series playbooks ship with the lab so the free articles run
against real files:

| Playbook | Purpose |
| --- | --- |
| `playbooks/00_ping.yml` | Reachability |
| `playbooks/01_facts.yml` | Fact gathering (`./lab facts`) |
| `playbooks/10_baseline.yml` | Small Linux baseline |
| `playbooks/20_users_and_ssh.yml` | Users, keys and sudo (article 4) |
| `playbooks/30_web_service.yml` | nginx + handlers (article 5) |
| `playbooks/40_templates_and_handlers.yml` | Templates, validate, serial, flush before verify (article 6) |
| `playbooks/60_secrets.yml` | Vault-backed secret deploy (article 7) |
| `playbooks/70_web_role.yml` | Apply `roles/web` (article 7 refactor) |
| `playbooks/21_services_systemd.yml` | Optional systemd-mode service demo |

Group vars for article 4 live in `inventory/*/group_vars/linux.yml`. For
article 7, copy `inventory/lab/group_vars/secrets/vault.yml.example` to
`vault.yml` in the same directory, encrypt it, then run
`./lab play playbooks/60_secrets.yml --ask-vault-pass`. The example uses a
`.example` suffix so Ansible does not auto-load a plaintext demo password.

## Service Management: Two Init Modes

By default the managed hosts run sshd as PID 1 (unprivileged containers).
Many packages still ship classic init scripts, so `ansible.builtin.service`
for nginx (article 5) works via that fallback. Tasks that need a real
systemd (`ansible.builtin.systemd`, full unit control) need systemd mode:

```bash
./lab down
LAB_INIT=systemd ./lab up
./lab play playbooks/21_services_systemd.yml
```

```powershell
.\lab.ps1 down
$env:LAB_INIT = "systemd"; .\lab.ps1 up
.\lab.ps1 play playbooks/21_services_systemd.yml
```

Each default host then boots systemd as PID 1 (the Molecule/geerlingguy
pattern). The trade-off is weaker isolation: privileged containers and the
host cgroup namespace. Fine for a disposable lab bound to 127.0.0.1; do not
copy that pattern for exposed services. Hosts created with `add-host` keep
sshd init in either mode. Use the same `LAB_INIT` for `up`, `down` and
`reset`; run `down` before switching.

## Lab Version

The repo root `VERSION` file is the lab compatibility pin for pro content.
Print it with `./lab version` (or `.\lab.ps1 version`). Doctor also reports
it when the file is present.

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
