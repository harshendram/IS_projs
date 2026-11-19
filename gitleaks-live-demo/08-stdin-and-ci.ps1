# DEMO 08 - Scanning piped text (stdin), exit codes, and running gitleaks in CI
. "$PSScriptRoot\common.ps1"
New-DemoWorkspace '08-stdin-and-ci'
Add-LeakyConfigCommit
Write-CleanConfig
Invoke-QuietGit @('commit', '-q', '-am', 'Remove hardcoded secrets')
Write-DemoFile 'app-crash.log' @(
    '2026-11-18 21:04:11 INFO  starting wallet-dashboard',
    ('2026-11-18 21:04:12 DEBUG env dump: GITHUB_TOKEN={0} DEBUG=true' -f $Fake.LogTok),
    '2026-11-18 21:04:13 ERROR connection refused'
)
Write-DemoFile '.github/workflows/gitleaks.yml' @(
    '# Runs gitleaks on every push and pull request (free CLI, no licence needed)',
    'name: gitleaks',
    'on: [push, pull_request]',
    'permissions:',
    '  contents: read',
    '  security-events: write',
    'jobs:',
    '  secret-scan:',
    '    runs-on: ubuntu-latest',
    '    steps:',
    '      - uses: actions/checkout@v4',
    '        with:',
    '          fetch-depth: 0      # full history (default 1 = only the latest commit)',
    '      - name: Install gitleaks v8.30.1',
    '        run: curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz | tar -xz gitleaks',
    '      - name: Scan',
    '        run: ./gitleaks git --redact -v --report-format sarif --report-path gitleaks.sarif',
    '      - name: Upload to GitHub code scanning',
    '        if: always()',
    '        uses: github/codeql-action/upload-sarif@v3',
    '        with:',
    '          sarif_file: gitleaks.sarif'
)

Show-Title '08' 'stdin, exit codes and CI' @(
    'gitleaks stdin scans ANY text you pipe into it.',
    'Exit codes are how pipelines decide to pass or fail.'
)

Show-Step 'stdin use case 1: check a log file BEFORE sharing it with support or online'
Invoke-Demo 'Get-Content app-crash.log'
Invoke-Demo 'Get-Content app-crash.log | gitleaks stdin --no-banner -v --redact=60'

Show-Step 'stdin use case 2: check the output of another command (here: an old commit)'
Invoke-Demo 'git show HEAD~1 | gitleaks stdin --no-banner'

Show-Step 'stdin use case 3: quick check of a single line before pasting it in chat'
Invoke-Demo ("echo 'curl -H `"Authorization: Bearer {0}`" https://api.example.com' | gitleaks stdin --no-banner" -f $Fake.CurlTok)

Show-Step 'Exit codes (what CI pipelines look at)'
Invoke-Demo 'gitleaks git --no-banner'
Invoke-Demo 'gitleaks git --no-banner --log-opts=-1'
Invoke-Demo 'gitleaks git --no-banner --exit-code 0'
Show-Note '--exit-code 0 = warn-only mode: report leaks but do not fail the build.'
Invoke-Demo 'gitleaks git --bogus-flag'
Show-Note '0 = clean, 1 = leaks found, 126 = unknown flag.'

Show-Step 'Running it automatically on every push: a GitHub Actions workflow'
Invoke-Demo 'Get-Content .github\workflows\gitleaks.yml'
Show-Note 'fetch-depth: 0 matters: without full history, old leaks are invisible to the scan.'

Show-End 'stdin scans any text; exit codes drive CI; the workflow scans every push.'
