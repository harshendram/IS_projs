# DEMO 05 - Handling false positives: inline allow, allowlist, .gitleaksignore, baseline
. "$PSScriptRoot\common.ps1"
New-DemoWorkspace '05-false-positives'
Add-LeakyConfigCommit
Write-CleanConfig
Invoke-QuietGit @('commit', '-q', '-am', 'Remove hardcoded secrets')

Show-Title '05' 'Handling false positives' @(
    'Not every finding is a real problem: test fixtures, documentation samples,',
    'already-revoked keys, old findings. Four ways to tell gitleaks.'
)

Show-Step 'Starting point: 3 real leaks in history'
Invoke-Demo 'gitleaks git --no-banner'

# ------------------------------------------------ 1) inline comment
Show-Step '1) INLINE: a test file with a dummy token, marked with gitleaks:allow'
Write-DemoFile 'tests/test_auth.py' @(
    '# Unit test fixture: a dummy token that is intentionally kept',
    ('DUMMY_TOKEN = "{0}"  # gitleaks:allow' -f $Fake.TestTok),
    '',
    'def test_rejects_bad_token():',
    '    assert DUMMY_TOKEN.startswith("ghp_")'
)
Invoke-Demo 'Get-Content tests\test_auth.py'
Invoke-Demo 'git add tests; git commit -q -m "Add auth tests"'
Invoke-Demo 'gitleaks git --no-banner'
Show-Note 'Still 3: the allowed line is skipped.'
Invoke-Demo 'gitleaks git --no-banner --ignore-gitleaks-allow'
Show-Note 'An auditor can switch the comments off and see everything (4).'

# ------------------------------------------------ 2) allowlist in config
Show-Step '2) ALLOWLIST: documentation folder contains sample tokens'
Write-DemoFile 'docs/setup-guide.md' @(
    '# Setup guide',
    '',
    'Set your token before running the app. Sample value:',
    '',
    ('    export GITHUB_TOKEN={0}' -f $Fake.DocTok)
)
Invoke-Demo 'git add docs; git commit -q -m "Add setup guide"'
Invoke-Demo 'gitleaks git --no-banner'
Write-DemoFile '.gitleaks.toml' @(
    '[extend]',
    'useDefault = true',
    '',
    '[[allowlists]]',
    'description = "Documentation contains sample tokens only"',
    "paths = ['''^docs/''']"
)
Invoke-Demo 'Get-Content .gitleaks.toml'
Invoke-Demo 'gitleaks git --no-banner'
Show-Note 'Back to 3: everything under docs/ is ignored.'

# ------------------------------------------------ 3) .gitleaksignore
Show-Step '3) .gitleaksignore: the AWS key was REVOKED, accept that one old finding'
Invoke-Demo 'gitleaks git --no-banner -r findings.json'
Invoke-Demo '(Get-Content findings.json -Raw | ConvertFrom-Json) | Format-Table RuleID, Fingerprint -AutoSize'
$awsFp = ((Get-Content findings.json -Raw | ConvertFrom-Json) | Where-Object { $_.RuleID -eq 'aws-access-token' }).Fingerprint
Write-DemoFile '.gitleaksignore' @('# AWS key revoked during rotation - historical finding accepted', $awsFp)
Invoke-Demo 'Get-Content .gitleaksignore'
Invoke-Demo 'gitleaks git --no-banner -v'
Show-Note 'Down to 2: exactly one finding silenced, nothing else.'

# ------------------------------------------------ 4) baseline
Show-Step '4) BASELINE: accept today''s findings, fail only on NEW ones'
Invoke-Demo 'gitleaks git --no-banner -r baseline.json'
Invoke-Demo 'gitleaks git --no-banner --baseline-path baseline.json'
Show-Note 'Exit 0: old findings are known and accepted.'
Write-DemoFile 'notify.py' @(
    '# Sends alerts to the team chat (FAKE token)',
    ('SLACK_BOT_TOKEN = "{0}"' -f $Fake.Slack)
)
Invoke-Demo 'git add notify.py; git commit -q -m "Add slack notifier"'
Invoke-Demo 'gitleaks git --no-banner -v --baseline-path baseline.json'
Show-Note 'Only the NEW Slack token is reported. This is how teams adopt gitleaks on old repos.'
Show-Note 'Remember: ignoring only hides findings from YOU. An attacker sees everything.'

Show-End 'gitleaks:allow, [[allowlists]], .gitleaksignore and --baseline-path.'
