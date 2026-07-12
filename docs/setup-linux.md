# Linux Setup

Install Docker using the official Docker instructions for your distribution.

On Ubuntu or Debian based systems, install the helper tools:

```bash
sudo apt update
sudo apt install -y git python3 python3-pip pipx
pipx ensurepath
pipx install --include-deps ansible
```

You can also run Ansible through the `forge` control-node container by using `./lab`.
