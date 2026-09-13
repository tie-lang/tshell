# build.ps1 -- tshell build driver (bootstrap with tiec stage0)
# usage: powershell -File build.ps1 [-NoCache]
# builds two assemblies: standalone (tsh_main.exe, full) + tedit subset (tedit_embed.exe)
param([switch]$NoCache)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$tiec = Join-Path $root "..\tiec\compiler\tiec.exe"
if (-not (Test-Path $tiec)) {
    Write-Host "[build] tiec stage0 not found: $tiec"
    Write-Host "[build] please clone tie-lang/tiec as a sibling of this repo."
    exit 1
}
$targets = @("src\tsh_main.tie" , "src\tedit_embed.tie")
foreach ($t in $targets) {
    Write-Host "[build] compiling $t"
    $entry = Join-Path $root $t
    if ($NoCache) {
        & $tiec "--no-cache" $entry
    } else {
        & $tiec $entry
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[build] compile failed: $t"
        exit 1
    }
}
Write-Host "[build] done: src\tsh_main.exe (standalone) + src\tedit_embed.exe (tedit subset)"