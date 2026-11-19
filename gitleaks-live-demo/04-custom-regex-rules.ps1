# DEMO 04 - Custom regex rules: detect your own token format, and search history
. "$PSScriptRoot\common.ps1"
New-DemoWorkspace '04-custom-regex-rules'

# History for Part B: someone committed a server inventory, then deleted it.
Write-DemoFile 'README.md' @('# wallet-dashboard', '', 'Practice repository. Every secret in it is FAKE.')
Invoke-QuietGit @('add', '.')
Invoke-QuietGit @('commit', '-q', '-m', 'Initial commit')
Write-DemoFile 'deploy/inventory.ini' @(
    '[wallet_servers]',
    'api01.internal.rit.edu  ansible_host=10.20.30.41',
    'api02.internal.rit.edu  ansible_host=10.20.30.42'
)
Invoke-QuietGit @('add', '.')
Invoke-QuietGit @('commit', '-q', '-m', 'Add server inventory')
Invoke-QuietGit @('rm', '-q', '-r', 'deploy')
Invoke-QuietGit @('commit', '-q', '-m', 'Remove server inventory')

Show-Title '04' 'Custom regex rules' @(
    'Part A: teach gitleaks our own token format (RIT_DEMO_TOKEN_...).',
    'Part B: use custom regex to SEARCH every commit, even deleted files.',
    'Part C (bonus): advanced rule types.'
)

# ----------------------------------------------------------------- Part A
Show-Step 'PART A - Our organisation issues tokens like RIT_DEMO_TOKEN_<20 chars>'
Write-DemoFile 'internal_api.py' @(
    '# Internal API client (FAKE tokens)',
    ('PLACEHOLDER = "{0}"   # low randomness -> should be ignored' -f $Fake.RitLow),
    ('API_TOKEN   = "{0}"   # random         -> should be caught' -f $Fake.Rit)
)
Invoke-Demo 'Get-Content internal_api.py'

Show-Step 'Built-in rules do not know this format'
Invoke-Demo 'gitleaks dir internal_api.py --no-banner'

Show-Step 'Write a custom rule in .gitleaks.toml (gitleaks loads it automatically)'
Write-DemoFile '.gitleaks.toml' @(
    'title = "RIT demo config"',
    '',
    '# Keep all built-in rules; this file only ADDS to them',
    '[extend]',
    'useDefault = true',
    '',
    '[[rules]]',
    'id = "rit-demo-token"',
    'description = "RIT internal demo token"',
    "regex = '''RIT_DEMO_TOKEN_([A-Za-z0-9]{20})'''",
    'secretGroup = 1                  # the secret is the part after the prefix',
    'entropy = 3.0                    # skip low-randomness placeholders',
    'keywords = ["rit_demo_token_"]   # fast pre-filter before running the regex'
)
Invoke-Demo 'Get-Content .gitleaks.toml'
Invoke-Demo 'gitleaks dir . --no-banner -v'
Show-Note 'Real token caught (high entropy). The aaaa... placeholder was skipped (entropy 0).'

# ----------------------------------------------------------------- Part B
Show-Step 'PART B - Custom regex as a SEARCH tool across all git history'
Invoke-Demo 'git log --oneline --name-status'
Show-Note 'deploy/inventory.ini was added and then deleted. Hostnames are not "secrets"...'
Write-DemoFile 'search-rules.toml' @(
    '# Search-only config: NO built-in rules, only these patterns',
    '[[rules]]',
    'id = "internal-hostname"',
    'description = "Internal hostname"',
    "regex = '''\b[a-z0-9-]+\.internal\.rit\.edu\b'''",
    'keywords = ["internal.rit.edu"]',
    '',
    '[[rules]]',
    'id = "private-ipv4"',
    'description = "Private network IP address"',
    "regex = '''\b(?:10(?:\.\d{1,3}){3}|192\.168(?:\.\d{1,3}){2}|172\.(?:1[6-9]|2\d|3[01])(?:\.\d{1,3}){2})\b'''"
)
Invoke-Demo 'Get-Content search-rules.toml'
Invoke-Demo 'gitleaks git -c search-rules.toml --no-banner -v'
Show-Note 'Found in a DELETED file, in an old commit. Gitleaks = regex search over all of history.'

