#!/usr/bin/env bash
set -euo pipefail

docker compose config >/dev/null
bash -n lab
bash -n scripts/doctor.sh
