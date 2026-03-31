# ============================================================
#  axios Supply Chain Attack - Remediation Script (Windows)
#  Package managers supported: npm, pnpm, yarn, bun
#  Reference: https://www.stepsecurity.io/blog/axios-compromised-on-npm-malicious-versions-drop-remote-access-trojan
# ============================================================

Write-Host "=============================================="
Write-Host "   axios Supply Chain Attack - Remediation"
Write-Host "=============================================="
Write-Host ""
Write-Host "⚠️  This script will attempt to remove malicious artifacts,"
Write-Host "    downgrade axios, block C2 network traffic, and guide you"
Write-Host "    through credential rotation."
Write-Host ""
Read-Host "▶ Press Enter to continue or Ctrl+C to cancel"

$Compromised = $false

# --------------------------------------------------------------
# Helper: detect package manager from lock files
# --------------------------------------------------------------
function Get-PackageManager($dirPath) {
    if ((Test-Path (Join-Path $dirPath "bun.lockb")) -or (Test-Path (Join-Path $dirPath "bun.lock"))) {
        return "bun"
    } elseif (Test-Path (Join-Path $dirPath "pnpm-lock.yaml")) {
        return "pnpm"
    } elseif (Test-Path (Join-Path $dirPath "yarn.lock")) {
        return "yarn"
    } else {
        return "npm"
    }
}

# Helper: install a specific axios version safely
function Invoke-PkgInstall($mgr, $version) {
    switch ($mgr) {
        "pnpm" { & pnpm add "axios@$version" --ignore-scripts 2>$null }
        "yarn" { & yarn add "axios@$version" --ignore-scripts 2>$null }
        "bun"  { & bun  add "axios@$version" --ignore-scripts 2>$null }
        default { & npm install "axios@$version" --ignore-scripts 2>$null }
    }
}

# Helper: remove a package
function Invoke-PkgRemove($mgr, $pkg, $pkgPath) {
    switch ($mgr) {
        "pnpm" { & pnpm remove $pkg 2>$null }
        "yarn" { & yarn remove $pkg 2>$null }
        "bun"  { & bun  remove $pkg 2>$null }
        default { Remove-Item -Path $pkgPath -Recurse -Force }
    }
}

# Helper: reinstall all deps safely
function Invoke-PkgReinstall($mgr) {
    switch ($mgr) {
        "pnpm" { & pnpm install --ignore-scripts 2>$null }
        "yarn" { & yarn install --ignore-scripts 2>$null }
        "bun"  { & bun  install --ignore-scripts 2>$null }
        default { & npm install --ignore-scripts 2>$null }
    }
}

# --------------------------------------------------------------
# STEP 1: RAT Artifact Detection & Removal
# --------------------------------------------------------------
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "🔍 STEP 1: RAT Artifact Detection & Removal"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

$ratPath = Join-Path $env:PROGRAMDATA "wt.exe"
if (Test-Path $ratPath) {
    Write-Host "  🚨 RAT artifact found: $ratPath"
    $Compromised = $true
    Write-Host "  🗑️  Removing artifact..."
    try {
        Remove-Item -Path $ratPath -Force
        Write-Host "  ✅ Removed: $ratPath"
    } catch {
        Write-Host "  ❌ Failed to remove. Run manually as Administrator: Remove-Item -Path '$ratPath' -Force"
    }
} else {
    Write-Host "  ✅ No Windows RAT artifact found."
}

# --------------------------------------------------------------
# STEP 2: Block C2 Network Communication
# --------------------------------------------------------------
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "🌐 STEP 2: Block C2 Network Communication"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

$C2Host    = "sfrclak.com"
$C2IP      = "142.11.206.73"
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

$hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue
if ($hostsContent -match [regex]::Escape($C2Host)) {
    Write-Host "  ✅ C2 host already blocked in hosts file."
} else {
    Write-Host "  🚫 Blocking C2 host: $C2Host..."
    try {
        Add-Content -Path $hostsPath -Value "0.0.0.0 $C2Host"
        Write-Host "  ✅ Blocked $C2Host via hosts file."
    } catch {
        Write-Host "  ❌ Failed (requires Administrator). Run manually:"
        Write-Host "     Add-Content -Path '$hostsPath' -Value '0.0.0.0 $C2Host'"
    }
}

