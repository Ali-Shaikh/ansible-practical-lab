#!/bin/bash
# DinD entrypoint: start dockerd, then exec the container command.
# Root of the earlier Codespaces failure: dockerd never became reachable in postCreate.
# This script must run as root (see Dockerfile USER + devcontainer.json entrypoint).
set +e

LOG=/tmp/dockerd.log
: >"$LOG"

log() {
    echo "[docker-init] $*" | tee -a "$LOG"
}

if [ "$(id -u)" -ne 0 ]; then
    log "not root (uid=$(id -u)); re-exec with sudo"
    exec sudo -E /usr/local/share/docker-init.sh "$@"
fi

# Already running?
if docker info >/dev/null 2>&1; then
    log "dockerd already reachable"
else
    log "starting dockerd"

    find /run /var/run -iname 'docker*.pid' -delete 2>/dev/null
    find /run /var/run -iname 'container*.pid' -delete 2>/dev/null

    export container=docker

    if [ -d /sys/kernel/security ] && ! mountpoint -q /sys/kernel/security; then
        mount -t securityfs none /sys/kernel/security 2>>"$LOG" || true
    fi
    if ! mountpoint -q /tmp; then
        mount -t tmpfs none /tmp 2>>"$LOG" || true
    fi

    # cgroup v2 nesting
    if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
        mkdir -p /sys/fs/cgroup/init
        # shellcheck disable=SC2002
        cat /sys/fs/cgroup/cgroup.procs 2>/dev/null | xargs -rn1 > /sys/fs/cgroup/init/cgroup.procs 2>/dev/null || true
        sed -e 's/ / +/g' -e 's/^/+/' < /sys/fs/cgroup/cgroup.controllers \
            > /sys/fs/cgroup/cgroup.subtree_control 2>>"$LOG" || true
    fi

    CUSTOMDNS=()
    if grep -qi 'internal.cloudapp.net' /etc/resolv.conf 2>/dev/null; then
        CUSTOMDNS=(--dns 168.63.129.16)
        log "using Azure DNS 168.63.129.16"
    fi

    # Prefer overlay2; fall back to vfs (always works nested, slower).
    for DRIVER in overlay2 vfs; do
        log "trying storage-driver=$DRIVER"
        dockerd \
            --host=unix:///var/run/docker.sock \
            --storage-driver="$DRIVER" \
            --ip6tables=false \
            "${CUSTOMDNS[@]}" \
            >>"$LOG" 2>&1 &
        DOCKERD_PID=$!

        for _ in $(seq 1 40); do
            if docker info >/dev/null 2>&1; then
                log "dockerd ready (pid=$DOCKERD_PID, driver=$DRIVER)"
                # so vscode (non-root) can use the socket without a re-login
                chmod 666 /var/run/docker.sock 2>>"$LOG" || true
                break 2
            fi
            if ! kill -0 "$DOCKERD_PID" 2>/dev/null; then
                log "dockerd exited early with driver=$DRIVER; tail of log:"
                tail -n 40 "$LOG" || true
                break
            fi
            sleep 0.5
        done

        kill "$DOCKERD_PID" 2>/dev/null || true
        wait "$DOCKERD_PID" 2>/dev/null || true
        find /run /var/run -iname 'docker*.pid' -delete 2>/dev/null
        find /run /var/run -iname 'container*.pid' -delete 2>/dev/null
    done

    if ! docker info >/dev/null 2>&1; then
        log "ERROR: dockerd failed to become ready; see $LOG"
        tail -n 80 "$LOG" || true
    fi
fi

if [ "$#" -eq 0 ]; then
    set -- sleep infinity
fi
exec "$@"
