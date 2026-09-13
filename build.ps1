# build.ps1 —— tshell 构建驱动（自举：用 tiec stage0 编译装配入口）
# 用法: powershell -File build.ps1
# 前置: tiec 为 tshell 的兄弟目录（f:\Projects\tie-repo\{tiec, tshell}）
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$tiec = Join-Path $root "..\tiec\compiler\tiec.exe"
if (-not (Test-Path $tiec)) {
    Write-Host "[build] 未找到 tiec stage0 编译器: $tiec"
    Write-Host "[build] 请把 tie-lang/tiec 克隆到 tshell 的兄弟目录再构建。"
    exit 1
}
$entry = Join-Path $root "src\tsh_main.tie"
Write-Host "[build] tiec 编译: $entry"
& $tiec $entry
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    Write-Host "[build] 编译失败 (exit $LASTEXITCODE)"
    exit 1
}
$exe = Join-Path $root "src\tsh_main.exe"
if (Test-Path $exe) {
    Write-Host "[build] OK: $exe"
} else {
    Write-Host "[build] 未生成 $exe"
    exit 1
}