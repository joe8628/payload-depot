#!/usr/bin/env bash
set -euo pipefail

RIG_REPO="https://github.com/joe8628/Rig.git"
RIG_HOME="${RIG_HOME:-$HOME/.rig}"

echo "[rig-stage] Installing Rig..."

if [[ -d "$RIG_HOME/.git" ]]; then
  echo "[rig-stage] Found existing install at $RIG_HOME — updating..."
  git -C "$RIG_HOME" pull --ff-only
else
  echo "[rig-stage] Cloning into $RIG_HOME..."
  git clone --depth 1 "$RIG_REPO" "$RIG_HOME"
fi

cd "$RIG_HOME"
make install

echo ""
echo "[rig-stage] Done. Run: rig-stage install"
echo ""

# Check PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo "[rig-stage] WARNING: $HOME/.local/bin is not on your PATH."
  echo "[rig-stage] Add this to your ~/.bashrc or ~/.zshrc:"
  echo ""
  echo '    export PATH="$HOME/.local/bin:$PATH"'
  echo ""
fi
