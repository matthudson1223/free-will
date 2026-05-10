#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CREDENTIALS="$HOME/.claude/.credentials.json"
if [[ ! -f "$CREDENTIALS" ]]; then
    echo "ERROR: ~/.claude/.credentials.json not found."
    echo "Run 'claude' and log in first, then retry."
    exit 1
fi

UV="$HOME/.local/bin/uv"
if [[ ! -x "$UV" ]]; then
    echo "ERROR: uv not found at $UV"
    echo "Install it: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

echo "→ Syncing dependencies..."
"$UV" sync --quiet

echo "→ Starting free-will server on :8765"
"$UV" run uvicorn app.main:app --host 0.0.0.0 --port 8765 --reload
