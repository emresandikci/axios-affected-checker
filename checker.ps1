# checker.ps1 - Axios Supply Chain Attack Scanner (Windows)

Write-Host "🪟 STEP 1: macOS System Check..."
Write-Host "  ℹ️  Skipping macOS RAT artifact check (not applicable on Windows)."

Write-Host "--------------------------------------------------"
Write-Host "📁 STEP 2: Scanning Project Directories..."

Get-ChildItem -Directory | ForEach-Object {
    $dir = $_
    $packageJson = Join-Path $dir.FullName "package.json"

    if (Test-Path $packageJson) {
        Write-Host "🔍 Inspecting: $($dir.Name)\"

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

Write-Host "--------------------------------------------------"
Write-Host "🏁 Scan Completed."
