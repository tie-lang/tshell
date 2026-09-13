# tshell --stdio frame roundtrip smoke (p.9.3.4)
# 用文件重定向做二进制帧往返：in.bin=[len BE][payload][crc BE] 送给 --stdio，
# 读取 out.bin 响应帧并解码，校验 1+2 -> 3。避免交互式工具主机的 stdout 字节截获。
$ErrorActionPreference = "Stop"
$exe = Join-Path $PSScriptRoot "..\src\tsh_main.exe"
$exe = (Resolve-Path $exe).Path
$inF = Join-Path $env:TEMP "tsh_stdin.bin"
$outF = Join-Path $env:TEMP "tsh_stdout.bin"

function Get-Crc32([byte[]]$data) {
    $poly = [uint32]3988292384
    $table = New-Object 'uint32[]' 256
    for ($i = 0; $i -lt 256; $i++) {
        $c = [uint32]$i
        for ($k = 0; $k -lt 8; $k++) {
            if (($c -band 1) -ne 0) { $c = $poly -bxor ($c -shr 1) } else { $c = $c -shr 1 }
        }
        $table[$i] = $c
    }
    $crc = [uint32]::MaxValue
    foreach ($b in $data) { $crc = $table[($crc -bxor $b) -band 0xFF] -bxor ($crc -shr 8) }
    return ([uint32]::MaxValue -bxor $crc)
}

# ---- build frame ----
$pb = [System.Text.Encoding]::UTF8.GetBytes("1+2")
$len = [uint32]$pb.Length
$head = [byte[]](@([byte](($len -shr 24) -band 0xFF), [byte](($len -shr 16) -band 0xFF), [byte](($len -shr 8) -band 0xFF), [byte]($len -band 0xFF)))
$crc = Get-Crc32 $pb
$tail = [byte[]](@([byte](($crc -shr 24) -band 0xFF), [byte](($crc -shr 16) -band 0xFF), [byte](($crc -shr 8) -band 0xFF), [byte]($crc -band 0xFF)))
$frameIn = [byte[]]($head + $pb + $tail)
[IO.File]::WriteAllBytes($inF, $frameIn)
if (Test-Path $outF) { Remove-Item $outF }

# ---- run child with file redirection ----
$p = Start-Process -FilePath $exe -ArgumentList "--stdio" -RedirectStandardInput $inF -RedirectStandardOutput $outF -Wait -PassThru -NoNewWindow

$resp0 = [IO.File]::ReadAllBytes($outF)
Write-Host "response bytes=$($resp0.Length)"
if ($resp0.Length -lt 4) { Write-Host "FAIL: no response frame"; exit 1 }
$n = (($resp0[0] -shl 24) -bor ($resp0[1] -shl 16) -bor ($resp0[2] -shl 8) -bor $resp0[3])
if ($resp0.Length -lt ($n + 4)) { Write-Host "FAIL: incomplete frame"; exit 1 }
$payloadBytes = New-Object byte[] $n
[Array]::Copy($resp0, 4, $payloadBytes, 0, $n)
$i0 = 4 + $n
$want = [uint32](([int]$resp0[$i0] -shl 24) -bor ([int]$resp0[$i0+1] -shl 16) -bor ([int]$resp0[$i0+2] -shl 8) -bor [int]$resp0[$i0+3])
$calc = Get-Crc32 $payloadBytes
if ($calc -ne $want) { Write-Host "FAIL: response CRC invalid ($calc vs $want)"; exit 1 }
$resp = [System.Text.Encoding]::UTF8.GetString($payloadBytes)
if ($resp -eq "3") { Write-Host "PASS: --stdio roundtrip 1+2 -> 3 (payload=$resp)" }
else { Write-Host "FAIL: unexpected payload '$resp'"; exit 1 }
Write-Host "STDIO: ALL PASS"