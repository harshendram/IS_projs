# DEMO 01 - A developer commits secrets; gitleaks finds them in git history
. "$PSScriptRoot\common.ps1"
New-DemoWorkspace '01-find-secrets'
Write-DemoFile 'README.md' @('# wallet-dashboard', '', 'Practice repository. Every secret in it is FAKE.')
Write-DemoFile 'config.py' @(
    '# App configuration -- ALL VALUES ARE FAKE (classroom demo)',
    'APP_NAME = "wallet-dashboard"',
    'DEBUG = True',
    '',
    '# Cloud deployment credentials',
    ('AWS_ACCESS_KEY_ID = "{0}"' -f $Fake.Aws),
    '',
    '# CI/CD token used to push container images',
    ('GITHUB_TOKEN = "{0}"' -f $Fake.GitHub),
    '',
    '# Database',
    'DB_HOST = "localhost"',
    ('DB_PASSWORD = "{0}"' -f $Fake.DbPass)
)

Show-Title '01' 'Finding hardcoded secrets' @(
    'A developer hardcodes credentials in config.py and commits them.',
    'Gitleaks scans the git history and reports every secret.'
)

Show-Step 'The file a developer wrote (all values are FAKE)'
Invoke-Demo 'Get-Content config.py'

Show-Step 'They commit it, the normal everyday mistake'
Invoke-Demo 'git add .'
Invoke-Demo 'git commit -m "Add app config"'

Show-Step 'Scan the git history with gitleaks (-v = show every finding)'
Invoke-Demo 'gitleaks git -v'
Show-Note 'RuleID = which of ~200 built-in rules matched (aws-access-token, github-pat, generic-api-key)'
Show-Note 'File / Line / Commit / Author = exactly where and who'
Show-Note 'Entropy = randomness score; real keys are random, placeholders are not'
Show-Note 'Fingerprint = unique ID of this finding (used later to ignore it)'
Show-Note 'Exit code 1 = leaks found, so a CI pipeline would fail here'

Show-End 'gitleaks found all 3 fake secrets in the commit.'
