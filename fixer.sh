#!/bin/bash

# ============================================================
#  axios Supply Chain Attack - Remediation Script
#  Supports: macOS and Linux | Package managers: npm, pnpm, yarn, bun
#  Reference: https://www.stepsecurity.io/blog/axios-compromised-on-npm-malicious-versions-drop-remote-access-trojan
# ============================================================

OS="$(uname -s)"
COMPROMISED=0

echo "=============================================="
echo "   axios Supply Chain Attack - Remediation"
echo "=============================================="
echo ""
echo "⚠️  This script will attempt to remove malicious artifacts,"
echo "    downgrade axios, block C2 network traffic, and guide you"
echo "    through credential rotation."
echo ""
read -rp "▶ Press Enter to continue or Ctrl+C to cancel..."

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

# Helper: install a specific axios version safely (no postinstall scripts)
pkg_install() {
  local mgr="$1" version="$2"
  case "$mgr" in
    pnpm) pnpm add "axios@$version" --ignore-scripts 2>/dev/null ;;
    yarn) yarn add "axios@$version" --ignore-scripts 2>/dev/null ;;
    bun)  bun  add "axios@$version" --ignore-scripts 2>/dev/null ;;
    *)    npm install "axios@$version" --ignore-scripts 2>/dev/null ;;
  esac
}

# Helper: remove a package safely
pkg_remove() {
  local mgr="$1" pkg="$2"
  case "$mgr" in
    pnpm) pnpm remove "$pkg" 2>/dev/null ;;
    yarn) yarn remove "$pkg" 2>/dev/null ;;
    bun)  bun  remove "$pkg" 2>/dev/null ;;
    *)    rm -rf "node_modules/$pkg" ;;
  esac
}

# Helper: reinstall all deps safely
pkg_reinstall() {
  local mgr="$1"
  case "$mgr" in
    pnpm) pnpm install --ignore-scripts 2>/dev/null ;;
    yarn) yarn install --ignore-scripts 2>/dev/null ;;
    bun)  bun  install --ignore-scripts 2>/dev/null ;;
    *)    npm install --ignore-scripts 2>/dev/null ;;
  esac
}

# --------------------------------------------------------------
# STEP 1: RAT Artifact Detection & Removal
# --------------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 STEP 1: RAT Artifact Detection & Removal"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$OS" = "Darwin" ]; then
  RAT_PATH="/Library/Caches/com.apple.act.mond"
  if ls -la "$RAT_PATH" >/dev/null 2>&1; then
    echo "  🚨 RAT artifact found: $RAT_PATH"
    COMPROMISED=1
    echo "  🗑️  Removing artifact (requires sudo)..."
    sudo rm -rf "$RAT_PATH" && echo "  ✅ Removed: $RAT_PATH" \
      || echo "  ❌ Failed. Run manually: sudo rm -rf $RAT_PATH"
  else
    echo "  ✅ No macOS RAT artifact found."
  fi
elif [ "$OS" = "Linux" ]; then
  RAT_PATH="/tmp/ld.py"
  if ls -la "$RAT_PATH" >/dev/null 2>&1; then
    echo "  🚨 RAT artifact found: $RAT_PATH"
    COMPROMISED=1
    echo "  🗑️  Removing artifact..."
    rm -f "$RAT_PATH" && echo "  ✅ Removed: $RAT_PATH" \
      || echo "  ❌ Failed. Run manually: rm -f $RAT_PATH"
  else
    echo "  ✅ No Linux RAT artifact found."
  fi
fi

# --------------------------------------------------------------
# STEP 2: Block C2 Network Communication
# --------------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 STEP 2: Block C2 Network Communication"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

C2_HOST="sfrclak.com"
C2_IP="142.11.206.73"
HOSTS_FILE="/etc/hosts"

if grep -q "$C2_HOST" "$HOSTS_FILE" 2>/dev/null; then
  echo "  ✅ C2 host already blocked in $HOSTS_FILE."
else
  echo "  🚫 Blocking C2 host: $C2_HOST (requires sudo)..."
  echo "0.0.0.0 $C2_HOST" | sudo tee -a "$HOSTS_FILE" >/dev/null \
    && echo "  ✅ Blocked $C2_HOST via $HOSTS_FILE" \
    || echo "  ❌ Failed. Run manually: echo '0.0.0.0 $C2_HOST' | sudo tee -a $HOSTS_FILE"
fi

if [ "$OS" = "Linux" ] && command -v iptables >/dev/null 2>&1; then
  if iptables -C OUTPUT -d "$C2_IP" -j DROP >/dev/null 2>&1; then
    echo "  ✅ iptables rule for $C2_IP already exists."
  else
    echo "  🚫 Adding iptables DROP rule for $C2_IP (requires sudo)..."
    sudo iptables -A OUTPUT -d "$C2_IP" -j DROP \
      && echo "  ✅ iptables rule added." \
      || echo "  ❌ Failed. Run manually: sudo iptables -A OUTPUT -d $C2_IP -j DROP"
  fi
