#!/bin/bash

OS="$(uname -s)"

echo "=============================================="
echo "   axios Supply Chain Attack - Checker"
echo "=============================================="

# STEP 1: System-level check (macOS only)
if [ "$OS" = "Darwin" ]; then
  echo ""
  echo "🍎 STEP 1: Performing macOS System Check..."
  if ls -d /Library/Caches/com.apple.act.mond >/dev/null 2>&1; then
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

# Prompt for folder path
echo ""
read -rp "📂 Enter the folder path to scan (press Enter for current directory): " SCAN_PATH
SCAN_PATH="${SCAN_PATH:-$(pwd)}"

# Expand ~ if used
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
    echo "🔍 Inspecting: $dir"
    (
      cd "$dir"

      # 1. Malicious axios version check
      if npm list axios 2>/dev/null | grep -qE "1\.14\.1|0\.30\.4"; then
        echo "  🚨 WARNING: Malicious axios version found!"
      fi

      # 2. plain-crypto-js dropper check
      if [ -d "node_modules/plain-crypto-js" ]; then
        echo "  🚨 WARNING: plain-crypto-js directory found (POTENTIALLY AFFECTED)!"
      fi
    )
  fi
done

if [ "$FOUND" -eq 0 ]; then
  echo "  ℹ️  No Node.js projects (package.json) found in subdirectories."
fi

echo "--------------------------------------------------"
echo "🏁 Scan Completed."
