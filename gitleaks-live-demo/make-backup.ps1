# Runs every demo without pauses and saves the full output to .\backup\
# Use these files (plus backup\report.html) if the laptop or projector fails.
# The backup folder is git-ignored because its text contains the FAKE secrets.
$here = $PSScriptRoot
$out  = Join-Path $here 'backup'
New-Item -ItemType Directory -Force $out | Out-Null
$esc  = [char]27

$env:DEMO_AUTO = '1'
try {
    Get-ChildItem $here -Filter '*.ps1' | Where-Object { $_.Name -match '^\d\d-' } | Sort-Object Name | ForEach-Object {
        Write-Host "Recording $($_.Name) ..." -ForegroundColor Cyan
        $lines = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $_.FullName 2>&1 | ForEach-Object { "$_" -replace "$esc\[[0-9;]*m", '' }
        $lines | Set-Content (Join-Path $out ($_.BaseName + '.txt')) -Encoding UTF8
    }
}
finally {
    Remove-Item Env:DEMO_AUTO -ErrorAction SilentlyContinue
}

$html = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'gitleaks-live\06-reports-and-redaction\reports\report.html'
if (Test-Path $html) { Copy-Item $html (Join-Path $out 'report.html') -Force }

Write-Host "Backup saved to $out" -ForegroundColor Green
Get-ChildItem $out | Format-Table Name, Length -AutoSize
