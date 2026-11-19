# DEMO 06 - Reports (JSON, CSV, SARIF, JUnit, HTML) and redaction
. "$PSScriptRoot\common.ps1"
New-DemoWorkspace '06-reports-and-redaction'
Add-LeakyConfigCommit
New-Item -ItemType Directory -Force reports | Out-Null
Write-DemoFile 'report.html.tmpl' @(
    '<!doctype html><html><head><meta charset="utf-8"><title>Gitleaks report</title>',
    '<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px;background:#fafafa;color:#222}',
    'table{border-collapse:collapse;width:100%;background:#fff}th,td{border:1px solid #ddd;padding:8px;font-size:14px;text-align:left}',
    'th{background:#b00020;color:#fff}tr:nth-child(even){background:#f4f4f4}code{font-family:Consolas,monospace}</style></head><body>',
    '<h1>Gitleaks report</h1><p>{{ len . }} finding(s). Secrets are redacted.</p>',
    '<table><tr><th>#</th><th>Rule</th><th>File : Line</th><th>Commit</th><th>Author</th><th>Secret</th><th>Entropy</th></tr>',
    '{{- range $i, $f := . }}',
    '<tr><td>{{ $i }}</td><td>{{ $f.RuleID }}<br><small>{{ $f.Description }}</small></td><td><code>{{ $f.File }}:{{ $f.StartLine }}</code></td><td><code>{{ $f.Commit }}</code></td><td>{{ $f.Author }}</td><td><code>{{ $f.Secret }}</code></td><td>{{ $f.Entropy }}</td></tr>',
    '{{- end }}',
    '</table></body></html>'
)

Show-Title '06' 'Reports and redaction' @(
    'Scan results must be saved, shared and fed into other tools,',
    'without spreading the secrets even further.'
)

Show-Step 'JSON report: machine-readable, for scripts and dashboards'
Invoke-Demo 'gitleaks git --no-banner -f json -r reports\report.json'
Invoke-Demo 'Get-Content reports\report.json -TotalCount 22'

Show-Step 'Redaction: hide the secret in output and reports'
Invoke-Demo 'gitleaks git --no-banner -v --redact'
Invoke-Demo 'gitleaks git --no-banner -v --redact=50'
Show-Note '--redact hides 100%. --redact=50 keeps half, enough to recognise which key it was.'

Show-Step 'Other formats: CSV (Excel), SARIF (GitHub code scanning), JUnit (CI test dashboards)'
Invoke-Demo 'gitleaks git --no-banner --redact -f csv -r reports\report.csv'
Invoke-Demo 'Import-Csv reports\report.csv | Format-Table RuleID, File, StartLine, Secret -AutoSize'
Invoke-Demo 'gitleaks git --no-banner --redact -f sarif -r reports\report.sarif'
Invoke-Demo 'gitleaks git --no-banner --redact -f junit -r reports\report-junit.xml'

Show-Step 'Custom template: build your own report (here an HTML page)'
Invoke-Demo 'gitleaks git --no-banner --redact -f template --report-template report.html.tmpl -r reports\report.html'
Invoke-Demo 'Get-ChildItem reports | Format-Table Name, Length -AutoSize'
if (-not $AutoMode) { Invoke-Demo 'Start-Process reports\report.html' }
Show-Note 'Note: --report-template needs -f template as well in v8.30.1.'

Show-End 'JSON, CSV, SARIF, JUnit and a custom HTML report, all redacted.'
