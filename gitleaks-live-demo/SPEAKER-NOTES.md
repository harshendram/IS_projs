# Speaker notes

**Before the class (5 minutes)**
1. Plug in the projector, set Windows Terminal font large (`Ctrl` + `+`).
2. Double-click `CHECK-SETUP.cmd`: both versions print.
3. Double-click `MAKE-BACKUP.cmd`: fresh backup in `backup\` (copy it to your phone or a USB drive too).
4. Double-click `START-DEMO.cmd` (all 8 tabs) or `START-CORE-DEMOS.cmd` (tabs 1-4): tabs open and wait on their title screens.

**10-minute plan**

| Time | What |
|---|---|
| 0:00-2:00 | Slides: the problem, your case study hook, what Gitleaks is |
| 2:00-8:00 | Live: tabs 1, 2, 3, 4 (about 1:30 each) |
| 8:00-9:30 | Wrap-up: limits and best practice |
| Q&A | Answer with tabs 5-8 |

Each `PS>` line waits for Enter. Talk first, then press Enter.

---

## Tab 1: Finding secrets (1:30)

| On screen | Say |
|---|---|
| Title | "This is a practice repo the script just built. Every key in it is fake." |
| `Get-Content config.py` | "A developer hardcoded an AWS key, a GitHub token and a database password. This happens every day." |
| `git add` / `git commit` | "They commit it. Now it is part of the project's history." |
| `gitleaks git -v` | "One command scans every commit. It found all three." |
| (point at one finding) | "**RuleID** github-pat is one of about 200 built-in regex rules. **File, Line, Commit, Author** say exactly where and who. **Entropy** 5.27 measures randomness: real keys are random, so high entropy means likely real. **Fingerprint** is this finding's unique ID." |
| exit code 1 | "Exit code 1 means leaks found. That is what makes a CI pipeline fail." |

## Tab 2: Git history never forgets (1:30)

| On screen | Say |
|---|---|
| `git log` | "Same mistake, already committed." |
| new `config.py` + commit | "The developer notices, moves secrets to environment variables, commits the fix." |
| `gitleaks dir .` (0) | "`dir` scans only the files as they are now. Clean. Looks fixed..." |
| `gitleaks git` (3) | "...but `git` scans history: still 3 leaks." |
| `git show HEAD~1:config.py` | "No tool needed: anyone can print the old version." |
| clone + scan (3) | "Pushing to GitHub gives every cloner the full history. Bots scan public repos for keys within minutes." |
| end | "So the real fix is to **revoke and rotate the key first**. Cleaning history comes second." |

## Tab 3: Pre-commit hook (1:30)

| On screen | Say |
|---|---|
| hook file | "Prevention: a git hook runs gitleaks on the staged changes before every commit. `--staged` means it only checks what is about to be committed, so it takes under a second." |
| blocked commit | "Blocked. The Slack token never entered history. That is far cheaper than cleaning up later." |
| fixed commit | "Fixed properly and committed." |
| `--no-verify` on a branch | "Weakness: hooks run on the developer's laptop, and anyone can skip them with `--no-verify`." |
| `dir` (0), `git -v` (1) | "On main the folder is clean, but `gitleaks git` scans **all branches** and still finds the Stripe key." |
| `--log-opts=main..feature/payments` | "In CI we scan only the commits a pull request adds. Lesson: hook for developers **and** CI on the server." |

## Tab 4: Custom regex rules (1:30, Part C optional)

| On screen | Say |
|---|---|
| `internal_api.py` | "Our organisation issues tokens with its own prefix, RIT_DEMO_TOKEN_." |
| default scan (0) | "The built-in rules have never heard of it." |
| `.gitleaks.toml` | "A rule is just a regex. `secretGroup` picks the secret part, `entropy` skips boring placeholders, `keywords` is a fast pre-filter, `[extend] useDefault` keeps the 200 built-in rules." |
| scan (1) | "Real token caught. The aaaa placeholder was skipped because its entropy is 0." |
| Part B `git log` | "Someone committed a server inventory and deleted it later." |
| `search-rules.toml` + scan (4) | "With only my own regex rules, gitleaks becomes a search engine over all history. It found internal hostnames and IPs in a file that no longer exists." |
| Part C (if time) | "More rule types: path-only (a file called id_rsa), path+regex (password only in YAML), allowlists (ignore `changeme`), and composite rules (a secret only counts if a client ID is within 3 lines)." |

## Tabs 5-8: use for questions

| Question | Tab | One-line answer |
|---|---|---|
| "What about false positives?" | 5 | Inline `gitleaks:allow`, `[[allowlists]]` in config, `.gitleaksignore` fingerprints, `--baseline-path` for old repos. Ignoring hides findings only from you, not from attackers. |
| "Can you save or share the results?" | 6 | JSON, CSV, SARIF (GitHub Security tab), JUnit (CI dashboards), custom HTML template, with `--redact`. |
| "What if the key is base64-encoded or zipped?" | 7 | Decodes base64/hex/percent automatically (depth 5); opens archives with `--max-archive-depth`. |
| "How do companies use it?" | 8 | `stdin` for logs, exit codes 0/1/126 for CI, a GitHub Actions workflow on every push. |

## Wrap-up (1:30)

- **Gitleaks** finds secrets in files, git history and any text, using about 200 regex rules plus entropy.
- **Best practice:** pre-commit hook + CI scan + rotate any leaked key immediately.
- **Limits:** regex-based, so unknown formats need custom rules; some false positives; it does **not** check whether a key still works. The regex engine is RE2, so custom rules cannot use lookaheads.

## Before presenting: check these facts

These came from the original brief and have **not** been verified yet:
- Gitleaks 8.30.1 is the latest release. (It was the version winget installed on 2026-11-19.)
- The Binance October 2026 incident details and the Trust Wallet December 2025 Chrome Web Store key leak.
- Betterleaks (March 2026) as the original author's successor project.
- gitleaks-action needs a paid licence for organisation repos.

## If the laptop or projector fails

- Open `backup\report.html` on any machine and the `backup\*.txt` files; they hold the full output of every demo.
- Or clone this repo on another Windows machine with gitleaks installed and run `.\open-terminals.ps1`.
