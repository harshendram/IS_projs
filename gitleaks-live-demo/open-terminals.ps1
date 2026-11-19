# Opens one terminal tab per demo (Windows Terminal), or one window per demo as a fallback.
# Each tab builds its own fresh workspace and then waits on its title screen for Enter.
#
#   .\open-terminals.ps1                  # all demos 1-8
#   .\open-terminals.ps1 -Demos 1,2,3,4   # only the core demos
param(
    [int[]]$Demos = @(1, 2, 3, 4, 5, 6, 7, 8)
)

$here    = $PSScriptRoot
$scripts = @(Get-ChildItem $here -Filter '*.ps1' |
    Where-Object { $_.Name -match '^(\d\d)-' -and ([int]$Matches[1] -in $Demos) } |
    Sort-Object Name)

if ($scripts.Count -eq 0) { Write-Host 'No matching demo scripts found.' -ForegroundColor Red; exit 1 }

if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
    $tabs = foreach ($s in $scripts) {
        $title = 'Demo ' + ($s.BaseName -replace '-', ' ')
        'new-tab --title "{0}" --suppressApplicationTitle -d "{1}" powershell.exe -NoExit -NoProfile -ExecutionPolicy Bypass -File "{2}"' -f $title, $here, $s.FullName
    }
    Start-Process wt.exe -ArgumentList ('-w new ' + ($tabs -join ' ; '))
    Write-Host "Opened $($scripts.Count) tabs in a new Windows Terminal window." -ForegroundColor Green
    Write-Host 'Switch tabs with Ctrl+Tab or Ctrl+Alt+1..9. Zoom with Ctrl+Plus for the projector.' -ForegroundColor Gray
}
else {
    foreach ($s in $scripts) {
        Start-Process powershell.exe -WorkingDirectory $here -ArgumentList ('-NoExit -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $s.FullName)
    }
    Write-Host "Opened $($scripts.Count) PowerShell windows." -ForegroundColor Green
}
