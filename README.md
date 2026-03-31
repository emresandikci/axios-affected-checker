# axios-affected-checker

Scans your machine and Node.js projects for indicators of the axios supply chain attack.

## What it detects

| Check | Details |
|---|---|
| macOS RAT artifact | Presence of `/Library/Caches/com.apple.act.mond` |
| Linux RAT artifact | Presence of `/tmp/ld.py` |
| Windows RAT artifact | Presence of `%PROGRAMDATA%\wt.exe` |
| Malicious axios versions | `1.14.1` or `0.30.4` installed in any project |
| Malicious dropper package | `plain-crypto-js` present in `node_modules` |

## Requirements

- **macOS / Linux**: Bash, npm
- **Windows**: PowerShell 5+, npm

## How to run

Run the script, then enter the folder path containing your Node.js projects when prompted. It will scan all subdirectories with a `package.json`. Press Enter to use the current directory.

**macOS & Linux** — auto-detects OS; performs macOS RAT check when on macOS
```bash
chmod +x checker.sh
./checker.sh
```

**Windows (PowerShell)**
```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\checker.ps1
```

## Understanding the output

| Symbol | Meaning |
|---|---|
| ✅ | Clean — no issues found |
| 🚨 | Danger — malicious artifact or package detected |
| ℹ️ | Check skipped (not applicable on this OS) |

If any warnings appear, treat the affected project or system as potentially compromised and investigate immediately.

## Resources

- **Video walkthrough**: [Axios Supply Chain Attack Explained](https://www.youtube.com/watch?v=CHkiSSZiWVE)
- **Technical write-up**: [Axios Compromised on npm — StepSecurity](https://www.stepsecurity.io/blog/axios-compromised-on-npm-malicious-versions-drop-remote-access-trojan#:~:text=Am%20I%20Affected%3F%0AStep%201%20%E2%80%93,all%20injected%20secrets%20rotated%20immediately.)
