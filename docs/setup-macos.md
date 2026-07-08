# macOS Setup

Install Docker Desktop for Mac and Git.

You can run Ansible through the `forge` control-node container, or install Ansible locally with `pipx`:

```bash
brew install git pipx
pipx ensurepath
pipx install --include-deps ansible
```
