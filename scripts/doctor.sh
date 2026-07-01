#!/usr/bin/env bash
set -euo pipefail

missing=0

need_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing required command: $name"
    missing=1
  fi
}

need_command git
need_command docker
need_command ssh-keygen

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker is installed, but the Docker daemon is not reachable."
  echo "Start Docker Desktop or the Docker service, then run this command again."
  exit 1
fi

docker compose version >/dev/null

# Port clashes are the most common first-run failure. The lab publishes these
# host ports in docker-compose.yml, so check they are free before `up`.
# Skip the check when the lab is already running, since it legitimately holds
# these ports itself.
lab_ports=(2222 2223 2224 2225 8080)

lab_running() {
  [[ -n "$(docker ps --filter 'name=apl-' --format '{{.Names}}' 2>/dev/null)" ]]
}

port_in_use() {
  # Succeeds (exit 0) when something is already listening on the port.
  (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null
}

if ! lab_running; then
  ports_busy=0
  for port in "${lab_ports[@]}"; do
    if port_in_use "$port"; then
      echo "Port $port is already in use by another process."
      echo "Free it or change the port mapping in docker-compose.yml, then run doctor again."
      ports_busy=1
    fi
  done
  if [[ "$ports_busy" -ne 0 ]]; then
    exit 1
  fi
fi

echo "Doctor checks passed."
