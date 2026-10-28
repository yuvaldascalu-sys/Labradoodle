#!/usr/bin/env bash
# Keep this agent's memory in sync across machines and sessions.
#   sync.sh pull              fetch the latest memory before starting
#   sync.sh push "message"    commit and push memory changes
set -euo pipefail
cd "$(dirname "$0")/.."

retry() {
  local delay=2
  for _ in 1 2 3 4 5; do
    "$@" && return 0
    sleep "$delay"; delay=$((delay * 2))
  done
  return 1
}

case "${1:-}" in
  pull)
    git remote get-url origin >/dev/null 2>&1 || { echo "no remote yet"; exit 0; }
    retry git pull --rebase --autostash origin main
    ;;
  push)
    git add -A
    git diff --cached --quiet && { echo "nothing to save"; exit 0; }
    git commit -m "${2:-memory update}"
    git remote get-url origin >/dev/null 2>&1 || { echo "no remote yet"; exit 0; }
    # Another session may have pushed meanwhile: rebase and retry.
    retry sh -c 'git pull --rebase origin main && git push -u origin main'
    ;;
  *)
    echo "usage: $0 pull | push \"message\"" >&2; exit 1
    ;;
esac
