# Legt das GitHub-Repo Bearenkrauler/primeblock-pack an, laedt die Build-Skripte hoch
# und veroeffentlicht PrimeBlock.zip als Release (Standard: v1).
# Aufruf:  powershell -ExecutionPolicy Bypass -File publish.ps1 [-Tag v2] [-Notes "Was neu ist"]
param(
    [string]$Tag = 'v1',
    [string]$Notes = 'Lieferwagen, Mitarbeiter, Arbeitskleidung, Paket, Klebebandabroller'
)
# 'Continue': gh schreibt Statusmeldungen nach stderr, das darf in PowerShell 5.1 kein Abbruch sein.
# Fehler werden stattdessen ueber $LASTEXITCODE erkannt.
$ErrorActionPreference = 'Continue'
$gh = "$env:ProgramFiles\GitHub CLI\gh.exe"
$repo = 'Bearenkrauler/primeblock-pack'
$here = $PSScriptRoot
$zip = Join-Path $here 'PrimeBlock.zip'

function Gh {
    & $gh @args 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -notmatch '^(System\.Management|\s*$)' } | Write-Host
    if ($LASTEXITCODE -ne 0) { Write-Host "FEHLER: gh $($args[0]) $($args[1]) ist fehlgeschlagen." -ForegroundColor Red; exit 1 }
}
function Exists { & $gh @args 2>&1 | Out-Null; return ($LASTEXITCODE -eq 0) }
if (-not (Test-Path $zip)) { Write-Host "PrimeBlock.zip nicht gefunden: $zip" -ForegroundColor Red; exit 1 }

# 1) Repo anlegen (falls noch nicht vorhanden)
if (-not (Exists repo view $repo --json name)) {
    Write-Host "Lege Repo $repo an ..."
    Gh repo create $repo --public --add-readme --description 'PrimeBlock Texture Pack - wird automatisch vom Primeblock-Server-Plugin verteilt'
    Start-Sleep -Seconds 2
}

# 2) Dateien hochladen/aktualisieren (ueber die GitHub-API, kein Git noetig)
function Upload($localPath, $repoPath) {
    $bytes = [System.IO.File]::ReadAllBytes($localPath)
    $body = @{ message = "Update $repoPath"; content = [Convert]::ToBase64String($bytes) }
    $sha = & $gh api "repos/$repo/contents/$repoPath" --jq .sha 2>&1
    if ($LASTEXITCODE -eq 0 -and "$sha".Trim()) { $body.sha = "$sha".Trim() }
    $tmp = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tmp, ($body | ConvertTo-Json -Compress), (New-Object System.Text.UTF8Encoding $false))
    Gh api -X PUT "repos/$repo/contents/$repoPath" --input $tmp --silent
    Remove-Item $tmp
    Write-Host "  hochgeladen: $repoPath"
}
$readme = @'
# PrimeBlock Texture Pack

Wird vom **Primeblock**-Server-Plugin automatisch an alle Spieler verteilt: Das Plugin prueft regelmaessig
das neueste Release dieses Repos und schickt die ZIP als Server-Resource-Pack. Spieler laden es nur neu,
wenn sich das Pack geaendert hat.

## Inhalt
- Boote -> PrimeBlock-Lieferwagen (3D-Modell, braucht **Entity Model Features + Entity Texture Features** oder OptiFine)
- Villager -> PrimeBlock-Mitarbeiter, jeder Beruf mit eigener Arbeitskleidung
- Diamantruestung -> Arbeitskleidung (Kappe, Warnweste, Arbeitshose, Arbeitsschuhe)
- Diamantschwert -> 3D-Klebebandabroller
- Totem der Unsterblichkeit -> 3D-PrimeBlock-Paket

## Pack neu bauen
Windows PowerShell 5.1:
```
powershell -ExecutionPolicy Bypass -File build.ps1
```
Erzeugt `PrimeBlock/` und `PrimeBlock.zip` neben den Skripten.

## Update veroeffentlichen
Neues Release mit hoeherer Versionsnummer und der ZIP als Anhang, z. B.:
```
powershell -ExecutionPolicy Bypass -File publish.ps1 -Tag v2 -Notes "Was neu ist"
```
Der Server erkennt es innerhalb von 10 Minuten (sofort mit `/primeblock pack`).
'@
$readmeFile = Join-Path $env:TEMP 'primeblock-readme.md'
[System.IO.File]::WriteAllText($readmeFile, $readme, (New-Object System.Text.UTF8Encoding $false))

Write-Host 'Lade Dateien hoch ...'
Upload $readmeFile 'README.md'
foreach ($f in 'build.ps1', 'extras.ps1', 'extras2.ps1', 'publish.ps1') { Upload (Join-Path $here $f) $f }
Remove-Item $readmeFile

# 3) Release mit der ZIP
if (Exists release view $Tag --repo $repo) {
    Write-Host "Release $Tag existiert schon - ersetze die ZIP ..."
    Gh release upload $Tag $zip --repo $repo --clobber
} else {
    Write-Host "Erstelle Release $Tag ..."
    Gh release create $Tag $zip --repo $repo --title "PrimeBlock $Tag" --notes $Notes
}
Write-Host ''
Write-Host "Fertig: https://github.com/$repo/releases/tag/$Tag" -ForegroundColor Green
