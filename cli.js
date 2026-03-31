#!/usr/bin/env node

const { spawnSync } = require('child_process');
const path = require('path');
const os = require('os');

const args = process.argv.slice(2);
const fix = args.includes('--fix');
const isWindows = os.platform() === 'win32';
const dir = __dirname;

if (isWindows) {
  const script = path.join(dir, fix ? 'fixer.ps1' : 'checker.ps1');
  const result = spawnSync(
    'powershell.exe',
    ['-ExecutionPolicy', 'Bypass', '-File', script],
    { stdio: 'inherit' }
  );
  process.exit(result.status || 0);
} else {
  const script = path.join(dir, fix ? 'fixer.sh' : 'checker.sh');
  spawnSync('chmod', ['+x', script]);
  const result = spawnSync('bash', [script], { stdio: 'inherit' });
  process.exit(result.status || 0);
}
