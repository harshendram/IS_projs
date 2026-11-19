# DEMO 02 - Deleting a secret does not remove it from git history
. "$PSScriptRoot\common.ps1"
$attacker = Join-Path $DemoRoot '02-attacker-copy'
Set-Location $HOME
if (Test-Path $attacker) { Remove-Item -Recurse -Force $attacker }
New-DemoWorkspace '02-history-never-forgets'
Add-LeakyConfigCommit          # config.py with 3 FAKE secrets, already committed

Show-Title '02' 'Git history never forgets' @(
    'The developer notices the leak, deletes the secrets and commits again.',
    'Is the problem solved? We compare a folder scan with a history scan.'
)

Show-Step 'Starting point: the leaky config is already committed'
Invoke-Demo 'git log --oneline'

Show-Step 'The "fix": replace the secrets with environment variables'
Write-CleanConfig
Invoke-Demo 'Get-Content config.py'
Invoke-Demo 'git commit -am "Remove hardcoded secrets"'

Show-Step 'Scan only the files on disk right now (gitleaks dir)'
Invoke-Demo 'gitleaks dir . --no-banner'
Show-Note 'Clean. It looks fixed...'

Show-Step 'Scan the whole git history (gitleaks git)'
Invoke-Demo 'gitleaks git --no-banner'
Show-Note 'Still 3 leaks: the old commit still contains the secrets.'

Show-Step 'Anyone can read the old version of the file straight from history'
Invoke-Demo 'git show HEAD~1:config.py'

Show-Step 'An attacker clones the repo (this is what pushing to GitHub gives them)'
Invoke-Demo "git clone -q . `"$attacker`""
Invoke-Demo "gitleaks git `"$attacker`" --no-banner"
Show-Note 'Every clone carries the full history, including the leaked keys.'
Show-Note 'Real fix = REVOKE / ROTATE the key first, then optionally rewrite history.'

Show-End 'dir = 0 leaks, git = 3 leaks. Deleting is not enough.'
