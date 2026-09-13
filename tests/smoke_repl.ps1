# smoke_repl.ps1 —— tshell standalone REPL 综合验收（p.9.3.1/2 核心）
# 用子串 Contains（REPL 提示符与结果同行，避免整行锚定的脆弱性）。
$ErrorActionPreference = "Stop"
$exe = (Resolve-Path (Join-Path $PSScriptRoot "..\src\tsh_main.exe")).Path
$inp = @("echo warmup", "1+2", "var sx = 21", "sx * 2", "echo hi-there", "lssp", "ls | count", "ls | filter { str_len(x) > 2 }", "exit")
$full = ($inp -join "`n") + "`n"
$out = (($full | & $exe 2>&1) -join "`n")
$fails = 0
function Check([bool]$c, [string]$m) { if ($c) { Write-Host "PASS: $m" } else { Write-Host "FAIL: $m"; $script:fails++ } }
Check ($out.Contains("tie> 3") -and -not $out.Contains("tie> 30")) "expression 1+2 -> 3"
Check $out.Contains("tie> 42") "session var persisting sx*2 -> 42"
Check $out.Contains("hi-there") "builtin echo"
Check $out.Contains("did you mean 'ls'") "did-you-mean for 'lssp'"
Check ($out -match "tie> \d+") "value pipeline ls | count"
Check $out.Contains("src") "filter predicate pipe"
if ($fails -eq 0) { Write-Host "REPL: ALL PASS" } else { Write-Host "REPL FAILURES: $fails" }