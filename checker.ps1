# checker.ps1 - Axios Supply Chain Attack Scanner (Windows)

Write-Host "=============================================="
Write-Host "   axios Supply Chain Attack - Checker"
Write-Host "=============================================="

# STEP 1: System check
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

# Prompt for folder path
Write-Host ""
$inputPath = Read-Host "📂 Enter the folder path to scan (press Enter for current directory)"
if ([string]::IsNullOrWhiteSpace($inputPath)) {
    $ScanPath = (Get-Location).Path
} else {
    $ScanPath = $inputPath
}

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
        Write-Host "🔍 Inspecting: $($dir.FullName)\"

        Push-Location $dir.FullName

        # 1. Malicious axios version check
        $axiosList = & npm list axios 2>$null
        if ($axiosList -match "1\.14\.1|0\.30\.4") {
            Write-Host "  🚨 WARNING: Malicious axios version found!"
        }

        # 2. plain-crypto-js dropper check
        $dropperPath = Join-Path $dir.FullName "node_modules\plain-crypto-js"
        if (Test-Path $dropperPath -PathType Container) {
            Write-Host "  🚨 WARNING: plain-crypto-js directory found (POTENTIALLY AFFECTED)!"
        }

        Pop-Location
    }
}

if (-not $found) {
    Write-Host "  ℹ️  No Node.js projects (package.json) found in subdirectories."
}

Write-Host "--------------------------------------------------"
Write-Host "🏁 Scan Completed."
