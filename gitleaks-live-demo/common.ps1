# common.ps1 - shared helpers for every Gitleaks demo script.
# Each demo script loads it with:   . "$PSScriptRoot\common.ps1"
# Works on Windows PowerShell 5.1 and PowerShell 7.

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

# Reload PATH so gitleaks works even in a terminal opened before it was installed.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')

if (-not (Get-Command gitleaks -ErrorAction SilentlyContinue)) {
    Write-Host 'gitleaks is not installed. Run:  winget install --id=Gitleaks.Gitleaks -e' -ForegroundColor Red
    exit 1
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host 'git is not installed. Run:  winget install --id=Git.Git -e' -ForegroundColor Red
    exit 1
}

# Every demo gets its own fresh folder under Documents\gitleaks-live\
$DemoRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'gitleaks-live'

# DEMO_AUTO=1 runs without pauses (used for rehearsal and for make-backup.ps1).
$AutoMode = ($env:DEMO_AUTO -eq '1')
$Esc      = [char]27
$KeepAnsi = (-not $AutoMode) -and [bool]$env:WT_SESSION   # colours only inside Windows Terminal

# ---------------------------------------------------------------------------
# FAKE secrets. Each one is glued together at runtime, so the script files
# themselves contain no secret-shaped strings. (They pass a gitleaks scan and
# GitHub push protection.) None of these values are real.
# ---------------------------------------------------------------------------
$Fake = @{
    Aws        = 'AKIA' + 'Q3EGUZJ7RT5WXKPL'
    GitHub     = 'ghp' + '_R8kd2LqZ7wXv4NbT9yPm3HcJ6sFgA1eUoQiK'
    DbPass     = 'Xk9mP2vL7q' + 'R4nWz8TbQe'
    Slack      = 'xox' + 'b-2048617394-5839201746-Hq7Zt2Lm9Vx4Rk8Wp3Ns6Yd1'
    Stripe     = 'sk' + '_live_51Hq8ZtLm9Vx4Rk8Wp3Ns6Yd'
    TestTok    = 'ghp' + '_T3stFixtur3NotRealAbCdEfGhIjKlMnOpQr'
    DocTok     = 'ghp' + '_D0cSampleValueOnly9xYz8wVu7tSr6qPo5nM'
    KubeTok    = 'ghp' + '_Wn5Kq8Rt2Yx7Bv4Lm9Pz3Hd6Jc1Fs0GaUeTo'
    HexKey     = 'sk' + '_live_9Tq2Wm7Xr4Lp8Zk3Vn6Bh1Jd'
    ZipSlack   = 'xox' + 'b-7391046285-1928374650-Lp4Xc8Vn2Bm6Qw9Er3Ty7Ui0'
    LogTok     = 'ghp' + '_L0gLeakQw8Er2Ty5Ui9Op3As6Df1Gh4Jk7Zx0'
    CurlTok    = 'ghp' + '_Qu1ckCheck7Lm2Np9Rs4Tv6Wx8Yz0Ab3Cd5E'
    Rit        = 'RIT_DEMO_' + 'TOKEN_a8F3kL9pQ2xZ7mW4vB6n'
    RitLow     = 'RIT_DEMO_' + 'TOKEN_aaaaaaaaaaaaaaaaaaaa'
    DbUrlPw    = 'Vq7Lp2x' + 'Nz9wKt4'
    YamlPw     = 'Tr0ub4' + 'dorXyz3'
    ClientS1   = 'Hq7Zt2' + 'Lm9Vx4Rk8Wp3Ns6Yd1'
    ClientS2   = 'Bn3Kd8' + 'Qw2Lx7Vm4Pz9Rt6Yh1'
}

# ---------------------------------------------------------------------------
# Screen helpers
# ---------------------------------------------------------------------------
function Wait-Presenter {
    if ($AutoMode) { return }
    Write-Host '   [Enter]' -ForegroundColor DarkGray -NoNewline
    $null = Read-Host
}

function Show-Title {
    param([string]$Number, [string]$Title, [string[]]$Goal)
    try { $Host.UI.RawUI.WindowTitle = "Demo $Number - $Title" } catch { }
    if (-not $AutoMode) { Clear-Host }
    $line = '=' * 72
    Write-Host $line -ForegroundColor DarkCyan
    Write-Host "  GITLEAKS DEMO $Number : $Title" -ForegroundColor Cyan
    Write-Host $line -ForegroundColor DarkCyan
    foreach ($g in $Goal) { Write-Host "  $g" -ForegroundColor Gray }
    Write-Host "  Workspace: $(Get-Location)" -ForegroundColor DarkGray
    Wait-Presenter
}

