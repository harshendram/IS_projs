# DEMO 00 - Check that the tools are installed (run this before the presentation)
. "$PSScriptRoot\common.ps1"
Set-Location $PSScriptRoot

Show-Title '00' 'Setup check' @(
    'Confirms gitleaks and git are installed and on PATH.'
)

Invoke-Demo 'gitleaks version'
Invoke-Demo 'git --version'
Invoke-Demo '(Get-Command gitleaks).Source'
Invoke-Demo 'gitleaks --help'

Show-End 'gitleaks and git are ready.'
