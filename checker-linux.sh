#!/bin/bash

echo "🐧 STEP 1: macOS System Check..."
echo "  ℹ️  Skipping macOS RAT artifact check (not applicable on Linux)."

echo "--------------------------------------------------"
echo "📁 STEP 2: Scanning Project Directories..."

for dir in */; do
  if [ -f "$dir/package.json" ]; then
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

echo "--------------------------------------------------"
echo "🏁 Scan Completed."
