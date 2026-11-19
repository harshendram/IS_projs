# Gitleaks live demo

Live demo scripts for presenting [Gitleaks](https://github.com/gitleaks/gitleaks), an open-source tool that finds hardcoded secrets (API keys, tokens, passwords) in code and git history.

Each demo is one PowerShell script that runs in its own terminal tab. It builds a fresh practice repo, then shows every command before running it and waits for **Enter**, so you can explain each step.

> Every secret used here is **fake**. The scripts assemble them at runtime, so the script files contain no secret-shaped strings, and this repo itself passes a gitleaks scan.

## Requirements

| Tool | Install (Windows) | Check |
|---|---|---|
| Gitleaks 8.30.1 | `winget install --id=Gitleaks.Gitleaks -e` | `gitleaks version` |
| Git | `winget install --id=Git.Git -e` | `git --version` |
| Windows Terminal (optional, for tabs) | built into Windows 11 | `wt --version` |

Open a **new** terminal after installing so `gitleaks` is on PATH.

## Quick start

### Double-click (easiest)

Open the folder in File Explorer and double-click one of these:

| File | What it does |
|---|---|
| `CHECK-SETUP.cmd` | Confirms gitleaks and git work |
| `START-CORE-DEMOS.cmd` | Opens tabs 1-4 (the 6-minute live demo) |
| `START-DEMO.cmd` | Opens all 8 demo tabs |
| `MAKE-BACKUP.cmd` | Records every demo's output into `backup\` |
| `RESET.cmd` | Deletes all demo workspaces |

> Do **not** double-click the `.ps1` files: by default Windows opens them in Notepad instead of running them.

### From a PowerShell terminal

Use PowerShell, not Command Prompt.

```powershell
cd gitleaks-live-demo
.\00-check-setup.ps1                 # confirm tools work
.\open-terminals.ps1                 # one tab per demo (1-8), each waits on its title screen
.\open-terminals.ps1 -Demos 1,2,3,4  # only the core demos
```

To run a single demo in the current terminal, use `.\03-pre-commit-hook.ps1`.

To rehearse without pauses, use `$env:DEMO_AUTO='1'; .\01-find-secrets.ps1; Remove-Item Env:DEMO_AUTO`.

## The demos

| Tab | Script | Gitleaks features shown | Time |
|---|---|---|---|
| 1 | `01-find-secrets.ps1` | `gitleaks git -v`, built-in rules, reading a finding, exit code 1 | 1:30 |
| 2 | `02-history-never-forgets.ps1` | `dir` vs `git` scan, `git show` of old commit, attacker clone | 1:30 |
| 3 | `03-pre-commit-hook.ps1` | `--pre-commit --staged` hook blocks a commit, `--no-verify` bypass, all-branch scan, `--log-opts` PR range | 1:30 |
| 4 | `04-custom-regex-rules.ps1` | custom rule (regex, `secretGroup`, `entropy`, `keywords`), regex **search** of history with `-c`, path-only / path+regex / allowlist / composite rules | 1:30-3:00 |
| 5 | `05-false-positives.ps1` | `gitleaks:allow`, `--ignore-gitleaks-allow`, `[[allowlists]]`, `.gitleaksignore` fingerprints, `--baseline-path` | 2:00 |
| 6 | `06-reports-and-redaction.ps1` | JSON, `--redact`, `--redact=50`, CSV, SARIF, JUnit, custom HTML template | 1:30 |
| 7 | `07-encoded-and-archives.ps1` | base64 / hex / double-encoded secrets, `--max-decode-depth`, zip-in-zip with `--max-archive-depth` | 1:30 |
| 8 | `08-stdin-and-ci.ps1` | `gitleaks stdin` on logs and command output, exit codes 0/1/126, `--exit-code`, GitHub Actions workflow | 1:30 |

Tabs 1-4 make a 6-minute core demo. Use tabs 5-8 to answer questions.

## Other scripts

| Script | Purpose |
|---|---|
| `open-terminals.ps1` | Opens the demo tabs in a new Windows Terminal window (falls back to separate windows) |
| `make-backup.ps1` | Runs every demo without pauses and saves the output to `backup\` (plus `report.html`) in case the laptop or projector fails |
| `reset.ps1` | Deletes all demo workspaces (`Documents\gitleaks-live`). Each demo also resets itself when started |
| `common.ps1` | Shared helpers and the fake secrets; loaded by every demo |
| `SPEAKER-NOTES.md` | What to say at each step, timings, and likely questions |

## Troubleshooting

- **A `.ps1` file opens in Notepad**: that happens when you double-click it or type its name in Command Prompt. Double-click the matching `.cmd` file instead, or run it from a PowerShell window as `.\open-terminals.ps1`.
- **"running scripts is disabled on this system"**: run `powershell -ExecutionPolicy Bypass -File .\open-terminals.ps1`, or once: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.
- **"gitleaks is not installed"** right after installing: open a new terminal.
- **"Could not delete ..."**: another tab is still inside that demo's folder; close it and rerun.
- **Text too small on the projector**: press `Ctrl` + `+` in Windows Terminal.
- **Note:** in v8.30.1, `--report-template` also needs `-f template`.