# ----------------------------------------------------------------- Part C
Show-Step 'PART C (bonus) - advanced rule types. Press Enter to continue, or Ctrl+C to stop here.'
Wait-Presenter
Write-DemoFile 'advanced-rules.toml' @(
    '# 1) Regex + capture group + rule-level allowlist',
    '[[rules]]',
    'id = "db-connection-string"',
    'description = "Database URL containing a password"',
    "regex = '''(?i)\b(?:postgres(?:ql)?|mysql|mongodb(?:\+srv)?)://[^:\s/]+:([^@\s]+)@[^\s'`"]+'''",
    'secretGroup = 1',
    'keywords = ["postgres", "mysql", "mongodb"]',
    '    [[rules.allowlists]]',
    '    regexTarget = "secret"',
    "    regexes = ['''^<.*>$''']",
    '    stopwords = ["changeme"]',
    '',
    '# 2) PATH-ONLY rule: the file name alone is the finding',
    '[[rules]]',
    'id = "sensitive-filename"',
    'description = "Private key or .env file committed"',
    "path = '''(?i)(^|/)(id_rsa|id_ed25519|[^/]+\.pem|\.env)$'''",
    '',
    '# 3) PATH + REGEX: password lines, but only inside YAML files',
    '[[rules]]',
    'id = "yaml-password"',
    'description = "Password field in a YAML file"',
    "path = '''(?i)\.ya?ml$'''",
    "regex = '''(?i)\bpassword:\s*[`"']?([^\s`"']{6,})'''",
    'secretGroup = 1',
    'keywords = ["password"]',
    '',
    '# 4) COMPOSITE rule: report a client secret ONLY if a client id is within 3 lines',
    '[[rules]]',
    'id = "rit-client-id"',
    'description = "Helper rule, not reported on its own"',
    "regex = '''rit_client_id\s*=\s*`"(RIT-\d{6})`"'''",
    'keywords = ["rit_client_id"]',
    'skipReport = true',
    '',
    '[[rules]]',
    'id = "rit-client-secret"',
    'description = "Client secret next to a client id"',
    "regex = '''rit_client_secret\s*=\s*`"([A-Za-z0-9]{24})`"'''",
    'secretGroup = 1',
    'keywords = ["rit_client_secret"]',
    '    [[rules.required]]',
    '    id = "rit-client-id"',
    '    withinLines = 3'
)
Write-DemoFile 'samples/app-settings.yaml' @(
    '# Application settings (ALL FAKE)',
    ('database_url: postgresql://wallet_admin:{0}@db01.internal.rit.edu:5432/wallet' -f $Fake.DbUrlPw),
    'example_url: postgres://user:changeme@localhost:5432/test',
    'docs_url: mysql://root:<password>@localhost/app',
    ('password: {0}' -f $Fake.YamlPw)
)
Write-DemoFile 'samples/ops-notes.txt' @(
    'Ops notes (FAKE)',
    ('password: {0}' -f $Fake.YamlPw)
)
Write-DemoFile 'samples/keys/id_rsa' @('placeholder - only the file NAME should be flagged')
Write-DemoFile 'samples/client_paired.py' @(
    'rit_client_id = "RIT-482913"',
    ('rit_client_secret = "{0}"' -f $Fake.ClientS1)
)
Write-DemoFile 'samples/client_alone.py' @(
    '# no client id nearby -> composite rule should NOT fire',
    ('rit_client_secret = "{0}"' -f $Fake.ClientS2)
)
Invoke-Demo 'Get-Content advanced-rules.toml'
Invoke-Demo 'Get-ChildItem samples -Recurse -File | Resolve-Path -Relative'
Invoke-Demo 'gitleaks dir samples -c advanced-rules.toml --no-banner -r findings.json'
Invoke-Demo '(Get-Content findings.json -Raw | ConvertFrom-Json) | Format-Table RuleID, File, StartLine, Secret -AutoSize'
Show-Note 'Caught: real DB password, id_rsa by name, YAML password, paired client secret.'
Show-Note 'Ignored: changeme and <password> placeholders, the password in a .txt file, the lonely client secret.'

Show-End 'Custom rules = regex + entropy + keywords + path + allowlists + composite conditions.'
