#!/bin/bash

OS="$(uname -s)"

echo "=============================================="
echo "   axios Supply Chain Attack - Checker"
echo "=============================================="

# --------------------------------------------------------------
# Helper: detect package manager from lock files
# --------------------------------------------------------------
detect_pkg_manager() {
  local dir="$1"
  if [ -f "$dir/bun.lockb" ] || [ -f "$dir/bun.lock" ]; then
    echo "bun"
  elif [ -f "$dir/pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "$dir/yarn.lock" ]; then
    echo "yarn"
  else
    echo "npm"
  fi
}

# --------------------------------------------------------------
# STEP 1: System-level RAT check
# --------------------------------------------------------------
if [ "$OS" = "Darwin" ]; then
  echo ""
  echo "🍎 STEP 1: Performing macOS System Check..."
  if ls -la /Library/Caches/com.apple.act.mond >/dev/null 2>&1; then
    echo "  🚨 CRITICAL DANGER: RAT artifact found on your macOS system (COMPROMISED)!"
  else
    echo "  ✅ Clean: No malicious artifacts found system-wide."
  fi
else
  echo ""
  echo "🐧 STEP 1: Performing Linux System Check..."
  if ls -la /tmp/ld.py >/dev/null 2>&1; then
    echo "  🚨 CRITICAL DANGER: RAT artifact found on your Linux system (COMPROMISED)!"
  else
    echo "  ✅ Clean: No malicious artifacts found system-wide."
  fi
fi

echo ""
echo "--------------------------------------------------"

# --------------------------------------------------------------
# Prompt for folder path
# --------------------------------------------------------------
echo ""
read -rp "📂 Enter the folder path to scan (press Enter for current directory): " SCAN_PATH
SCAN_PATH="${SCAN_PATH:-$(pwd)}"
SCAN_PATH="${SCAN_PATH/#\~/$HOME}"

if [ ! -d "$SCAN_PATH" ]; then
  echo "  ❌ Error: '$SCAN_PATH' is not a valid directory."
  exit 1
fi

echo ""
echo "📁 STEP 2: Scanning subdirectories in: $SCAN_PATH"
echo "--------------------------------------------------"

FOUND=0

for dir in "$SCAN_PATH"/*/; do
  if [ -f "$dir/package.json" ]; then
    FOUND=1
    PKG_MGR=$(detect_pkg_manager "$dir")
    echo "🔍 Inspecting: $dir  (package manager: $PKG_MGR)"

    (
      cd "$dir"

      # 1. Malicious axios version check — read directly from installed package.json
      AXIOS_VERSION=$(grep -m1 '"version"' node_modules/axios/package.json 2>/dev/null \
        | grep -oE "[0-9]+\.[0-9]+\.[0-9]+")
      if echo "$AXIOS_VERSION" | grep -qE "^(1\.14\.1|0\.30\.4)$"; then
        echo "  🚨 WARNING: Malicious axios version found! ($AXIOS_VERSION)"
      fi

      # 2. plain-crypto-js dropper check (symlink OR directory — covers pnpm/yarn/bun/npm)
      if [ -d "node_modules/plain-crypto-js" ] || [ -L "node_modules/plain-crypto-js" ]; then
        echo "  🚨 WARNING: plain-crypto-js found (POTENTIALLY AFFECTED)!"
      fi
    )
  fi
done

if [ "$FOUND" -eq 0 ]; then
  echo "  ℹ️  No Node.js projects (package.json) found in subdirectories."
fi

echo "--------------------------------------------------"
echo "🏁 Scan Completed."