Write-Host "  🚫 Adding Windows Firewall rule to block $C2IP..."
try {
    $existingRule = Get-NetFirewallRule -DisplayName "Block axios C2" -ErrorAction SilentlyContinue
    if ($existingRule) {
        Write-Host "  ✅ Firewall rule already exists."
    } else {
        New-NetFirewallRule -DisplayName "Block axios C2" -Direction Outbound `
            -RemoteAddress $C2IP -Action Block -Protocol Any | Out-Null
        Write-Host "  ✅ Firewall rule added to block $C2IP."
    }
} catch {
    Write-Host "  ❌ Failed (requires Administrator). Run manually:"
    Write-Host "     New-NetFirewallRule -DisplayName 'Block axios C2' -Direction Outbound -RemoteAddress $C2IP -Action Block"
}

# --------------------------------------------------------------
# STEP 3: Scan and Remediate Node.js Projects
# --------------------------------------------------------------
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "📦 STEP 3: Scan and Remediate Node.js Projects"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host ""

$inputPath = Read-Host "📂 Enter the folder path to scan (press Enter for current directory)"
$ScanPath = if ([string]::IsNullOrWhiteSpace($inputPath)) { (Get-Location).Path } else { $inputPath }

if (-not (Test-Path $ScanPath -PathType Container)) {
    Write-Host "  ❌ Error: '$ScanPath' is not a valid directory."
    exit 1
}

Get-ChildItem -Path $ScanPath -Directory | ForEach-Object {
    $dir = $_
    $packageJson = Join-Path $dir.FullName "package.json"

    if (Test-Path $packageJson) {
        $pkgMgr = Get-PackageManager $dir.FullName
        Write-Host ""
        Write-Host "🔍 Inspecting: $($dir.FullName)\  (package manager: $pkgMgr)"
        Push-Location $dir.FullName

        # Detect malicious axios version by reading installed package.json directly
        $axiosPkgJson = Join-Path $dir.FullName "node_modules\axios\package.json"
        $axiosVersion = $null
        if (Test-Path $axiosPkgJson) {
            $versionMatch = [regex]::Match((Get-Content $axiosPkgJson -Raw), '"version"\s*:\s*"([^"]+)"')
            if ($versionMatch.Success) { $axiosVersion = $versionMatch.Groups[1].Value }
        }

        if ($axiosVersion -match "^(1\.14\.1|0\.30\.4)$") {
            Write-Host "  🚨 Malicious axios version detected: $axiosVersion"

            $safeVersion = if ($axiosVersion -match "^1\.") { "1.14.0" } else { "0.30.3" }
            Write-Host "  ⬇️  Downgrading axios to $safeVersion via $pkgMgr..."
            try {
                Invoke-PkgInstall $pkgMgr $safeVersion
                Write-Host "  ✅ axios downgraded to $safeVersion"
            } catch {
                $installCmd = if ($pkgMgr -eq "npm") { "install" } else { "add" }
                Write-Host "  ❌ Failed. Run manually: $pkgMgr $installCmd axios@$safeVersion --ignore-scripts"
            }
        } else {
            $versionInfo = if ($axiosVersion) { " ($axiosVersion)" } else { "" }
            Write-Host "  ✅ axios version is safe$versionInfo."
        }

        # Remove plain-crypto-js dropper (handles symlinks/junctions for pnpm/yarn/bun)
        $dropperPath = Join-Path $dir.FullName "node_modules\plain-crypto-js"
        if (Test-Path $dropperPath) {
            Write-Host "  🚨 plain-crypto-js dropper found."
            Write-Host "  🗑️  Removing plain-crypto-js via $pkgMgr..."
            try {
                Invoke-PkgRemove $pkgMgr "plain-crypto-js" $dropperPath
                Write-Host "  ✅ plain-crypto-js removed."
            } catch {
                Write-Host "  ❌ Failed. Run manually: $pkgMgr remove plain-crypto-js"
            }
        } else {
            Write-Host "  ✅ plain-crypto-js not present."
        }

        # Reinstall safely if axios was malicious
        if ($axiosVersion -match "^(1\.14\.1|0\.30\.4)$") {
            Write-Host "  🔄 Reinstalling dependencies safely (--ignore-scripts)..."
            try {
                Invoke-PkgReinstall $pkgMgr
                Write-Host "  ✅ Dependencies reinstalled safely."
            } catch {
                Write-Host "  ❌ Reinstall failed. Run manually: $pkgMgr install --ignore-scripts"
            }
        }

        Pop-Location
    }
}

# --------------------------------------------------------------
# STEP 4: Credential Rotation Checklist
# --------------------------------------------------------------
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "🔑 STEP 4: Credential Rotation Checklist"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ($Compromised) {
    Write-Host ""
    Write-Host "  🚨 RAT artifacts were found. Your system may be FULLY COMPROMISED."
    Write-Host "     Treat this machine as untrusted. Consider rebuilding from a known-good state."
    Write-Host ""
}

Write-Host ""
Write-Host "  Manually rotate ALL secrets that were accessible on this machine:"
Write-Host ""
Write-Host "  [ ] npm tokens        -> https://www.npmjs.com/settings/~/tokens"
Write-Host "  [ ] AWS access keys   -> https://console.aws.amazon.com/iam"
Write-Host "  [ ] GCP credentials   -> https://console.cloud.google.com/iam-admin"
Write-Host "  [ ] Azure secrets     -> https://portal.azure.com"
Write-Host "  [ ] SSH private keys  -> regenerate and re-authorize on all servers"
Write-Host "  [ ] CI/CD secrets     -> GitHub / GitLab / CircleCI / etc. pipeline env vars"
Write-Host "  [ ] .env files        -> rotate all tokens and passwords in .env"
Write-Host ""
Write-Host "  Also review CI/CD logs for any install runs that used"
Write-Host "  axios@1.14.1 or axios@0.30.4 and rotate secrets from those jobs."
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "🏁 Remediation Script Completed."
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