fi

# --------------------------------------------------------------
# STEP 3: Scan and Remediate Node.js Projects
# --------------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 3: Scan and Remediate Node.js Projects"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -rp "📂 Enter the folder path to scan (press Enter for current directory): " SCAN_PATH
SCAN_PATH="${SCAN_PATH:-$(pwd)}"
SCAN_PATH="${SCAN_PATH/#\~/$HOME}"

if [ ! -d "$SCAN_PATH" ]; then
  echo "  ❌ Error: '$SCAN_PATH' is not a valid directory."
  exit 1
fi

for dir in "$SCAN_PATH"/*/; do
  if [ -f "$dir/package.json" ]; then
    PKG_MGR=$(detect_pkg_manager "$dir")
    echo ""
    echo "🔍 Inspecting: $dir  (package manager: $PKG_MGR)"

    (
      cd "$dir"

      # Detect malicious axios version by reading installed package.json directly
      AXIOS_VERSION=$(grep -m1 '"version"' node_modules/axios/package.json 2>/dev/null \
        | grep -oE "[0-9]+\.[0-9]+\.[0-9]+")

      if echo "$AXIOS_VERSION" | grep -qE "^(1\.14\.1|0\.30\.4)$"; then
        echo "  🚨 Malicious axios version detected: $AXIOS_VERSION"

        MAJOR=$(echo "$AXIOS_VERSION" | cut -d. -f1)
        SAFE_VERSION=$([ "$MAJOR" = "1" ] && echo "1.14.0" || echo "0.30.3")

        echo "  ⬇️  Downgrading axios to $SAFE_VERSION via $PKG_MGR..."
        pkg_install "$PKG_MGR" "$SAFE_VERSION" \
          && echo "  ✅ axios downgraded to $SAFE_VERSION" \
          || echo "  ❌ Failed. Run manually: $PKG_MGR $([ "$PKG_MGR" = "npm" ] && echo install || echo add) axios@$SAFE_VERSION --ignore-scripts"
      else
        echo "  ✅ axios version is safe${AXIOS_VERSION:+ ($AXIOS_VERSION)}."
      fi

      # Remove plain-crypto-js dropper (symlink OR directory — covers all package managers)
      if [ -d "node_modules/plain-crypto-js" ] || [ -L "node_modules/plain-crypto-js" ]; then
        echo "  🚨 plain-crypto-js dropper found."
        echo "  🗑️  Removing plain-crypto-js via $PKG_MGR..."
        pkg_remove "$PKG_MGR" "plain-crypto-js" \
          && echo "  ✅ plain-crypto-js removed." \
          || echo "  ❌ Failed. Run manually: $PKG_MGR remove plain-crypto-js"
      else
        echo "  ✅ plain-crypto-js not present."
      fi

      # Reinstall safely if axios was malicious
      if echo "$AXIOS_VERSION" | grep -qE "^(1\.14\.1|0\.30\.4)$"; then
        echo "  🔄 Reinstalling dependencies safely (--ignore-scripts)..."
        pkg_reinstall "$PKG_MGR" \
          && echo "  ✅ Dependencies reinstalled safely." \
          || echo "  ❌ Reinstall failed. Run manually: $PKG_MGR install --ignore-scripts"
      fi
    )
  fi
done

# --------------------------------------------------------------
# STEP 4: Credential Rotation Checklist
# --------------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 STEP 4: Credential Rotation Checklist"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$COMPROMISED" -eq 1 ]; then
  echo ""
  echo "  🚨 RAT artifacts were found. Your system may be FULLY COMPROMISED."
  echo "     Treat this machine as untrusted. Consider rebuilding from a known-good state."
  echo ""
fi

echo ""
echo "  Manually rotate ALL secrets that were accessible on this machine:"
echo ""
echo "  [ ] npm tokens        → https://www.npmjs.com/settings/~/tokens"
echo "  [ ] AWS access keys   → https://console.aws.amazon.com/iam"
echo "  [ ] GCP credentials   → https://console.cloud.google.com/iam-admin"
echo "  [ ] Azure secrets     → https://portal.azure.com"
echo "  [ ] SSH private keys  → regenerate and re-authorize on all servers"
echo "  [ ] CI/CD secrets     → GitHub / GitLab / CircleCI / etc. pipeline env vars"
echo "  [ ] .env files        → rotate all tokens and passwords in .env"
echo ""
echo "  Also review CI/CD logs for any install runs that used"
echo "  axios@1.14.1 or axios@0.30.4 and rotate secrets from those jobs."
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏁 Remediation Script Completed."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
