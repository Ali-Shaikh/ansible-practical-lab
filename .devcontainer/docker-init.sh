#!/bin/sh
# Starts dockerd for Docker-in-Docker, then execs the container command.
# Adapted from the MIT-licensed Microsoft docker-in-docker Feature init script.
# https://github.com/devcontainers/features/tree/main/src/docker-in-docker
set -e

dockerd_start() {
    # Remove stale PID files so dockerd can start after unclean stop
    find /run /var/run -iname 'docker*.pid' -delete 2>/dev/null || :
    find /run /var/run -iname 'container*.pid' -delete 2>/dev/null || :

    export container=docker

    if [ -d /sys/kernel/security ] && ! mountpoint -q /sys/kernel/security; then
        mount -t securityfs none /sys/kernel/security || true
    fi

    if ! mountpoint -q /tmp; then
        mount -t tmpfs none /tmp || true
    fi

    # cgroup v2 nesting (needed for nested containers)
    if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
        mkdir -p /sys/fs/cgroup/init
        xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs 2>/dev/null || :
        sed -e 's/ / +/g' -e 's/^/+/' < /sys/fs/cgroup/cgroup.controllers \
            > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || :
    fi

    CUSTOMDNS=""
    if grep -qi 'internal.cloudapp.net' /etc/resolv.conf 2>/dev/null; then
        CUSTOMDNS="--dns 168.63.129.16"
    fi

    # shellcheck disable=SC2086
    dockerd $CUSTOMDNS --ip6tables=false >/tmp/dockerd.log 2>&1 &
}

if [ "$(id -u)" -ne 0 ]; then
    # vscode user: start dockerd as root via passwordless sudo
    sudo sh -c '
        find /run /var/run -iname "docker*.pid" -delete 2>/dev/null || true
        find /run /var/run -iname "container*.pid" -delete 2>/dev/null || true
        export container=docker
        if [ -d /sys/kernel/security ] && ! mountpoint -q /sys/kernel/security; then
            mount -t securityfs none /sys/kernel/security || true
        fi
        if ! mountpoint -q /tmp; then
            mount -t tmpfs none /tmp || true
        fi
        if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
            mkdir -p /sys/fs/cgroup/init
            xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs 2>/dev/null || true
            sed -e "s/ / +/g" -e "s/^/+/" < /sys/fs/cgroup/cgroup.controllers \
                > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || true
        fi
        CUSTOMDNS=""
        if grep -qi internal.cloudapp.net /etc/resolv.conf 2>/dev/null; then
            CUSTOMDNS="--dns 168.63.129.16"
        fi
        dockerd $CUSTOMDNS --ip6tables=false >/tmp/dockerd.log 2>&1 &
    '
else
    dockerd_start
fi

i=0
while [ "$i" -lt 30 ]; do
    if docker info >/dev/null 2>&1; then
        break
    fi
    i=$((i + 1))
    sleep 1
done

if [ "$#" -eq 0 ]; then
    set -- sleep infinity
fi
exec "$@"
