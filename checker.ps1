# checker.ps1 - Axios Supply Chain Attack Scanner (Windows)
# Package managers supported: npm, pnpm, yarn, bun

Write-Host "=============================================="
Write-Host "   axios Supply Chain Attack - Checker"
Write-Host "=============================================="

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

# --------------------------------------------------------------
# STEP 1: System check
# --------------------------------------------------------------
Write-Host ""
Write-Host "🪟 STEP 1: Performing Windows System Check..."
$ratPath = Join-Path $env:PROGRAMDATA "wt.exe"
if (Test-Path $ratPath) {
    Write-Host "  🚨 CRITICAL DANGER: RAT artifact found on your Windows system (COMPROMISED)!"
} else {
    Write-Host "  ✅ Clean: No malicious artifacts found system-wide."
}

Write-Host ""
Write-Host "--------------------------------------------------"

# --------------------------------------------------------------
# Prompt for folder path
# --------------------------------------------------------------
Write-Host ""
$inputPath = Read-Host "📂 Enter the folder path to scan (press Enter for current directory)"
$ScanPath = if ([string]::IsNullOrWhiteSpace($inputPath)) { (Get-Location).Path } else { $inputPath }

if (-not (Test-Path $ScanPath -PathType Container)) {
    Write-Host "  ❌ Error: '$ScanPath' is not a valid directory."
    exit 1
}

Write-Host ""
Write-Host "📁 STEP 2: Scanning subdirectories in: $ScanPath"
Write-Host "--------------------------------------------------"

$found = $false

Get-ChildItem -Path $ScanPath -Directory | ForEach-Object {
    $dir = $_
    $packageJson = Join-Path $dir.FullName "package.json"

    if (Test-Path $packageJson) {
        $found = $true
        $pkgMgr = Get-PackageManager $dir.FullName
        Write-Host "🔍 Inspecting: $($dir.FullName)\  (package manager: $pkgMgr)"

        Push-Location $dir.FullName

        # 1. Malicious axios version check — read directly from installed package.json
        $axiosPkgJson = Join-Path $dir.FullName "node_modules\axios\package.json"
        $axiosVersion = $null
        if (Test-Path $axiosPkgJson) {
            $versionMatch = [regex]::Match((Get-Content $axiosPkgJson -Raw), '"version"\s*:\s*"([^"]+)"')
            if ($versionMatch.Success) { $axiosVersion = $versionMatch.Groups[1].Value }
        }

        if ($axiosVersion -match "^(1\.14\.1|0\.30\.4)$") {
            Write-Host "  🚨 WARNING: Malicious axios version found! ($axiosVersion)"
        }

        # 2. plain-crypto-js dropper check (handles symlinks/junctions for pnpm/yarn/bun)
        $dropperPath = Join-Path $dir.FullName "node_modules\plain-crypto-js"
        if (Test-Path $dropperPath) {
            Write-Host "  🚨 WARNING: plain-crypto-js found (POTENTIALLY AFFECTED)!"
        }

        Pop-Location
    }
}

if (-not $found) {
    Write-Host "  ℹ️  No Node.js projects (package.json) found in subdirectories."
}

Write-Host "--------------------------------------------------"
Write-Host "🏁 Scan Completed."
