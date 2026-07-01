# Troubleshooting

## Docker Is Not Running

Run:

```bash
docker version
```

Docker should show both a client and server.

## Compose Is Missing

Run:

```bash
docker compose version
```

Install Docker Desktop or the Docker Compose plugin if the command is missing.

## Ansible Cannot Reach Hosts

Check the containers:

```bash
./lab status
```

Then reset the lab:

```bash
./lab reset
./lab ping
```

## SSH Key Problems

The lab creates a dedicated SSH key under `.lab/ssh`. If the key is missing or corrupt, recreate it:

```bash
rm -rf .lab
./lab up
./lab ping
```

On Windows without WSL, remove the `.lab` folder and run:

```powershell
.\lab.ps1 up
.\lab.ps1 ping
```
