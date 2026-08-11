#!/usr/bin/env bash
set -e

HOST="$1"
USER="$2"
KEY="$3"

if [ -z "$HOST" ] || [ -z "$USER" ] || [ -z "$KEY" ]; then
  echo "Missing args: <host> <user> <key>" >&2
  exit 1
fi

# Use ssh with a short timeout; ignore host key checking for automation
SSH_OPTS=( -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o BatchMode=yes )

# Run systemctl commands, capture output even if non-zero
run_cmd() {
  local cmd="$1"
  ssh -i "$KEY" "${SSH_OPTS[@]}" "${USER}@${HOST}" "$cmd" 2>&1 || true
}

G_OUT=$(run_cmd "sudo systemctl status grafana-server --no-pager --no-full || true")
P_OUT=$(run_cmd "sudo systemctl status prometheus --no-pager --no-full || true")
N_OUT=$(run_cmd "sudo systemctl status node_exporter --no-pager --no-full || true")

# Write to temp files and print JSON using Python to ensure proper escaping
TMPDIR=$(mktemp -d)
printf "%s" "$G_OUT" > "$TMPDIR/g.out"
printf "%s" "$P_OUT" > "$TMPDIR/p.out"
printf "%s" "$N_OUT" > "$TMPDIR/n.out"

python3 - <<PY
import json
with open('$TMPDIR/g.out') as f: g=f.read()
with open('$TMPDIR/p.out') as f: p=f.read()
with open('$TMPDIR/n.out') as f: n=f.read()
print(json.dumps({'grafana': g, 'prometheus': p, 'node_exporter': n}))
PY

rm -rf "$TMPDIR"