function Show-Step {
    param([string]$Text)
    Write-Host ''
    Write-Host ">> $Text" -ForegroundColor Cyan
}

function Show-Note {
    param([string]$Text)
    Write-Host "   => $Text" -ForegroundColor Green
}

# Print a command, wait for Enter, run it, then print its exit code.
function Invoke-Demo {
    param([string]$Command)
    Write-Host ''
    Write-Host "PS> $Command" -ForegroundColor Yellow
    Wait-Presenter
    $global:LASTEXITCODE = 0
    & { Invoke-Expression $Command } 2>&1 | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) {
            # Native tools write normal progress text to stderr; show it as plain text.
            $s = $_.Exception.Message
            if ($s -eq 'System.Management.Automation.RemoteException') { $s = '' }
        }
        elseif ($_ -is [string]) { $s = $_ }
        else { $_; return }
        if ($KeepAnsi) { $s } else { $s -replace "$Esc\[[0-9;]*m", '' }
    } | Out-Host
    $code = $global:LASTEXITCODE
    if ($Command -match '(^|[|;]\s*)(gitleaks\s|git commit)') {
        $hint = ''
        if ($Command -match 'git commit' -and $code -ne 0) { $hint = '(commit was rejected)' }
        elseif ($Command -match 'gitleaks\s+(git|dir|stdin)\b' -and $Command -notmatch '--exit-code') {
            switch ($code) { 0 { $hint = '(no leaks)' } 1 { $hint = '(leaks found)' } 126 { $hint = '(unknown flag)' } }
        }
        $colour = if ($code -eq 0) { 'Green' } else { 'Red' }
        Write-Host "   exit code: $code $hint" -ForegroundColor $colour
    }
}

# ---------------------------------------------------------------------------
# Workspace helpers
# ---------------------------------------------------------------------------
# Delete and recreate Documents\gitleaks-live\<Name>, cd into it, optionally git init.
function New-DemoWorkspace {
    param([string]$Name, [switch]$NoGit)
    $path = Join-Path $DemoRoot $Name
    Set-Location $HOME          # never stand inside the folder we are deleting
    if (Test-Path $path) {
        try { Remove-Item -Recurse -Force $path -ErrorAction Stop }
        catch {
            Write-Host "Could not delete $path. Close any other terminal using it and run again." -ForegroundColor Red
            exit 1
        }
    }
    New-Item -ItemType Directory -Force $path | Out-Null
    Set-Location $path
    if (-not $NoGit) {
        git init -q -b main
        git config user.name 'Demo Student'
        git config user.email 'demo.student@example.com'
        git config core.autocrlf false
        git config commit.gpgsign false
    }
}

# Write a text file (UTF-8, no BOM, LF line endings), creating folders as needed.
function Write-DemoFile {
    param([string]$Path, [string[]]$Lines)
    $full = Join-Path $PWD.Path $Path
    $dir  = Split-Path $full -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    [IO.File]::WriteAllText($full, (($Lines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))
}

# Run git quietly during setup (nothing printed).
function Invoke-QuietGit {
    param([string[]]$GitArgs)
    & git @GitArgs *> $null
}

# The classic mistake: config.py with three hardcoded FAKE secrets, committed.
function Add-LeakyConfigCommit {
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
    Invoke-QuietGit @('add', '.')
    Invoke-QuietGit @('commit', '-q', '-m', 'Add app config')
}

# The "fix": secrets replaced by environment variables.
function Write-CleanConfig {
    Write-DemoFile 'config.py' @(
        '# App configuration -- secrets now come from environment variables',
        'import os',
        '',
        'APP_NAME = "wallet-dashboard"',
        'DEBUG = True',
        '',
        'AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID")',
        'GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")',
        '',
        'DB_HOST = "localhost"',
        'DB_PASSWORD = os.environ.get("DB_PASSWORD")'
    )
}

function Show-End {
    param([string]$Text)
    Write-Host ''
    Write-Host ('-' * 72) -ForegroundColor DarkCyan
    Write-Host "  DONE: $Text" -ForegroundColor Cyan
    Write-Host '  This terminal stays open in the demo folder for any extra commands.' -ForegroundColor DarkGray
    Write-Host ('-' * 72) -ForegroundColor DarkCyan
}
