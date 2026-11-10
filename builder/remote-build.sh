#!/bin/bash
# Forced command for the Chromebook's key (authorized_keys on the build server):
#   command="/path/to/builder/remote-build.sh",restrict ssh-ed25519 AAAA... sasuke-update
# The key can only: start "builder update" (no command, or "ultra" for the ULTRA variant)
# or show the status ("check", "ultra-check").
cd "$(dirname "$(readlink -f "$0")")" || exit 1
# ULTRA_JOBS from .env: the job count is passed explicitly so that an older container
# created with a different value still uses the current one
ULTRA_JOBS=$(sed -n 's/^ULTRA_JOBS=//p' .env 2>/dev/null)
U="docker compose --profile ultra exec -T -e BUILD_JOBS=${ULTRA_JOBS} builder-ultra"
case "$SSH_ORIGINAL_COMMAND" in
  "")          exec docker compose exec -T builder builder update ;;
  check)       exec docker compose exec -T builder builder status 3 ;;
  ultra)       exec $U builder update ;;
  ultra-check) exec $U builder status 3 ;;
  *)     echo "not allowed" >&2; exit 1 ;;
esac
