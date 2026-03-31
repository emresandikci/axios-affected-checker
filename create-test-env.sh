#!/bin/bash

# ============================================================
#  Creates a mock vulnerable environment to test checker.sh
#  and fixer.sh WITHOUT downloading any real malicious packages.
#  All "installed" packages are empty stubs with fake metadata.
# ============================================================

BASE_DIR="$(pwd)/test-env"

echo "=============================================="
echo "   axios-affected-checker - Test Environment"
echo "=============================================="
echo ""
echo "Creating mock vulnerable projects in: $BASE_DIR"
echo ""

# --------------------------------------------------------------
# Project 1: axios 1.14.1 (malicious 1.x) + plain-crypto-js
# --------------------------------------------------------------
P1="$BASE_DIR/project-axios-1x"
mkdir -p "$P1/node_modules/axios"
mkdir -p "$P1/node_modules/plain-crypto-js"

cat > "$P1/package.json" <<'EOF'
{
  "name": "project-axios-1x",
  "version": "1.0.0",
  "dependencies": {
    "axios": "1.14.1"
  }
}
EOF

cat > "$P1/node_modules/axios/package.json" <<'EOF'
{
  "name": "axios",
  "version": "1.14.1"
}
EOF

cat > "$P1/node_modules/plain-crypto-js/package.json" <<'EOF'
{
  "name": "plain-crypto-js",
  "version": "1.0.0"
}
EOF

# npm lock file so checker detects it as npm project
echo '{ "lockfileVersion": 3 }' > "$P1/package-lock.json"

echo "✅ Created: project-axios-1x  (axios@1.14.1 + plain-crypto-js, npm)"

# --------------------------------------------------------------
# Project 2: axios 0.30.4 (malicious 0.x)
# --------------------------------------------------------------
P2="$BASE_DIR/project-axios-0x"
mkdir -p "$P2/node_modules/axios"

cat > "$P2/package.json" <<'EOF'
{
  "name": "project-axios-0x",
  "version": "1.0.0",
  "dependencies": {
    "axios": "0.30.4"
  }
}
EOF

cat > "$P2/node_modules/axios/package.json" <<'EOF'
{
  "name": "axios",
  "version": "0.30.4"
}
EOF

# pnpm lock file so checker detects it as pnpm project
touch "$P2/pnpm-lock.yaml"

echo "✅ Created: project-axios-0x  (axios@0.30.4, pnpm)"

# --------------------------------------------------------------
# Project 3: clean project (should pass all checks)
# --------------------------------------------------------------
P3="$BASE_DIR/project-clean"
mkdir -p "$P3/node_modules/axios"

cat > "$P3/package.json" <<'EOF'
{
  "name": "project-clean",
  "version": "1.0.0",
  "dependencies": {
    "axios": "1.14.0"
  }
}
EOF

cat > "$P3/node_modules/axios/package.json" <<'EOF'
{
  "name": "axios",
  "version": "1.14.0"
}
EOF

# yarn lock file so checker detects it as yarn project
touch "$P3/yarn.lock"

echo "✅ Created: project-clean      (axios@1.14.0 — safe, yarn)"

# --------------------------------------------------------------
# Project 4: plain-crypto-js only (no malicious axios)
# --------------------------------------------------------------
P4="$BASE_DIR/project-dropper-only"
mkdir -p "$P4/node_modules/axios"
mkdir -p "$P4/node_modules/plain-crypto-js"

cat > "$P4/package.json" <<'EOF'
{
  "name": "project-dropper-only",
  "version": "1.0.0",
  "dependencies": {
    "axios": "1.13.0"
  }
}
EOF

cat > "$P4/node_modules/axios/package.json" <<'EOF'
{
  "name": "axios",
  "version": "1.13.0"
}
EOF

cat > "$P4/node_modules/plain-crypto-js/package.json" <<'EOF'
{
  "name": "plain-crypto-js",
  "version": "1.0.0"
}
EOF

# bun lock file so checker detects it as bun project
touch "$P4/bun.lockb"

echo "✅ Created: project-dropper-only (plain-crypto-js only, bun)"

# --------------------------------------------------------------
# Optional: mock RAT artifact (commented out by default)
# Uncomment to also test the system-level RAT check.
# WARNING: fixer.sh will attempt to delete these paths.
# --------------------------------------------------------------
# if [ "$(uname)" = "Darwin" ]; then
#   sudo mkdir -p /Library/Caches/com.apple.act.mond
#   echo "⚠️  Mock macOS RAT artifact created at /Library/Caches/com.apple.act.mond"
# elif [ "$(uname)" = "Linux" ]; then
#   touch /tmp/ld.py
#   echo "⚠️  Mock Linux RAT artifact created at /tmp/ld.py"
# fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test environment ready. Now run:"
echo ""
echo "  ./checker.sh"
echo "  → enter path: $BASE_DIR"
echo ""
echo "Expected results:"
echo "  project-axios-1x    → 🚨 axios 1.14.1 + 🚨 plain-crypto-js"
echo "  project-axios-0x    → 🚨 axios 0.30.4"
echo "  project-clean       → ✅ clean"
echo "  project-dropper-only→ 🚨 plain-crypto-js"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
