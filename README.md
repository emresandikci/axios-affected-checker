# axios-affected-checker

Scans your machine and Node.js projects for indicators of the axios supply chain attack, then fixes any issues found.

Supports package managers: **npm, pnpm, yarn, bun**

---

## Quickstart (npx)

No installation required:

```bash
# Scan for indicators
npx @emstack/axios-affected-checker

# Fix issues found
npx @emstack/axios-affected-checker --fix
```

---

## Scripts

| Script | Platform | Purpose |
|---|---|---|
| `checker.sh` | macOS / Linux | Scan for indicators |
| `checker.ps1` | Windows | Scan for indicators |
| `fixer.sh` | macOS / Linux | Remove artifacts, downgrade axios, block C2 |
| `fixer.ps1` | Windows | Remove artifacts, downgrade axios, block C2 |

---

## What it detects

| Check | Details |
|---|---|
| macOS RAT artifact | Presence of `/Library/Caches/com.apple.act.mond` |
| Linux RAT artifact | Presence of `/tmp/ld.py` |
| Windows RAT artifact | Presence of `%PROGRAMDATA%\wt.exe` |
| Malicious axios versions | `1.14.1` or `0.30.4` installed in any project |
| Malicious dropper package | `plain-crypto-js` present in `node_modules` |

---

## Requirements

- **macOS / Linux**: Bash, and at least one of: npm, pnpm, yarn, bun
- **Windows**: PowerShell 5+, and at least one of: npm, pnpm, yarn, bun

---

## Step 1 — Run the checker

Run the script, then enter the folder path containing your Node.js projects when prompted. It scans all subdirectories with a `package.json` and auto-detects the package manager per project. Press Enter to use the current directory.

**macOS & Linux** — auto-detects OS; runs macOS or Linux RAT check accordingly
```bash
chmod +x checker.sh
./checker.sh
```

**Windows (PowerShell)**
```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\checker.ps1
```

---

## Step 2 — Run the fixer (if issues found)

If the checker reports any warnings, run the fixer. It will:

1. Remove the OS-specific RAT artifact
2. Block C2 server (`sfrclak.com` / `142.11.206.73`) via hosts file and firewall
3. Downgrade malicious axios to a safe version (`1.14.0` or `0.30.3`)
4. Remove `plain-crypto-js` dropper from `node_modules`
5. Reinstall dependencies with `--ignore-scripts`
6. Show a credential rotation checklist

**macOS & Linux**
```bash
chmod +x fixer.sh
./fixer.sh
```
> Some steps require `sudo` (RAT removal, hosts file, iptables on Linux).

**Windows (PowerShell — run as Administrator)**
```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\fixer.ps1
```
> Must be run as Administrator for RAT removal and firewall rules.

> **If RAT artifacts are found**, treat the machine as fully compromised. Rebuild from a known-good state and rotate all secrets immediately.

---

## Understanding the output

| Symbol | Meaning |
|---|---|
| ✅ | Clean — no issues found |
| 🚨 | Danger — malicious artifact or package detected |
| ℹ️ | Check skipped (not applicable on this OS) |

---

## Testing

`create-test-env.sh` builds a mock vulnerable environment locally — no real malicious packages are downloaded. It creates stub `node_modules` with fake metadata files only.

```bash
chmod +x create-test-env.sh
./create-test-env.sh
```

Then point the checker at the generated folder:
```
→ enter path: ./test-env
```

| Project created | Expected checker result |
|---|---|
| `project-axios-1x` | 🚨 axios 1.14.1 + 🚨 plain-crypto-js (npm) |
| `project-axios-0x` | 🚨 axios 0.30.4 (pnpm) |
| `project-clean` | ✅ clean (yarn) |
| `project-dropper-only` | 🚨 plain-crypto-js only (bun) |

To also test the RAT artifact check, uncomment the relevant lines at the bottom of `create-test-env.sh`.

---

## Resources

- **Video walkthrough**: [Axios Supply Chain Attack Explained](https://www.youtube.com/watch?v=CHkiSSZiWVE)
- **Technical write-up**: [Axios Compromised on npm — StepSecurity](https://www.stepsecurity.io/blog/axios-compromised-on-npm-malicious-versions-drop-remote-access-trojan#:~:text=Am%20I%20Affected%3F%0AStep%201%20%E2%80%93,all%20injected%20secrets%20rotated%20immediately.)
