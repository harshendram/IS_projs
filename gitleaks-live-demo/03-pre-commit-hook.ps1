# DEMO 03 - A pre-commit hook blocks secrets BEFORE they enter history
. "$PSScriptRoot\common.ps1"
New-DemoWorkspace '03-pre-commit-hook'
Write-DemoFile 'README.md' @('# wallet-dashboard', '', 'Practice repository. Every secret in it is FAKE.')
Invoke-QuietGit @('add', '.')
Invoke-QuietGit @('commit', '-q', '-m', 'Initial commit')

Show-Title '03' 'Pre-commit hook: stop leaks before they happen' @(
    'Prevention is cheaper than cleanup: scan every commit on the developer laptop.',
    'Then: what if someone bypasses the hook? Scan all branches.'
)

Show-Step 'Install a git hook that runs gitleaks on the STAGED changes before every commit'
Write-DemoFile '.git/hooks/pre-commit' @(
    '#!/bin/sh',
    '# Gitleaks pre-commit hook: scan only the staged changes',
    'gitleaks git --pre-commit --staged --redact --verbose --no-banner',
    'status=$?',
    'if [ $status -ne 0 ]; then',
    '  echo ""',
    '  echo ">>> COMMIT BLOCKED by gitleaks: remove the secret and try again."',
    'fi',
    'exit $status'
)
Invoke-Demo 'Get-Content .git\hooks\pre-commit'

Show-Step 'A developer adds a Slack bot token (FAKE) and tries to commit'
Write-DemoFile 'notify.py' @(
    '# Sends alerts to the team chat (FAKE token)',
    ('SLACK_BOT_TOKEN = "{0}"' -f $Fake.Slack)
)
Invoke-Demo 'Get-Content notify.py'
Invoke-Demo 'git add notify.py'
Invoke-Demo 'git commit -m "Add slack notifier"'
Show-Note 'Blocked. The secret never reached git history.'
Invoke-Demo 'git log --oneline'

Show-Step 'Fix it properly (read the token from the environment) and commit again'
Write-DemoFile 'notify.py' @(
    '# Sends alerts to the team chat -- token comes from the environment',
    'import os',
    '',
    'SLACK_BOT_TOKEN = os.environ.get("SLACK_BOT_TOKEN")'
)
Invoke-Demo 'git add notify.py'
Invoke-Demo 'git commit -m "Add slack notifier (token from env)"'
Show-Note 'Clean commit goes through.'

Show-Step 'Weakness: a developer can skip hooks with --no-verify (on a feature branch)'
Write-DemoFile 'payments.py' @(
    '# Payment gateway client (FAKE key)',
    ('STRIPE_SECRET_KEY = "{0}"' -f $Fake.Stripe)
)
Invoke-Demo 'git checkout -b feature/payments'
Invoke-Demo 'git add payments.py'
Invoke-Demo 'git commit --no-verify -m "Add payments (quick fix)"'
Invoke-Demo 'git checkout main'

Show-Step 'Back on main: the folder looks clean...'
Invoke-Demo 'gitleaks dir . --no-banner'

Show-Step '...but gitleaks git scans ALL branches by default'
Invoke-Demo 'gitleaks git --no-banner -v'

Show-Step 'CI usually scans only the commits a pull request adds'
Invoke-Demo 'gitleaks git --no-banner --log-opts="main..feature/payments"'
Show-Note 'Hooks help developers, but CI must ALSO scan, because hooks can be skipped.'

Show-End 'Hook blocked the Slack token; the bypassed Stripe key was still caught.'
