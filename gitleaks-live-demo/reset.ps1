# Deletes every demo workspace (Documents\gitleaks-live). Each demo script also
# rebuilds its own workspace from scratch whenever it starts, so this is optional.
$root = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'gitleaks-live'
Set-Location $HOME
if (Test-Path $root) {
    Remove-Item -Recurse -Force $root
    Write-Host "Deleted $root" -ForegroundColor Green
}
else {
    Write-Host "Nothing to delete ($root does not exist)." -ForegroundColor Gray
}
