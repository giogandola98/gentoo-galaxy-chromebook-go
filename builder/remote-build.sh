#!/bin/bash
# Forced command for the Chromebook's key (authorized_keys on the build server):
#   command="/path/to/builder/remote-build.sh",restrict ssh-ed25519 AAAA... sasuke-update
# The key can only: start "builder update" (no command) or show the status ("check").
cd "$(dirname "$(readlink -f "$0")")" || exit 1
case "$SSH_ORIGINAL_COMMAND" in
  "")    exec docker compose exec -T builder builder update ;;
  check) exec docker compose exec -T builder builder status 3 ;;
  *)     echo "not allowed" >&2; exit 1 ;;
esac
