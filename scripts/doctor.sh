#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

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

if [[ -f VERSION ]]; then
  LAB_VERSION=$(head -n1 VERSION | tr -d '[:space:]')
  echo "ansible-practical-lab version: $LAB_VERSION (see VERSION file and official compatibility notes)"
fi

# Same compose file list as the ./lab wrapper: the base file plus one
# drop-in per added host, plus the systemd override when LAB_INIT=systemd.
compose_files=(-f docker-compose.yml)
for host_file in compose.hosts/*.yml; do
  [[ -e "$host_file" ]] && compose_files+=(-f "$host_file")
done

LAB_INIT="${LAB_INIT:-sshd}"
case "$LAB_INIT" in
  sshd) ;;
  systemd)
    compose_files+=(-f compose.systemd.yml)
    echo "Init mode: systemd (privileged containers; service/systemd tasks work)."
    ;;
  *)
    echo "LAB_INIT must be 'sshd' (default) or 'systemd', not '$LAB_INIT'."
    exit 1
    ;;
esac

# Port clashes are the most common first-run failure. Read the published
# ports from the resolved compose config so added hosts are covered too.
# Skip the check when the lab is already running, since it legitimately
# holds these ports itself.
lab_running() {
  [[ -n "$(docker ps --filter 'name=apl-' --format '{{.Names}}' 2>/dev/null)" ]]
}

port_in_use() {
  # Succeeds (exit 0) when something is already listening on the port.
  (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null
}

if ! lab_running; then
  # No mapfile here: macOS ships bash 3.2 by default.
  lab_ports=()
  while IFS= read -r published_port; do
    lab_ports+=("$published_port")
  done < <(
    docker compose "${compose_files[@]}" config 2>/dev/null \
      | sed -n 's/.*published: "\{0,1\}\([0-9]\{1,\}\)"\{0,1\}.*/\1/p' \
      | sort -un
  )
  if [[ "${#lab_ports[@]}" -eq 0 ]]; then
    # Fall back to the default lab ports if the compose config could not
    # be parsed for any reason.
    lab_ports=(2222 2223 2224 2225 8080)
  fi
  ports_busy=0
  for port in "${lab_ports[@]}"; do
    if port_in_use "$port"; then
      echo "Port $port is already in use by another process."
      echo "Free it or change the port mapping, then run doctor again."
      ports_busy=1
    fi
  done
  if [[ "$ports_busy" -ne 0 ]]; then
    exit 1
  fi
fi

echo "Doctor checks passed."
