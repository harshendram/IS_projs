# DEMO 07 - Secrets hidden by encoding (base64 / hex) and inside zip archives
. "$PSScriptRoot\common.ps1"
New-DemoWorkspace '07-encoded-and-archives' -NoGit

# --- encoded secrets
$bytes  = [Text.Encoding]::ASCII.GetBytes($Fake.KubeTok)
$b64    = [Convert]::ToBase64String($bytes)
$double = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($b64))
$hex    = ([Text.Encoding]::ASCII.GetBytes($Fake.HexKey) | ForEach-Object { $_.ToString('x2') }) -join ''
Write-DemoFile 'encoded/k8s-deploy-secret.yaml' @(
    '# Kubernetes Secret: token the CI pipeline uses to push container images (FAKE)',
    'apiVersion: v1',
    'kind: Secret',
    'metadata:',
    '  name: registry-deploy-token',
    'type: Opaque',
    'data:',
    "  token: $b64"
)
Write-DemoFile 'encoded/hex-config.txt'     @("payment_key_hex = `"$hex`"")
Write-DemoFile 'encoded/double-encoded.txt' @("nested: $double")

# --- archives: release-v1.zip contains .env ; backup-nested.zip contains release-v1.zip
New-Item -ItemType Directory -Force archives, build | Out-Null
Write-DemoFile 'build/.env' @("SLACK_BOT_TOKEN=$($Fake.ZipSlack)")
Compress-Archive -Path 'build\.env' -DestinationPath 'archives\release-v1.zip' -Force
Compress-Archive -Path 'archives\release-v1.zip' -DestinationPath 'archives\backup-nested.zip' -Force
Remove-Item -Recurse -Force build

Show-Title '07' 'Encoded secrets and archives' @(
    'Attackers do not need plain text: base64 and hex are not encryption.',
    'Secrets also hide inside zip files: backups, release bundles.'
)

Show-Step 'Encoded files: no secret is visible to a human'
Invoke-Demo 'Get-Content encoded\k8s-deploy-secret.yaml'
Invoke-Demo 'Get-Content encoded\hex-config.txt, encoded\double-encoded.txt'

Show-Step 'gitleaks decodes base64 / hex / percent-encoding automatically (default depth 5)'
Invoke-Demo 'gitleaks dir encoded --no-banner -v'
Show-Note 'Tags show HOW it was decoded: decoded:base64 decode-depth:2 = base64 inside base64.'

Show-Step 'Same scan with decoding switched off'
Invoke-Demo 'gitleaks dir encoded --no-banner --max-decode-depth=0'

Show-Step 'Archives: a release zip and a backup zip that contains the release zip'
Invoke-Demo 'Get-ChildItem archives | Format-Table Name, Length -AutoSize'
Invoke-Demo 'gitleaks dir archives --no-banner'
Show-Note 'By default archives are NOT opened.'
Invoke-Demo 'gitleaks dir archives --no-banner -v --max-archive-depth=2'
Show-Note 'The ! in the path shows where it was found: backup-nested.zip!release-v1.zip!.env'

Show-End 'Encoding is not protection, and zips are not hiding places.'
